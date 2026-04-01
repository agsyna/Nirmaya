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
}


def evaluate_parameters(parameters: Dict[str, Dict[str, str]]) -> Dict[str, Any]:
    """
    Compares extracted parameters against standard reference ranges.
    Flags each as Normal, High, Low, or Critical.
    """
    evaluated_results = {}
    health_score_points = 0
    total_params = 0

    for param_key, data in parameters.items():
        val_str = data.get("value", "")
        extracted_unit = data.get("unit", "")
        display_name = data.get("name", param_key)

        try:
            val = float(val_str)
        except ValueError:
            evaluated_results[display_name] = {
                "value": val_str,
                "status": "Unknown",
                "message": "Could not parse value"
            }
            continue

        ref = REFERENCE_RANGES.get(param_key)
        if not ref:
            evaluated_results[display_name] = {
                "value": val,
                "unit": extracted_unit,
                "status": "Unknown",
                "message": "No reference range available"
            }
            continue

        total_params += 1
        status = "Normal"

        # Check critical first
        if val <= ref["critical_min"]:
            status = "CRITICAL LOW"
            health_score_points += 3
        elif val >= ref["critical_max"]:
            status = "CRITICAL HIGH"
            health_score_points += 3
        elif val < ref["min"]:
            status = "Low"
            health_score_points += 1
        elif val > ref["max"]:
            status = "High"
            health_score_points += 1

        evaluated_results[display_name] = {
            "value": val,
            "unit": extracted_unit if extracted_unit else ref["unit"],
            "status": status,
            "reference_range": f"{ref['min']} - {ref['max']} {ref['unit']}"
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
