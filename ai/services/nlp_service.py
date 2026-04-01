import spacy
import re
from typing import Dict, List, Any, Optional, Tuple
from rapidfuzz import fuzz, process

# Load the base spaCy English model
try:
    nlp = spacy.load("en_core_web_sm")
except OSError:
    print("Warning: en_core_web_sm not found.")
    nlp = None

# Comprehensive list of lab test names with aliases
LAB_TEST_PATTERNS = {
    # CBC
    "hemoglobin": ["hemoglobin", "haemoglobin", "hemoglobin (hb)", "hemoglobin(hb)", "hb"],
    "rbc": ["total rbc count", "rbc count", "total rbc", "red blood cell count"],
    "wbc": ["total wbc count", "wbc count", "total wbc", "white blood cell count", "tlc"],
    "platelet": ["platelet count", "platelet"],
    "pcv": ["packed cell volume", "packed cell volume (pcv)", "pcv", "hematocrit", "hct"],
    "mcv": ["mean corpuscular volume", "mean corpuscular volume (mcv)", "mcv"],
    "mch": ["mean corpuscular hemoglobin", "mch"],
    "mchc": ["mchc"],
    "rdw": ["rdw", "red cell distribution width"],
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
    "sgot": ["sgot", "aspartate aminotransferase", "ast"],
    "sgpt": ["sgpt", "alanine aminotransferase", "alt"],
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

# All aliases flattened for fuzzy matching
ALL_ALIASES = {}
for param_key, aliases in LAB_TEST_PATTERNS.items():
    for alias in aliases:
        ALL_ALIASES[alias.lower()] = param_key

# Skip words for units
SKIP_UNIT_WORDS = {"normal", "abnormal", "high", "low", "critical", "positive", "negative",
                   "reactive", "non", "borderline", "calculated", "electrical", "impedance",
                   "vcs", "tat", "blood", "sample", "day", "days", "normat"}

# Max reasonable values to filter garbage
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

# Lines to skip (headers, footers, lab info)
SKIP_LINE_KEYWORDS = [
    "phone", "email", "www.", "http", "page ", "pathology lab", "healthcare",
    "road", "complex", "mumbai", "delhi", "address", "generated on", "collection",
    "whatsapp", "qr code", "instruments:", "interpretation:", "technician",
    "thanks for", "end of report", "reference", "sample type", "sample collected",
    "registered", "collected on", "reported on", "uhid", "investigation",
    "differential wbc", "blood indices", "drlogy", "accurate", "caring",
    "instant", "smart vision", "pathologist", "dmlt", "bmlt", "authenticity"
]


def _fuzzy_match_test_name(line_text: str) -> Optional[Tuple[str, str, int]]:
    """
    Uses fuzzy matching to find a lab test name in a garbled OCR line.
    Returns (param_key, matched_alias, match_end_position) or None.
    """
    line_lower = line_text.lower().strip()
    
    # 1. First try EXACT matching (fastest)
    for alias, param_key in sorted(ALL_ALIASES.items(), key=lambda x: len(x[0]), reverse=True):
        idx = line_lower.find(alias)
        if idx != -1:
            return param_key, alias, idx + len(alias)
    
    # 2. If exact match fails, try FUZZY matching on the first part of the line
    candidate = line_lower[:40]
    
    best_match = process.extractOne(
        candidate,
        ALL_ALIASES.keys(),
        scorer=fuzz.partial_ratio,
        score_cutoff=75
    )
    
    if best_match:
        matched_alias = best_match[0]
        score = best_match[1]
        param_key = ALL_ALIASES[matched_alias]
        
        # For very short aliases (<=3 chars), require higher score
        if len(matched_alias) <= 3 and score < 90:
            return None
        
        # Find where the test name actually ends in the original line.
        # Strategy: find the position of the first digit — that's where
        # the result value starts, so the test name ends just before it.
        digit_match = re.search(r'\d', line_text)
        if digit_match:
            match_end = digit_match.start()
        else:
            match_end = min(len(matched_alias) + 5, len(line_text))
        
        return param_key, matched_alias, match_end
    
    return None


def _extract_first_number(text: str, max_val: float = 999999) -> Optional[Tuple[str, int]]:
    """
    Find the first valid decimal/integer number in text within max_val range.
    Returns (value_str, end_position) or None.
    """
    for match in re.finditer(r'(\d+\.?\d*)', text):
        val_str = match.group(1)
        try:
            val = float(val_str)
            if val <= max_val:
                return val_str, match.end()
        except ValueError:
            continue
    return None


def _extract_unit(text: str) -> str:
    """Extract a valid measurement unit from text."""
    unit_match = re.match(r'\s*([a-zA-Z/%\.]+(?:/[a-zA-Z]+)*)', text)
    if unit_match:
        potential_unit = unit_match.group(1).strip()
        if potential_unit.lower() not in SKIP_UNIT_WORDS and len(potential_unit) <= 15:
            return potential_unit
    return ""


def _extract_reference_range(text: str) -> str:
    """Extract reference range like '13.00 - 17.00'."""
    match = re.search(r'(\d+\.?\d*)\s*[-–]\s*(\d+\.?\d*)', text)
    if match:
        return f"{match.group(1)} - {match.group(2)}"
    return ""


def _preprocess_lines(text: str) -> List[str]:
    """
    Preprocess OCR text: join lines where the value is on the next line.
    For example:
      MCH
      30 Normal 27-32 pg
    Gets joined into: MCH 30 Normal 27-32 pg
    """
    raw_lines = text.split("\n")
    merged = []
    i = 0
    while i < len(raw_lines):
        line = raw_lines[i].strip()
        # If this line is short (just a keyword, no numbers) and next line has a number
        if line and len(line) < 30 and not re.search(r'\d', line):
            # Check if next line starts with a number or has result data
            if i + 1 < len(raw_lines):
                next_line = raw_lines[i + 1].strip()
                if next_line and re.match(r'[\d°®o]', next_line):
                    # Join them
                    merged.append(f"{line} {next_line}")
                    i += 2
                    continue
        merged.append(line)
        i += 1
    return merged


def _extract_result_value(line: str, keyword_end_pos: int, param_key: str) -> Optional[Tuple[str, int]]:
    """
    Extract the RESULT value from a lab report line.
    
    Strategy: In lab reports, the structure is:
      TestName   Result   Normal   RefMin - RefMax   Unit
    So we look for numbers BEFORE the status word (Normal/Abnormal/High/Low)
    to avoid grabbing reference range numbers.
    """
    remaining = line[keyword_end_pos:]
    max_val = MAX_REASONABLE_VALUES.get(param_key, 999999)
    
    # Find where "Normal", "Abnormal", "High", "Low" appears
    status_pos = len(remaining)  # Default to end of line
    for status_word in ["normal", "normat", "abnormal", "high", "low"]:
        idx = remaining.lower().find(status_word)
        if idx != -1 and idx < status_pos:
            status_pos = idx
    
    # Look for the result number in the text BEFORE the status word
    before_status = remaining[:status_pos]
    
    # Find valid numbers in the before-status region
    for match in re.finditer(r'(\d+\.?\d*)', before_status):
        val_str = match.group(1)
        try:
            val = float(val_str)
            if val <= max_val:
                return val_str, keyword_end_pos + match.end()
        except ValueError:
            continue
    
    # Fallback: if no number found before status, try the whole line after keyword
    # but only take the first valid one
    for match in re.finditer(r'(\d+\.?\d*)', remaining):
        val_str = match.group(1)
        try:
            val = float(val_str)
            if val <= max_val:
                return val_str, keyword_end_pos + match.end()
        except ValueError:
            continue
    
    return None


def extract_lab_parameters(text: str) -> Dict[str, Dict[str, str]]:
    """
    Extracts lab parameters from OCR text using fuzzy matching for garbled text.
    Key improvement: extracts result values BEFORE the 'Normal' status word
    to avoid picking up reference range numbers.
    """
    parameters = {}
    lines = _preprocess_lines(text)

    for line in lines:
        line_stripped = line.strip()
        line_lower = line_stripped.lower()

        if not line_lower or len(line_lower) < 3:
            continue

        # Skip header/footer/irrelevant lines
        if any(skip in line_lower for skip in SKIP_LINE_KEYWORDS):
            continue

        # Try to match a test name (exact or fuzzy)
        match_result = _fuzzy_match_test_name(line_stripped)
        if not match_result:
            continue

        param_key, matched_alias, keyword_end_pos = match_result

        # Skip if already found
        if param_key in parameters:
            continue

        # Extract the result value (BEFORE "Normal" to avoid ref range numbers)
        number_result = _extract_result_value(line_stripped, keyword_end_pos, param_key)

        if not number_result:
            continue

        val_str, val_end_pos = number_result

        # Extract unit from text after the number
        after_val = line_stripped[val_end_pos:]
        unit = _extract_unit(after_val)

        # Extract reference range from the line
        ref_range = _extract_reference_range(line_stripped[keyword_end_pos:])

        parameters[param_key] = {
            "name": matched_alias.title(),
            "value": val_str,
            "unit": unit,
            "extracted_reference": ref_range,
            "matched_from": line_stripped[:60]  # Debug info
        }

    return parameters


def extract_medicines(text: str) -> List[Dict[str, str]]:
    """Extracts medicines and dosages from a prescription."""
    medicines = []

    if nlp is not None:
        doc = nlp(text)
        for ent in doc.ents:
            if ent.label_ in ["PRODUCT", "ORG"]:
                medicines.append({"name": ent.text, "source": "ner"})

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
                    medicines.append({"name": med_name, "dosage": dosage, "timing": timing, "source": "regex"})

    return medicines


def analyze_parsed_text(text: str, report_type: str = "lab_report") -> Dict[str, Any]:
    """Main router for text analysis."""
    result = {"raw_text_length": len(text), "parameters": {}, "medicines": []}

    if report_type == "lab_report":
        result["parameters"] = extract_lab_parameters(text)
    elif report_type == "prescription":
        result["medicines"] = extract_medicines(text)

    return result
