import spacy
import re
from typing import Dict, List, Any

# Load the base spaCy English model
try:
    nlp = spacy.load("en_core_web_sm")
except OSError:
    print("Warning: en_core_web_sm not found. Run 'python -m spacy download en_core_web_sm'")
    nlp = None

# Comprehensive list of lab test names to search for (case-insensitive matching)
LAB_TEST_PATTERNS = {
    # CBC
    "hemoglobin": ["hemoglobin", "haemoglobin", "hb", "hgb"],
    "rbc": ["total rbc count", "rbc count", "red blood cell", "rbc", "total rbc"],
    "wbc": ["total wbc count", "wbc count", "white blood cell", "wbc", "total wbc", "tlc"],
    "platelet": ["platelet count", "platelet", "plt"],
    "pcv": ["packed cell volume", "pcv", "hematocrit", "hct"],
    "mcv": ["mean corpuscular volume", "mcv"],
    "mch": ["mean corpuscular hemoglobin", "mch"],
    "mchc": ["mchc", "mean corpuscular hb conc"],
    "rdw": ["rdw", "red cell distribution width"],
    # Differential WBC
    "neutrophils": ["neutrophils", "neutrophil"],
    "lymphocytes": ["lymphocytes", "lymphocyte"],
    "eosinophils": ["eosinophils", "eosinophil"],
    "monocytes": ["monocytes", "monocyte"],
    "basophils": ["basophils", "basophil"],
    # Metabolic
    "glucose_fasting": ["fasting glucose", "fasting blood sugar", "fbs", "glucose fasting", "glucose, fasting"],
    "glucose_pp": ["post prandial", "ppbs", "glucose pp", "pp glucose"],
    "glucose_random": ["random glucose", "random blood sugar", "rbs", "glucose random"],
    "hba1c": ["hba1c", "glycosylated hemoglobin", "glycated"],
    # Lipid Profile
    "total_cholesterol": ["total cholesterol", "cholesterol, total", "cholesterol"],
    "triglycerides": ["triglycerides", "triglyceride", "tg"],
    "hdl": ["hdl cholesterol", "hdl", "high density"],
    "ldl": ["ldl cholesterol", "ldl", "low density"],
    "vldl": ["vldl", "very low density"],
    # Kidney / Renal
    "creatinine": ["creatinine", "serum creatinine"],
    "urea": ["blood urea", "urea", "bun"],
    "uric_acid": ["uric acid"],
    # Liver / Hepatic
    "bilirubin_total": ["total bilirubin", "bilirubin total", "bilirubin"],
    "bilirubin_direct": ["direct bilirubin", "bilirubin direct", "conjugated bilirubin"],
    "sgot": ["sgot", "ast", "aspartate aminotransferase"],
    "sgpt": ["sgpt", "alt", "alanine aminotransferase"],
    "alp": ["alkaline phosphatase", "alp"],
    "total_protein": ["total protein"],
    "albumin": ["albumin"],
    # Thyroid
    "tsh": ["tsh", "thyroid stimulating hormone"],
    "t3": ["t3", "triiodothyronine"],
    "t4": ["t4", "thyroxine"],
    # Others
    "calcium": ["calcium", "serum calcium"],
    "iron": ["serum iron", "iron"],
    "vitamin_d": ["vitamin d", "25-oh vitamin d", "25 hydroxy"],
    "vitamin_b12": ["vitamin b12", "b12", "cobalamin"],
    "esr": ["esr", "erythrocyte sedimentation rate"],
}


def _extract_number_after_keyword(line: str, keyword_end_pos: int) -> tuple:
    """
    Given a line and the position where the keyword ends,
    find the FIRST number that appears after the keyword.
    Returns (value_str, unit_str) or (None, None).
    """
    remaining = line[keyword_end_pos:]
    # Match numbers like 13.00, 5.50, 20000, 0.5, etc.
    match = re.search(r'(\d+\.?\d*)', remaining)
    if match:
        val_str = match.group(1)
        # Try to grab a unit after the number
        after_num = remaining[match.end():].strip()
        unit_match = re.match(r'([a-zA-Z/%\.]+(?:/[a-zA-Z]+)?)', after_num)
        unit = unit_match.group(1) if unit_match else ""
        return val_str, unit
    return None, None


def _extract_reference_range(line: str) -> str:
    """
    Try to extract the reference range from the line (e.g., "13.00 - 17.00" or "4000 - 11000").
    """
    match = re.search(r'(\d+\.?\d*)\s*[-–]\s*(\d+\.?\d*)', line)
    if match:
        return f"{match.group(1)} - {match.group(2)}"
    return ""


def extract_lab_parameters(text: str) -> Dict[str, Dict[str, str]]:
    """
    Extracts lab parameters from OCR text by matching known test names
    and grabbing the numeric value that follows them.
    
    Returns structured dict like:
    {"Hemoglobin": {"value": "13.00", "unit": "g/dL", "reference_range": "13.00 - 17.00"}, ...}
    """
    parameters = {}
    lines = text.split("\n")

    for line in lines:
        line_lower = line.lower().strip()
        if not line_lower or len(line_lower) < 3:
            continue

        for param_key, aliases in LAB_TEST_PATTERNS.items():
            if param_key in parameters:
                continue  # Already found this parameter

            for alias in aliases:
                # Check if alias appears in line
                alias_lower = alias.lower()
                idx = line_lower.find(alias_lower)

                if idx != -1:
                    # Found the keyword. Now extract the number after the keyword.
                    keyword_end = idx + len(alias_lower)
                    val_str, unit = _extract_number_after_keyword(line, keyword_end)

                    if val_str is not None:
                        ref_range = _extract_reference_range(line)
                        parameters[param_key] = {
                            "name": alias.title(),
                            "value": val_str,
                            "unit": unit,
                            "extracted_reference": ref_range
                        }
                        break  # Move to next parameter
    return parameters


def extract_medicines(text: str) -> List[Dict[str, str]]:
    """
    Extracts medicines and dosages from a prescription.
    """
    medicines = []

    # 1. Use spaCy NER for potential entity detection
    if nlp is not None:
        doc = nlp(text)
        for ent in doc.ents:
            if ent.label_ in ["PRODUCT", "ORG"]:
                medicines.append({"name": ent.text, "source": "ner"})

    # 2. Use regex looking for dosage patterns (e.g., "Paracetamol 500mg", "Tab Amoxicillin 250 mg")
    lines = text.split("\n")
    dosage_pattern = re.compile(
        r'(?:tab\.?|cap\.?|syrup|inj\.?|drops?)?\s*'
        r'(\b[A-Z][a-zA-Z]+(?:\s[A-Z][a-zA-Z]+)?)\s+'
        r'(\d+\s*(?:mg|ml|mcg|g|iu)\b)',
        re.IGNORECASE
    )
    timing_pattern = re.compile(
        r'((?:once|twice|thrice|1|2|3)\s*(?:daily|times?\s*(?:a\s*)?day|x\s*day)|'
        r'(?:morning|afternoon|evening|night|before\s*food|after\s*food|bd|tid|od|hs|sos|prn|ac|pc))',
        re.IGNORECASE
    )

    for line in lines:
        for match in dosage_pattern.finditer(line):
            med_name = match.group(1).strip()
            dosage = match.group(2).strip()

            # Check for timing info in the same line
            timing_match = timing_pattern.search(line)
            timing = timing_match.group(0) if timing_match else ""

            if len(med_name) > 2:
                # Avoid duplicates
                existing = [m["name"].lower() for m in medicines]
                if med_name.lower() not in existing:
                    medicines.append({
                        "name": med_name,
                        "dosage": dosage,
                        "timing": timing,
                        "source": "regex"
                    })

    return medicines


def analyze_parsed_text(text: str, report_type: str = "lab_report") -> Dict[str, Any]:
    """
    Main router for text analysis.
    """
    result = {
        "raw_text_length": len(text),
        "parameters": {},
        "medicines": []
    }

    if report_type == "lab_report":
        result["parameters"] = extract_lab_parameters(text)
    elif report_type == "prescription":
        result["medicines"] = extract_medicines(text)

    return result
