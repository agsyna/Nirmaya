import spacy
import re
from typing import Dict, List, Any

# Load the base spaCy English model (we will fine-tune this later for B.Tech project)
try:
    nlp = spacy.load("en_core_web_sm")
except OSError:
    print("Warning: en_core_web_sm not found. Run 'python -m spacy download en_core_web_sm'")
    nlp = None

def extract_lab_parameters(text: str) -> Dict[str, Dict[str, str]]:
    """
    Extracts key lab parameters, values, and units using Regex.
    Returns: {"Hemoglobin": {"value": "11.2", "unit": "g/dL"}, ...}
    """
    parameters = {}
    
    # Common lab test names to look out for
    test_keywords = [
        "Hemoglobin", "Glucose", "Sugar", "Cholesterol", "WBC", "RBC",
        "Platelet", "Creatinine", "Urea", "Thyroid", "TSH", "Calcium"
    ]
    
    lines = text.split("\n")
    for line in lines:
        for keyword in test_keywords:
            if keyword.lower() in line.lower():
                # Simple regex to find a number followed by an optional unit
                # Example matches: "11.2 g/dL", "150", "4.5 million/cumm"
                match = re.search(r'(\d+\.?\d*)\s*([a-zA-Z/%]+)?', line)
                if match:
                    val = match.group(1)
                    unit = match.group(2) if match.group(2) else ""
                    
                    # Store it
                    parameters[keyword] = {
                        "value": val,
                        "unit": unit.strip()
                    }
                    break # Move to next line once a parameter is found
                    
    return parameters
    
def extract_medicines(text: str) -> List[str]:
    """
    Attempts to extract medicines from a prescription using basic NLP NER 
    and regex for dosages (mg, ml, tablet).
    """
    medicines = []
    
    # 1. Use spaCy NER to find potential chemical/product names
    if nlp is not None:
        doc = nlp(text)
        for ent in doc.ents:
            if ent.label_ in ["PRODUCT", "ORG"]:
                medicines.append(ent.text)
                
    # 2. Use simple regex looking for dosage patterns (e.g., "Paracetamol 500mg")
    lines = text.split("\n")
    dosage_pattern = re.compile(r'\b(\w+)\s+\d+(mg|ml|mcg|g|tablet|cap|syrup)\b', re.IGNORECASE)
    
    for line in lines:
        for match in dosage_pattern.finditer(line):
            med_name = match.group(1)
            # Avoid picking up generic words if they accidentally match
            if len(med_name) > 3 and med_name not in medicines:
                medicines.append(med_name)
                
    # Deduplicate and clean
    return list(set(medicines))

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
