from typing import Dict, Any

# A simplistic database of reference ranges (Male/Female/General could be expanded later)
REFERENCE_RANGES = {
    "Hemoglobin": {
        "unit": "g/dL",
        "min": 12.0,
        "max": 17.5,
        "critical_min": 7.0,
        "critical_max": 20.0
    },
    "Glucose": { # Fasting example
        "unit": "mg/dL",
        "min": 70.0,
        "max": 100.0,
        "critical_min": 50.0,
        "critical_max": 400.0
    },
    "Cholesterol": {
        "unit": "mg/dL",
        "min": 0,
        "max": 199.9,
        "critical_min": 0,
        "critical_max": 240.0
    },
    "WBC": {
        "unit": "cells/mcL", # or thousands/uL
        "min": 4.5,
        "max": 11.0,
        "critical_min": 2.0,
        "critical_max": 30.0
    }
}

def evaluate_parameters(parameters: Dict[str, Dict[str, str]]) -> Dict[str, Any]:
    """
    Compares extracted parameters against standard reference ranges.
    Flags each as Normal, High, Low, or Critical.
    """
    evaluated_results = {}
    health_score_points = 0 # Simple heuristic for now until ML model is trained
    
    for param, data in parameters.items():
        val_str = data.get("value", "")
        extracted_unit = data.get("unit", "")
        
        try:
            val = float(val_str)
        except ValueError:
            # Cannot parse as float
            evaluated_results[param] = {"value": val_str, "status": "Unknown", "message": "Could not parse value"}
            continue
            
        ref = REFERENCE_RANGES.get(param)
        if not ref:
            evaluated_results[param] = {"value": val, "status": "Unknown", "message": "No reference range found"}
            continue
            
        status = "Normal"
        
        # Check critical first
        if "critical_min" in ref and val <= ref["critical_min"]:
            status = "CRITICAL LOW"
            health_score_points += 3
        elif "critical_max" in ref and val >= ref["critical_max"]:
            status = "CRITICAL HIGH"
            health_score_points += 3
        # Check high/low
        elif val < ref["min"]:
            status = "Low"
            health_score_points += 1
        elif val > ref["max"]:
            status = "High"
            health_score_points += 1
            
        evaluated_results[param] = {
            "value": val,
            "unit": extracted_unit if extracted_unit else ref["unit"],
            "status": status,
            "reference_range": f"{ref['min']} - {ref['max']} {ref['unit']}"
        }
        
    # Placeholder for ML Risk Classification Model prediction
    # model.predict(extracted_features) -> overall risk
    overall_risk = "Low Risk"
    if health_score_points >= 3:
        overall_risk = "High Risk (Requires immediate doctor consultation)"
    elif health_score_points > 0:
        overall_risk = "Medium Risk (Monitor)"
        
    return {
        "details": evaluated_results,
        "overall_health_risk": overall_risk,
        "ml_model_used": "Heuristic (Pending XGBoost implementation)"
    }
