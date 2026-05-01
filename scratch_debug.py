import sys
import json
from ai.services.nlp_service import extract_lab_parameters
from ai.services.evaluation_service import evaluate_parameters

with open('full_text.txt', 'r', encoding='utf-8') as f:
    text = f.read()

from ai.services.nlp_service import _fuzzy_match_test_name

print("Cholesterol - HDL:", _fuzzy_match_test_name("Cholesterol - HDL"))
print("Red blood cell:", _fuzzy_match_test_name("Red blood cell"))
print("Platelet Count:", _fuzzy_match_test_name("Platelet Count"))
print("PDW:", _fuzzy_match_test_name("PDW"))
