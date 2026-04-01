import os
import ollama as ollama_client
from dotenv import load_dotenv
from typing import Dict, Any

load_dotenv()

OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2:1b")

def generate_report_summary(evaluated_data: Dict[str, Any]) -> str:
    """
    Generates a patient-friendly summary of their lab report using Ollama directly.
    """
    # Format the data nicely for the prompt
    details = evaluated_data.get("details", {})
    formatted_data = ""
    for param, info in details.items():
        formatted_data += f"- {param}: {info.get('value')} {info.get('unit')} (Status: {info.get('status')})\n"

    prompt = (
        "You are a helpful and empathetic AI doctor's assistant analyzing a medical lab report. "
        "Based on the following extracted parameters and risk level, provide a very concise, "
        "easy-to-understand summary for the patient (max 4-5 sentences).\n\n"
        f"Overall Health Risk: {evaluated_data.get('overall_health_risk', 'Unknown')}\n"
        f"Lab Parameters:\n{formatted_data}\n\n"
        "Highlight any 'CRITICAL' or 'High/Low' values in simple terms. "
        "Always add a disclaimer to consult a real doctor."
    )

    try:
        response = ollama_client.chat(
            model=OLLAMA_MODEL,
            messages=[{"role": "user", "content": prompt}]
        )
        return response["message"]["content"].strip()
    except Exception as e:
        print(f"LLM Generation Error: {e}")
        return "Error generating summary. Make sure Ollama is running with the llama3.2:1b model."
