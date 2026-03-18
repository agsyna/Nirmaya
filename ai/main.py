from fastapi import FastAPI, UploadFile, File, Form, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = FastAPI(
    title="Nirmaya AI Engine",
    description="Backend AI Services for Nirmaya Health Locker",
    version="1.0.0"
)

# Configure CORS for Flutter app communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with Flutter App domain/IP
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Nirmaya AI Engine is running"}

@app.post("/analyze")
async def analyze_report(
    file: UploadFile = File(...),
    patient_id: str = Form(...),
    report_type: str = Form("lab_report") # 'lab_report' or 'prescription'
):
    """
    Main endpoint for the Flutter app to upload a report.
    Pipeline: OCR -> NLP Extraction -> ML Risk Eval -> LLM Summary -> Save to DB
    """
    # Placeholder for the actual pipeline
    return {
        "status": "success",
        "message": f"Received {report_type} for patient {patient_id}. Processing pipeline is under construction.",
        "filename": file.filename
    }

@app.post("/chat")
async def chat_with_report(
    patient_id: str = Form(...),
    question: str = Form(...)
):
    """
    Endpoint for the patient or doctor to ask questions about the report (RAG).
    Pipeline: Embed Question -> Search ChromaDB -> Pass Context to Llama3 -> Return Answer
    """
    # Placeholder for RAG
    return {
        "status": "success",
        "answer": f"You asked about patient {patient_id}. RAG pipeline is under construction."
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
