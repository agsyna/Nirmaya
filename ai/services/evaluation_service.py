from typing import Dict, Any

# Comprehensive reference ranges database
# Source: Standard Indian pathology lab reference ranges
# Note: These are general adult ranges. Gender/age-specific ranges can be added later.
REFERENCE_RANGES = {
    # ===== CBC =====
    "hemoglobin": {
        "display_name": "Hemoglobin (Hb)",
        "unit": "g/dL",
        "min": 12.0, "max": 17.0,
        "critical_min": 7.0, "critical_max": 20.0
    },
    "rbc": {
        "display_name": "Total RBC Count",
        "unit": "mill/cumm",
        "min": 4.5, "max": 5.5,
        "critical_min": 2.0, "critical_max": 8.0
    },
    "wbc": {
        "display_name": "Total WBC Count",
        "unit": "cells/cumm",
        "min": 4000, "max": 11000,
        "critical_min": 2000, "critical_max": 30000
    },
    "platelet": {
        "display_name": "Platelet Count",
        "unit": "cells/cumm",
        "min": 150000, "max": 410000,
        "critical_min": 50000, "critical_max": 1000000
    },
    "pcv": {
        "display_name": "Packed Cell Volume (PCV)",
        "unit": "%",
        "min": 36, "max": 50,
        "critical_min": 20, "critical_max": 60
    },
    "mcv": {
        "display_name": "Mean Corpuscular Volume (MCV)",
        "unit": "fL",
        "min": 83, "max": 101,
        "critical_min": 60, "critical_max": 120
    },
    "mch": {
        "display_name": "MCH",
        "unit": "pg",
        "min": 27, "max": 32,
        "critical_min": 20, "critical_max": 40
    },
    "mchc": {
        "display_name": "MCHC",
        "unit": "g/dL",
        "min": 32.5, "max": 34.5,
        "critical_min": 28, "critical_max": 38
    },
    "rdw": {
        "display_name": "RDW",
        "unit": "%",
        "min": 11.6, "max": 14.0,
        "critical_min": 8, "critical_max": 20
    },
    "mpv": {
        "display_name": "Mean Platelet Volume",
        "unit": "fL",
        "min": 7.5, "max": 10.5,
        "critical_min": 5, "critical_max": 15
    },
    # ===== Differential WBC =====
    "neutrophils": {
        "display_name": "Neutrophils",
        "unit": "%",
        "min": 50, "max": 62,
        "critical_min": 20, "critical_max": 90
    },
    "lymphocytes": {
        "display_name": "Lymphocytes",
        "unit": "%",
        "min": 20, "max": 40,
        "critical_min": 5, "critical_max": 70
    },
    "eosinophils": {
        "display_name": "Eosinophils",
        "unit": "%",
        "min": 0, "max": 6,
        "critical_min": 0, "critical_max": 20
    },
    "monocytes": {
        "display_name": "Monocytes",
        "unit": "%",
        "min": 0, "max": 10,
        "critical_min": 0, "critical_max": 20
    },
    "basophils": {
        "display_name": "Basophils",
        "unit": "%",
        "min": 0, "max": 2,
        "critical_min": 0, "critical_max": 5
    },
    # ===== Blood Sugar =====
    "glucose_fasting": {
        "display_name": "Fasting Blood Sugar",
        "unit": "mg/dL",
        "min": 70, "max": 100,
        "critical_min": 50, "critical_max": 400
    },
    "glucose_pp": {
        "display_name": "Post Prandial Blood Sugar",
        "unit": "mg/dL",
        "min": 70, "max": 140,
        "critical_min": 50, "critical_max": 400
    },
    "glucose_random": {
        "display_name": "Random Blood Sugar",
        "unit": "mg/dL",
        "min": 70, "max": 140,
        "critical_min": 50, "critical_max": 400
    },
    "hba1c": {
        "display_name": "HbA1c",
        "unit": "%",
        "min": 4.0, "max": 5.6,
        "critical_min": 3.0, "critical_max": 14.0
    },
    # ===== Lipid Profile =====
    "total_cholesterol": {
        "display_name": "Total Cholesterol",
        "unit": "mg/dL",
        "min": 0, "max": 200,
        "critical_min": 0, "critical_max": 300
    },
    "triglycerides": {
        "display_name": "Triglycerides",
        "unit": "mg/dL",
        "min": 0, "max": 150,
        "critical_min": 0, "critical_max": 500
    },
    "hdl": {
        "display_name": "HDL Cholesterol",
        "unit": "mg/dL",
        "min": 40, "max": 60,
        "critical_min": 20, "critical_max": 100
    },
    "ldl": {
        "display_name": "LDL Cholesterol",
        "unit": "mg/dL",
        "min": 0, "max": 100,
        "critical_min": 0, "critical_max": 190
    },
    "vldl": {
        "display_name": "VLDL",
        "unit": "mg/dL",
        "min": 5, "max": 40,
        "critical_min": 0, "critical_max": 80
    },
    # ===== Kidney / Renal =====
    "creatinine": {
        "display_name": "Serum Creatinine",
        "unit": "mg/dL",
        "min": 0.7, "max": 1.3,
        "critical_min": 0.3, "critical_max": 10.0
    },
    "urea": {
        "display_name": "Blood Urea",
        "unit": "mg/dL",
        "min": 15, "max": 40,
        "critical_min": 5, "critical_max": 100
    },
    "uric_acid": {
        "display_name": "Uric Acid",
        "unit": "mg/dL",
        "min": 3.5, "max": 7.2,
        "critical_min": 1.0, "critical_max": 12.0
    },
    # ===== Liver / Hepatic =====
    "bilirubin_total": {
        "display_name": "Total Bilirubin",
        "unit": "mg/dL",
        "min": 0.1, "max": 1.2,
        "critical_min": 0, "critical_max": 15.0
    },
    "bilirubin_direct": {
        "display_name": "Direct Bilirubin",
        "unit": "mg/dL",
        "min": 0.0, "max": 0.3,
        "critical_min": 0, "critical_max": 10.0
    },
    "sgot": {
        "display_name": "SGOT (AST)",
        "unit": "U/L",
        "min": 0, "max": 40,
        "critical_min": 0, "critical_max": 200
    },
    "sgpt": {
        "display_name": "SGPT (ALT)",
        "unit": "U/L",
        "min": 0, "max": 40,
        "critical_min": 0, "critical_max": 200
    },
    "alp": {
        "display_name": "Alkaline Phosphatase",
        "unit": "U/L",
        "min": 44, "max": 147,
        "critical_min": 20, "critical_max": 500
    },
    "total_protein": {
        "display_name": "Total Protein",
        "unit": "g/dL",
        "min": 6.0, "max": 8.3,
        "critical_min": 3.0, "critical_max": 12.0
    },
    "albumin": {
        "display_name": "Albumin",
        "unit": "g/dL",
        "min": 3.5, "max": 5.5,
        "critical_min": 1.5, "critical_max": 7.0
    },
    "globulin": {
        "display_name": "Globulin",
        "unit": "g/dL",
        "min": 2.0, "max": 3.5,
        "critical_min": 1.0, "critical_max": 6.0
    },
    "ag_ratio": {
        "display_name": "A/G Ratio",
        "unit": "",
        "min": 1.2, "max": 2.2,
        "critical_min": 0.5, "critical_max": 3.5
    },
    "bilirubin_indirect": {
        "display_name": "Unconjugated (Indirect) Bilirubin",
        "unit": "mg/dL",
        "min": 0.0, "max": 1.1,
        "critical_min": 0, "critical_max": 10.0
    },
    "delta_bilirubin": {
        "display_name": "Delta Bilirubin",
        "unit": "mg/dL",
        "min": 0.0, "max": 0.2,
        "critical_min": 0, "critical_max": 5.0
    },
    "ggt": {
        "display_name": "GGT (Gamma GT)",
        "unit": "U/L",
        "min": 0, "max": 55,
        "critical_min": 0, "critical_max": 300
    },
    # ===== Thyroid =====
    "tsh": {
        "display_name": "TSH",
        "unit": "mIU/L",
        "min": 0.4, "max": 4.0,
        "critical_min": 0.01, "critical_max": 50.0
    },
    "t3": {
        "display_name": "T3",
        "unit": "ng/dL",
        "min": 80, "max": 200,
        "critical_min": 40, "critical_max": 400
    },
    "t4": {
        "display_name": "T4",
        "unit": "ug/dL",
        "min": 4.5, "max": 12.0,
        "critical_min": 1.0, "critical_max": 25.0
    },
    "ft3": {
        "display_name": "Free T3",
        "unit": "pg/mL",
        "min": 2.0, "max": 4.4,
        "critical_min": 1.0, "critical_max": 10.0
    },
    "ft4": {
        "display_name": "Free T4",
        "unit": "ng/dL",
        "min": 0.8, "max": 1.8,
        "critical_min": 0.3, "critical_max": 5.0
    },
    # ===== Others =====
    "calcium": {
        "display_name": "Calcium",
        "unit": "mg/dL",
        "min": 8.5, "max": 10.5,
        "critical_min": 6.0, "critical_max": 14.0
    },
    "iron": {
        "display_name": "Serum Iron",
        "unit": "ug/dL",
        "min": 60, "max": 170,
        "critical_min": 20, "critical_max": 300
    },
    "vitamin_d": {
        "display_name": "Vitamin D",
        "unit": "ng/mL",
        "min": 30, "max": 100,
        "critical_min": 10, "critical_max": 150
    },
    "vitamin_b12": {
        "display_name": "Vitamin B12",
        "unit": "pg/mL",
        "min": 200, "max": 900,
        "critical_min": 100, "critical_max": 2000
    },
    "esr": {
        "display_name": "ESR",
        "unit": "mm/hr",
        "min": 0, "max": 20,
        "critical_min": 0, "critical_max": 100
    },
    "crp": {
        "display_name": "C-Reactive Protein",
        "unit": "mg/L",
        "min": 0, "max": 5,
        "critical_min": 0, "critical_max": 200
    },
    "sodium": {
        "display_name": "Sodium",
        "unit": "mEq/L",
        "min": 136, "max": 145,
        "critical_min": 120, "critical_max": 160
    },
    "potassium": {
        "display_name": "Potassium",
        "unit": "mEq/L",
        "min": 3.5, "max": 5.0,
        "critical_min": 2.5, "critical_max": 6.5
    },
    "chloride": {
        "display_name": "Chloride",
        "unit": "mEq/L",
        "min": 98, "max": 106,
        "critical_min": 80, "critical_max": 120
    },
}


import re as _re


def _parse_extracted_reference(ref_str: str):
    """
    Parses the reference range string extracted from the report.
    Returns (min_val, max_val) if successfully parsed, else None.
    
    Handles formats like:
        "13.0 - 16.5"
        "0.66 - 1.25"
        "4000 - 10000"
        "150000 - 410000"
    """
    if not ref_str:
        return None
    
    match = _re.search(r'(\d+\.?\d*)\s*[-–]\s*(\d+\.?\d*)', ref_str)
    if match:
        try:
            min_val = float(match.group(1))
            max_val = float(match.group(2))
            if min_val < max_val:
                return (min_val, max_val)
        except ValueError:
            pass
    
    return None


def evaluate_parameters(parameters: Dict[str, Dict[str, str]]) -> Dict[str, Any]:
    """
    Compares extracted parameters against reference ranges.
    
    STRATEGY: Report-First, Hardcoded-Fallback
    1. First, try to use the reference range extracted from the report itself
       (more accurate, lab-specific)
    2. If not available/parseable, fall back to our hardcoded standard ranges
    3. Critical thresholds always come from hardcoded database
    
    This ensures each parameter is evaluated against the SAME reference range
    the lab intended, not a generic one.
    """
    evaluated_results = {}
    health_score_points = 0
    total_params = 0

    for param_key, data in parameters.items():
        val_str = data.get("value", "")
        extracted_unit = data.get("unit", "")
        display_name = data.get("name", param_key)
        extracted_ref = data.get("extracted_reference", "")

        try:
            val = float(val_str)
        except ValueError:
            evaluated_results[display_name] = {
                "value": val_str,
                "status": "Unknown",
                "message": "Could not parse value"
            }
            continue

        # Get hardcoded reference (for fallback and critical thresholds)
        hardcoded_ref = REFERENCE_RANGES.get(param_key)
        
        # Try report's own reference range first
        report_range = _parse_extracted_reference(extracted_ref)
        
        if report_range:
            # USE REPORT'S REFERENCE RANGE (more accurate, lab-specific)
            ref_min, ref_max = report_range
            ref_source = "report"
        elif hardcoded_ref:
            # FALLBACK: use our hardcoded standard range
            ref_min = hardcoded_ref["min"]
            ref_max = hardcoded_ref["max"]
            ref_source = "standard"
        else:
            # No reference range available at all
            evaluated_results[display_name] = {
                "value": val,
                "unit": extracted_unit,
                "status": "Unknown",
                "reference_range": "Not available",
                "message": "No reference range available"
            }
            continue

        total_params += 1
        status = "Normal"
        
        # Critical thresholds always from hardcoded (if available)
        critical_min = hardcoded_ref["critical_min"] if hardcoded_ref else ref_min * 0.3
        critical_max = hardcoded_ref["critical_max"] if hardcoded_ref else ref_max * 3.0

        # Evaluate: critical first, then normal range
        if val <= critical_min:
            status = "CRITICAL LOW"
            health_score_points += 3
        elif val >= critical_max:
            status = "CRITICAL HIGH"
            health_score_points += 3
        elif val < ref_min:
            status = "Low"
            health_score_points += 1
        elif val > ref_max:
            status = "High"
            health_score_points += 1

        # Build the reference range display string
        ref_unit = extracted_unit if extracted_unit else (hardcoded_ref["unit"] if hardcoded_ref else "")
        ref_display = f"{ref_min} - {ref_max} {ref_unit}".strip()

        evaluated_results[display_name] = {
            "value": val,
            "unit": extracted_unit if extracted_unit else (hardcoded_ref["unit"] if hardcoded_ref else ""),
            "status": status,
            "reference_range": ref_display,
            "ref_source": ref_source  # Shows if range came from report or standard
        }

    # Overall risk assessment
    overall_risk = "Low Risk"
    if health_score_points >= 6:
        overall_risk = "High Risk — Requires immediate doctor consultation"
    elif health_score_points >= 3:
        overall_risk = "Medium Risk — Monitor and consult doctor"
    elif health_score_points > 0:
        overall_risk = "Low-Medium Risk — Minor deviations detected"

    return {
        "details": evaluated_results,
        "parameters_found": len(evaluated_results),
        "parameters_evaluated": total_params,
        "overall_health_risk": overall_risk,
        "ml_model_used": "Heuristic (Pending XGBoost implementation)"
    }
