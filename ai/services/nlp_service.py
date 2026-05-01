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
# IMPORTANT: Order matters — longer/more-specific aliases are checked first
# to prevent partial matches from stealing results.
LAB_TEST_PATTERNS = {
    # CBC
    "hemoglobin": ["hemoglobin", "haemoglobin", "hemoglobin (hb)", "hemoglobin(hb)", "hb"],
    "rbc": ["total rbc count", "rbc count", "total rbc", "red blood cell count"],
    "wbc": ["total wbc count", "wbc count", "total wbc", "white blood cell count", "tlc"],
    "platelet": ["platelet count", "platelet"],
    "pcv": ["packed cell volume", "packed cell volume (pcv)", "pcv", "hematocrit", "hct"],
    "mpv": ["mpv", "mean platelet volume"],
    "mcv": ["mean corpuscular volume", "mean corpuscular volume (mcv)", "mcv"],
    "mch": ["mean corpuscular hemoglobin", "mch"],
    "mchc": ["mchc"],
    "rdw": ["rdw", "rdw cv", "red cell distribution width"],
    # Differential WBC
    "neutrophils": ["neutrophils", "neutrophil"],
    "lymphocytes": ["lymphocytes", "lymphocyte"],
    "eosinophils": ["eosinophils", "eosinophil"],
    "monocytes": ["monocytes", "monocyte"],
    "basophils": ["basophils", "basophil"],
    # Blood Sugar
    "glucose_fasting": ["fasting glucose", "fasting blood sugar", "fbs"],
    "glucose_pp": ["post prandial glucose", "post prandial blood sugar", "ppbs"],

    "glucose_random": ["random glucose", "random blood sugar", "rbs"],
    "hba1c": ["hba1c", "glycosylated hemoglobin"],
    # Lipid Profile
    "total_cholesterol": ["cholesterol - total", "total cholesterol", "cholesterol"],
    "triglycerides": ["triglycerides", "triglyceride"],
    "hdl": ["cholesterol - hdl", "hdl cholesterol", "hdl"],
    "ldl": ["cholesterol - ldl", "ldl cholesterol", "direct ldl", "ldl"],
    "vldl": ["cholesterol - vldl", "vldl"],
    # Kidney
    "creatinine": ["creatinine, serum", "serum creatinine", "creatinine"],
    "urea": ["blood urea nitrogen", "blood urea", "urea"],
    "uric_acid": ["uric acid"],
    # Liver / Hepatic Panel
    "bilirubin_total": ["bilirubin-total", "bilirubin - total", "total bilirubin", "tota bilirubin", "total bilrubin", "total billirubin"],
    "bilirubin_direct": ["bilirubin-direct", "bilirubin - direct", "conjugated bilirubin", "direct bilirubin"],
    "bilirubin_indirect": ["bilirubin-indirect", "bilirubin - indirect", "unconjugated bilirubin", "indirect bilirubin"],
    "delta_bilirubin": ["delta bilirubin"],
    "sgot": ["sgot", "aspartate aminotransferase", "ast"],
    "sgpt": ["sgpt", "alanine aminotransferase", "alt"],
    "alp": ["alkaline phosphatase", "alk phosphatase"],
    "ggt": ["gamma glutamyl transferase", "gamma gt", "ggt"],
    "total_protein": ["total protein"],
    "albumin": ["serum albumin", "albumin"],
    "globulin": ["globulin"],
    "ag_ratio": ["a/g ratio", "ag ratio", "aig ratio", "a|g ratio", "albumin/globulin ratio", "albumin globulin ratio"],
    # Thyroid
    "tsh": ["tsh - thyroid stimulating hormone", "thyroid stimulating hormone", "tsh"],
    "t3": ["t3 - triiodothyronine", "triiodothyronine", "total t3"],
    "t4": ["t4 - thyroxine", "thyroxine", "total t4"],
    "ft3": ["free t3", "ft3"],
    "ft4": ["free t4", "ft4"],
    # Others
    "calcium": ["serum calcium", "calcium"],
    "iron": ["serum iron"],
    "vitamin_d": ["25(oh) vitamin d", "25-oh vitamin d", "25 hydroxy vitamin d", "vitamin d"],
    "vitamin_b12": ["vitamin b12", "cyanocobalamin"],
    "esr": ["erythrocyte sedimentation rate", "esr"],
    "crp": ["c-reactive protein", "c reactive protein", "crp"],
    "sodium": ["sodium", "serum sodium"],
    "potassium": ["potassium", "serum potassium"],
    "chloride": ["chloride", "serum chloride"],
}

# All aliases flattened for fuzzy matching
ALL_ALIASES = {}
for param_key, aliases in LAB_TEST_PATTERNS.items():
    for alias in aliases:
        ALL_ALIASES[alias.lower()] = param_key

# Skip words for units
SKIP_UNIT_WORDS = {"normal", "abnormal", "high", "low", "critical", "positive", "negative",
                   "reactive", "non", "borderline", "calculated", "electrical", "impedance",
                   "vcs", "tat", "blood", "sample", "day", "days", "normat", "final",
                   "method", "green", "copper", "tartrate", "binding", "mordant",
                   "cationic", "ationic"}

# Max reasonable values to filter garbage
MAX_REASONABLE_VALUES = {
    "hemoglobin": 25, "rbc": 10, "wbc": 50000, "platelet": 1000000,
    "pcv": 70, "mcv": 150, "mch": 50, "mchc": 45, "rdw": 30, "mpv": 20,
    "neutrophils": 100, "lymphocytes": 100, "eosinophils": 100,
    "monocytes": 100, "basophils": 100,
    "glucose_fasting": 600, "glucose_pp": 600, "glucose_random": 600, "hba1c": 20,
    "total_cholesterol": 500, "triglycerides": 1000, "hdl": 150, "ldl": 300, "vldl": 100,
    "creatinine": 20, "urea": 200, "uric_acid": 20,
    "bilirubin_total": 30, "bilirubin_direct": 15, "bilirubin_indirect": 15,
    "delta_bilirubin": 15,
    "sgot": 500, "sgpt": 500, "alp": 800, "ggt": 500,
    "total_protein": 15, "albumin": 8, "globulin": 8, "ag_ratio": 5,
    "tsh": 100, "t3": 500, "t4": 30, "ft3": 20, "ft4": 10,
    "calcium": 20, "iron": 500, "vitamin_d": 200, "vitamin_b12": 3000, "esr": 150,
    "crp": 500, "sodium": 200, "potassium": 10, "chloride": 200,
}

# Lines to skip (headers, footers, lab info)
SKIP_LINE_KEYWORDS = [
    "phone", "email", "www.", "http", "page ", "pathology lab",
    "road", "address", "generated on",
    "whatsapp", "qr code", "instruments:", "interpretation:", "technician",
    "thanks for", "end of report", "sample type", "sample collected",
    "registered on", "collected on", "reported on", "uhid", "investigation",
    "differential wbc", "blood indices", "drlogy",
    "smart vision", "pathologist", "dmlt", "bmlt", "authenticity",
    "passport no", "laboratory test report", "patient information",
    "sample information", "client/location", "client name", "clientname",
    "location", "approved on", "printed on", "process at", "status:",
    "ref. by", "ref.ld", "lab id", "registration on", "sex/age",
    "scan qr", "report authenticity", "test result unit", "bromocresol",
    "biological ref", "sterling accuris", "microalbumin",
    "peripheral smear", "morphology", "normochromic", "normocytic",
    "malarial parasite", "electronically authenticated",
    "referred test", "male /", "female /", "hematopathologist",
    "microscopic examination", "pus cells", "epithelial cells",
    "hyaline casts", "rbc casts", "wbc casts", "granular casts",
    "waxy casts", "fatty casts", "amorphous material",
    "calcium oxalate", "calcium phosphate", "cystine crystals",
    "leucine crystals", "tyrosine crystals", "triple phosphate",
    "uric acid crystals", "urine routine", "physical & chemical",
    "dip strip", "specific gravity", "leucocyte esterase",
    "nitrite reaction", "griess reaction", "ascorbic acid",
    "indophenol", "tetra-bromphenol", "tetramethyl",
    "book more tests", "your health journey", "click here",
    "schedule now", "explore now", "connect now",
    "tata 1mg", "page ", "disclaimer", "t&c apply",
    "cholesterol : hdl", "ldl : hdl", "chol/hdl",
    "sgot/sgpt", "ldl/hdl", "non hdl cholesterol",
    "cholesterol- vldl", "cholesterol : hdl cholesterol",
    "ldl : hdl cholesterol",
    "red blood cell",  # singular = urine, blood test uses "RBC" or "RBC Count"
    "males <", "females <", "male >", "female >",
    "screening of", "identification of", "lipid association",
    "risk group", "risk factor", "primary target",
    "co-primary", "secondary target", "optional",
    "extreme-risk", "moderate-risk", "low-risk", "high-risk",
    "very high-risk", "lai ", "ncep", "apo-b",
    "fasting not", "lifestyle", "testing for"
]


def _fuzzy_match_test_name(line_text: str) -> Optional[Tuple[str, str, int]]:
    """
    Uses fuzzy matching to find a lab test name in a garbled OCR line.
    Returns (param_key, matched_alias, match_end_position) or None.
    """
    line_lower = line_text.lower().strip()

    # 1. First try EXACT matching (fastest, most reliable)
    # Sort by length descending so longer aliases match first
    # e.g. "total bilirubin" matches before "bilirubin"
    for alias, param_key in sorted(ALL_ALIASES.items(), key=lambda x: len(x[0]), reverse=True):
        idx = line_lower.find(alias)
        if idx != -1:
            # SHORT ALIASES (<=3 chars) need word-boundary check
            # to prevent "ast" matching inside "Fasting", "hb" in "HBsAg" etc.
            if len(alias) <= 3:
                # Check char before: must be start-of-line or non-alphanumeric
                if idx > 0 and line_lower[idx - 1].isalnum():
                    continue
                # Check char after: must be end-of-line or non-alphanumeric
                end_idx = idx + len(alias)
                if end_idx < len(line_lower) and line_lower[end_idx].isalnum():
                    continue
            return param_key, alias, idx + len(alias)

    # 2. If exact match fails, try FUZZY matching on the first part of the line
    candidate = line_lower[:45]

    # Only attempt fuzzy match against LONG aliases (>= 5 chars)
    # Short aliases like "hb", "mcv", "iron", "esr", "hdl" cause too many false positives
    long_aliases = {k: v for k, v in ALL_ALIASES.items() if len(k) >= 5}

    best_match = process.extractOne(
        candidate,
        long_aliases.keys(),
        scorer=fuzz.partial_ratio,
        score_cutoff=82  # Higher threshold = fewer false positives
    )

    if best_match:
        matched_alias = best_match[0]
        score = best_match[1]
        param_key = long_aliases[matched_alias]

        # Extra guard: the matched alias must share significant character overlap
        # with the candidate to prevent cross-category matches
        # e.g. prevent "total bilirubin" matching "total rbc"
        token_ratio = fuzz.token_sort_ratio(candidate[:len(matched_alias)+10], matched_alias)
        if token_ratio < 60:
            return None

        # Find where the test name actually ends in the original line.
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
        potential_unit = unit_match.group(1).strip().rstrip('.')
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
      TestName   Result   Normal/Status   RefMin - RefMax   Unit
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

    # Also look for reference range pattern (digits-digits) as status boundary
    ref_match = re.search(r'\d+\.?\d*\s*[-–]\s*\d+\.?\d*', remaining)
    if ref_match and ref_match.start() < status_pos:
        # The reference range starts before the status word, use it as boundary
        # but only if status_pos is at end of line (no status word found)
        if status_pos == len(remaining):
            status_pos = ref_match.start()

    # Look for the result number in the text BEFORE the status/reference word
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
    for match in re.finditer(r'(\d+\.?\d*)', remaining):
        val_str = match.group(1)
        try:
            val = float(val_str)
            if val <= max_val:
                return val_str, keyword_end_pos + match.end()
        except ValueError:
            continue

    return None

def _is_unit_line(line: str) -> bool:
    """Check if a line is likely a measurement unit (g/dL, %, mg/dL, etc.).
    IMPORTANT: Must NOT match test names like 'Hemoglobin', 'MCV', etc.
    Uses a whitelist approach instead of broad regex.
    """
    line = line.strip()
    if not line or len(line) > 20:
        return False
    
    line_lower = line.lower()
    
    # Known unit strings (exact or prefix match)
    KNOWN_UNITS = {
        "%", "g/dl", "mg/dl", "mg/l", "ng/ml", "ng/dl", "pg/ml", "pg",
        "fl", "u/l", "iu/ml", "iu/l", "meq/l", "mmol/l", "umol/l",
        "mm/hr", "mm/1hr", "cells/cumm", "mill/cumm", "million/cmm",
        "million/cumm", "/cmm", "/cumm", "/hpf", "ug/dl", "ug/l",
        "mg/g", "s/co", "microiu/ml", "micromol/l", "micro g/dl",
        "ratio",
    }
    
    # Check exact match
    if line_lower in KNOWN_UNITS:
        return True
    
    # Check if it contains a slash (most units do) and is short
    # BUT reject if it starts with a digit UNLESS it's scientific notation (10^3, 10^6)
    # Real units don't start with numbers, but "10^3/µL" and "10^6/cu.mm" do
    if '/' in line and len(line) <= 20:
        stripped = line.strip()
        if not re.match(r'^\d', stripped):
            return True
        # Allow scientific notation units like 10^3/µL, 10^6/cu.mm
        if re.match(r'^10\^\d', stripped):
            return True
    
    # Single character units like H, L (high/low flags) are NOT units
    return False


def _is_ref_range_line(line: str) -> bool:
    """Check if a line contains a reference range (e.g., '13.0 - 16.5')."""
    return bool(re.search(r'\d+\.?\d*\s*[-–]\s*\d+\.?\d*', line))


def _is_standalone_number(line: str) -> bool:
    """Check if a line is just a number (possibly with < > prefix)."""
    return bool(re.match(r'^[<>]?\s*\d+\.?\d*\s*$', line.strip()))


def _is_method_line(line: str) -> bool:
    """Check if a line is a testing method name."""
    methods = ["colorimetric", "calculated", "electrical impedance",
               "microscopic", "derived", "immunoturbidimetric",
               "chemiluminescence", "clia", "uricase", "direct",
               "arsenazo", "enzymatic", "god-pod", "urease",
               "chromatography", "diazo", "modified ehrlich",
               "nitroprusside", "polyelectrolyte", "direct- ise",
               "uv with", "pyridyl", "copper tartrate", "bromocresol",
               "protein error", "sf cube", "cationic mordant",
               "azobilirubin", "creatinine amidohydrolase",
               "lipase", "peroxidase", "cholesterol oxidase"]
    line_lower = line.strip().lower()
    return any(m in line_lower for m in methods)


def _extract_vertical_parameters(text: str, existing_params: Dict) -> Dict[str, Dict[str, str]]:
    """
    Extract parameters from VERTICAL format reports (common in digital PDFs).
    
    Vertical format structure:
        TestName              ← Line 1: test name
        Unit                  ← Line 2: unit (g/dL, %, etc.)
        RefMin - RefMax       ← Line 3: reference range
        Method                ← Line 4: method name (optional)
        ResultValue           ← Line 5: just a number = the result!
    """
    parameters = {}
    lines = text.split("\n")
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        line_lower = line.lower()
        
        if not line or len(line) < 2:
            i += 1
            continue
        
        # Skip known header/footer lines
        if any(skip in line_lower for skip in SKIP_LINE_KEYWORDS):
            i += 1
            continue
        
        # Skip lines that are just numbers, units, methods, or ref ranges
        if _is_standalone_number(line) or _is_unit_line(line) or _is_method_line(line):
            i += 1
            continue
        
        # Try to match this line as a test name
        match_result = _fuzzy_match_test_name(line)
        if not match_result:
            i += 1
            continue
        
        param_key, matched_alias, _ = match_result
        
        # Skip if already found (from horizontal parse or earlier vertical match)
        if param_key in existing_params or param_key in parameters:
            i += 1
            continue
        
        # Check if this line already has a number on it (horizontal format)
        # If so, skip — let the horizontal parser handle it
        has_number_on_line = bool(re.search(r'\d+\.?\d*', line[len(matched_alias):]))
        if has_number_on_line:
            i += 1
            continue
        
        # VERTICAL MODE: scan ahead up to 8 lines for the result value
        unit = ""
        ref_range = ""
        result_value = None
        max_val = MAX_REASONABLE_VALUES.get(param_key, 999999)
        
        for j in range(1, 15):
            if i + j >= len(lines):
                break
            
            next_line = lines[i + j].strip()
            if not next_line:
                continue
            
            # If we hit another test name, stop scanning
            next_match = _fuzzy_match_test_name(next_line)
            if next_match and next_match[0] != param_key:
                # Check it's not a method/unit/skip line that accidentally matches
                if not _is_unit_line(next_line) and not _is_method_line(next_line):
                    break
            
            # Capture unit
            if _is_unit_line(next_line) and not unit:
                unit = next_line.strip()
                continue
            
            # Capture reference range
            if _is_ref_range_line(next_line) and not ref_range:
                ref_range = _extract_reference_range(next_line)
                continue
            
            # Skip method lines
            if _is_method_line(next_line):
                continue
            
            # Skip complex ref range description lines (like "Desirable : <200")
            if re.match(r'^(desirable|borderline|optimal|near|high|low|very|non|poor|good|for |pre-|deficiency|insufficiency|sufficiency|toxicity|children|adult|diabetes|screening|reactive|interpretation|increased|decreased|limitation|summary|explanation|reference|note|disclaimer|normal :|absent|ratio|comment|source|treatment)', next_line.lower()):
                continue
            
            # Check for COMBINED "value     unit" lines (e.g. "20     U/L", "14.4     g/dL")
            # Common in Tata 1mg smart report format
            combo_match = re.match(r'^([<>]?\s*\d+\.?\d*)\s{2,}(.+)$', next_line)
            if combo_match:
                combo_val_str = combo_match.group(1).strip().replace('<','').replace('>','')
                combo_unit_str = combo_match.group(2).strip()
                # Verify the unit part looks like a real unit (not a test name)
                # Allow units starting with digits ONLY if scientific notation (10^)
                unit_looks_valid = (
                    len(combo_unit_str) <= 15 and 
                    (not combo_unit_str[0].isdigit() or combo_unit_str.startswith('10^'))
                )
                if unit_looks_valid:
                    try:
                        val = float(combo_val_str)
                        if val <= max_val:
                            result_value = combo_val_str
                            if not unit:
                                unit = combo_unit_str
                            break
                    except ValueError:
                        pass
            
            # Check if it's a standalone number — this is our RESULT!
            if _is_standalone_number(next_line):
                # RATIO CHECK: peek at the line AFTER this number
                # If it says "Ratio", this is a ratio value, not the actual test result
                peek_idx = i + j + 1
                if peek_idx < len(lines) and lines[peek_idx].strip().lower().startswith('ratio'):
                    continue  # Skip this number, it's a ratio
                
                clean = re.sub(r'[<>]', '', next_line).strip()
                try:
                    val = float(clean)
                    if val <= max_val:
                        result_value = clean
                        break
                except ValueError:
                    continue
        
        if result_value:
            # Skip urine microscopy results (unit /hpf) — not blood tests
            if unit and '/hpf' in unit.lower():
                i += 1
                continue
            
            parameters[param_key] = {
                "name": matched_alias.title(),
                "value": result_value,
                "unit": unit,
                "extracted_reference": ref_range,
                "matched_from": f"[vertical] {line[:50]}"
            }
        
        i += 1
    
    return parameters


def extract_lab_parameters(text: str) -> Dict[str, Dict[str, str]]:
    """
    Extracts lab parameters from OCR text using TWO parsing strategies:
    
    1. HORIZONTAL parser: for tabular reports where everything is on one line
       e.g., "Hemoglobin (Hb)   13.00   Normal   13.00-17.00   g/dL"
       
    2. VERTICAL parser: for digital PDF reports where data spans multiple lines
       e.g., "Hemoglobin\n g/dL\n 13.0-16.5\n Colorimetric\n 14.5"
    
    Both parsers run, and results are merged (vertical takes priority since it's
    more precise for structured multi-line reports).
    """
    parameters = {}
    lines = _preprocess_lines(text)

    # ===== PASS 1: Vertical parser (for digital PDF reports) =====
    # Run first because it's more precise — it finds the result value
    # in the correct position (after ref range & method lines)
    vertical_params = _extract_vertical_parameters(text, {})
    parameters.update(vertical_params)

    # ===== PASS 2: Horizontal parser (for tabular/image reports) =====
    # Fills in anything the vertical parser missed
    for line in lines:
        line_stripped = line.strip()
        line_lower = line_stripped.lower()

        if not line_lower or len(line_lower) < 3:
            continue

        if any(skip in line_lower for skip in SKIP_LINE_KEYWORDS):
            continue

        match_result = _fuzzy_match_test_name(line_stripped)
        if not match_result:
            continue

        param_key, matched_alias, keyword_end_pos = match_result

        # Skip if already found by vertical parser
        if param_key in parameters:
            continue

        number_result = _extract_result_value(line_stripped, keyword_end_pos, param_key)

        if not number_result:
            continue

        val_str, val_end_pos = number_result

        after_val = line_stripped[val_end_pos:]
        unit = _extract_unit(after_val)
        ref_range = _extract_reference_range(line_stripped[keyword_end_pos:])

        parameters[param_key] = {
            "name": matched_alias.title(),
            "value": val_str,
            "unit": unit,
            "extracted_reference": ref_range,
            "matched_from": f"[horizontal] {line_stripped[:50]}"
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
