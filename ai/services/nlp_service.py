import spacy
import re
from typing import Dict, List, Any

# Load the base spaCy English model
try:
    nlp = spacy.load("en_core_web_sm")
except OSError:
    print("Warning: en_core_web_sm not found.")
    nlp = None

# Comprehensive list of lab test names to search for
# Each key maps to a list of aliases (longest first to avoid partial matches)
LAB_TEST_PATTERNS = {
    # CBC
    "hemoglobin": ["hemoglobin (hb)", "hemoglobin(hb)", "haemoglobin", "hemoglobin"],
    "rbc": ["total rbc count", "rbc count", "total rbc"],
    "wbc": ["total wbc count", "wbc count", "total wbc"],
    "platelet": ["platelet count", "platelet"],
    "pcv": ["packed cell volume (pcv)", "packed cell volume", "pcv"],
    "mcv": ["mean corpuscular volume (mcv)", "mean corpuscular volume", "mcv"],
    "mch": ["mean corpuscular hemoglobin", "mch"],
    "mchc": ["mchc"],
    "rdw": ["rdw"],
    # Differential WBC
    "neutrophils": ["neutrophils", "neutrophil"],
    "lymphocytes": ["lymphocytes", "lymphocyte"],
    "eosinophils": ["eosinophils", "eosinophil"],
    "monocytes": ["monocytes", "monocyte"],
    "basophils": ["basophils", "basophil"],
    # Blood Sugar
    "glucose_fasting": ["fasting glucose", "fasting blood sugar", "fbs"],
    "glucose_pp": ["post prandial", "ppbs"],
    "glucose_random": ["random glucose", "random blood sugar", "rbs"],
    "hba1c": ["hba1c", "glycosylated hemoglobin"],
    # Lipid Profile
    "total_cholesterol": ["total cholesterol", "cholesterol"],
    "triglycerides": ["triglycerides", "triglyceride"],
    "hdl": ["hdl cholesterol", "hdl"],
    "ldl": ["ldl cholesterol", "ldl"],
    "vldl": ["vldl"],
    # Kidney
    "creatinine": ["serum creatinine", "creatinine"],
    "urea": ["blood urea", "urea"],
    "uric_acid": ["uric acid"],
    # Liver
    "bilirubin_total": ["total bilirubin", "bilirubin"],
    "sgot": ["sgot", "aspartate aminotransferase"],
    "sgpt": ["sgpt", "alanine aminotransferase"],
    "alp": ["alkaline phosphatase"],
    "total_protein": ["total protein"],
    "albumin": ["albumin"],
    # Thyroid
    "tsh": ["thyroid stimulating hormone", "tsh"],
    "t3": ["triiodothyronine", "t3"],
    "t4": ["thyroxine", "t4"],
    # Others
    "calcium": ["serum calcium", "calcium"],
    "iron": ["serum iron", "iron"],
    "vitamin_d": ["vitamin d", "25-oh vitamin d"],
    "vitamin_b12": ["vitamin b12", "b12"],
    "esr": ["erythrocyte sedimentation rate", "esr"],
}

# Words that should NOT be captured as units
SKIP_UNIT_WORDS = {"normal", "abnormal", "high", "low", "critical", "positive", "negative",
                   "reactive", "non", "borderline", "calculated", "electrical", "impedance",
                   "vcs", "tat", "blood", "sample", "day", "days"}

# Reasonable max values for each parameter to filter out garbage (phone numbers, etc.)
MAX_REASONABLE_VALUES = {
    "hemoglobin": 25, "rbc": 10, "wbc": 50000, "platelet": 1000000,
    "pcv": 70, "mcv": 150, "mch": 50, "mchc": 45, "rdw": 30,
    "neutrophils": 100, "lymphocytes": 100, "eosinophils": 100,
    "monocytes": 100, "basophils": 100,
    "glucose_fasting": 600, "glucose_pp": 600, "glucose_random": 600, "hba1c": 20,
    "total_cholesterol": 500, "triglycerides": 1000, "hdl": 150, "ldl": 300, "vldl": 100,
    "creatinine": 20, "urea": 200, "uric_acid": 20,
    "bilirubin_total": 30, "sgot": 500, "sgpt": 500, "alp": 800,
    "total_protein": 15, "albumin": 8,
    "tsh": 100, "t3": 500, "t4": 30,
    "calcium": 20, "iron": 500, "vitamin_d": 200, "vitamin_b12": 3000, "esr": 150,
}


def _find_all_numbers_in_line(text: str) -> list:
    """
    Find all decimal/integer numbers in a line with their positions.
    Returns list of (value_str, start_pos, end_pos).
    """
    results = []
    for match in re.finditer(r'(\d+\.?\d*)', text):
        results.append((match.group(1), match.start(), match.end()))
    return results


def _is_valid_unit(text: str) -> bool:
    """Check if extracted text is a valid measurement unit."""
    if not text:
        return False
    return text.lower().strip() not in SKIP_UNIT_WORDS


def extract_lab_parameters(text: str) -> Dict[str, Dict[str, str]]:
    """
    Extracts lab parameters from OCR text by matching known test names
    and extracting numeric values intelligently.
    """
    parameters = {}
    lines = text.split("\n")

    for line in lines:
        line_stripped = line.strip()
        line_lower = line_stripped.lower()

        if not line_lower or len(line_lower) < 3:
            continue

        # Skip header/footer lines that contain phone numbers, addresses, etc.
        if any(skip in line_lower for skip in ["phone", "email", "www.", "http", "page ",
                                                 "pathology lab", "healthcare", "road",
                                                 "complex", "mumbai", "delhi", "address",
                                                 "generated on", "collection", "whatsapp",
                                                 "qr code", "instruments:", "interpretation:",
                                                 "technician", "thanks for"]):
            continue

        for param_key, aliases in LAB_TEST_PATTERNS.items():
            if param_key in parameters:
                continue  # Already found this parameter

            for alias in aliases:
                alias_lower = alias.lower()
                idx = line_lower.find(alias_lower)

                if idx == -1:
                    continue

                # Found the keyword! Now extract numbers from the line.
                keyword_end = idx + len(alias_lower)

                # Get all numbers in the line
                all_numbers = _find_all_numbers_in_line(line_stripped)

                # Filter: only numbers AFTER the keyword position
                numbers_after_keyword = [
                    (val, start, end) for val, start, end in all_numbers
                    if start >= keyword_end
                ]

                if not numbers_after_keyword:
                    continue

                # Take the FIRST valid number after the keyword
                candidate_val = None
                candidate_pos_end = 0

                for val_str, start, end in numbers_after_keyword:
                    try:
                        val_float = float(val_str)
                    except ValueError:
                        continue

                    # Check if value is within reasonable range
                    max_val = MAX_REASONABLE_VALUES.get(param_key, 999999)
                    if val_float > max_val:
                        continue  # Skip garbage values (phone numbers etc.)

                    candidate_val = val_str
                    candidate_pos_end = end
                    break

                if candidate_val is None:
                    continue

                # Extract unit: the text immediately after the number
                remaining_after_val = line_stripped[candidate_pos_end:].strip()
                unit = ""
                unit_match = re.match(r'([a-zA-Z/%\.]+(?:/[a-zA-Z]+)*)', remaining_after_val)
                if unit_match:
                    potential_unit = unit_match.group(1)
                    if _is_valid_unit(potential_unit):
                        unit = potential_unit

                # Extract reference range from the line
                ref_range = ""
                ref_match = re.search(r'(\d+\.?\d*)\s*[-–]\s*(\d+\.?\d*)', line_stripped[keyword_end:])
                if ref_match:
                    ref_range = f"{ref_match.group(1)} - {ref_match.group(2)}"

                parameters[param_key] = {
                    "name": alias.title(),
                    "value": candidate_val,
                    "unit": unit,
                    "extracted_reference": ref_range
                }
                break  # Found this param, move to next

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

    # 2. Regex for dosage patterns
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
            timing_match = timing_pattern.search(line)
            timing = timing_match.group(0) if timing_match else ""

            if len(med_name) > 2:
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
