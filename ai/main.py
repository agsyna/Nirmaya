from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
import uuid
from dotenv import load_dotenv

# Import our custom AI services
from services.ocr_service import process_document
from services.nlp_service import analyze_parsed_text
from services.evaluation_service import evaluate_parameters
from services.llm_service import generate_report_summary
from services.rag_service import index_report, query_report

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
    Pipeline: OCR -> NLP Extraction -> ML Risk Eval -> LLM Summary -> Save to VectorDB
    """
    try:
        # Read file bytes
        file_bytes = await file.read()
        
        # 1. OCR Stage
        raw_text = process_document(file_bytes, file.filename)
        if not raw_text.strip():
            raise HTTPException(status_code=400, detail="Could not extract text from document.")
            
        # 2. NLP Information Extraction
        extracted_data = analyze_parsed_text(raw_text, report_type)
        
        # Initialize final return dict
        report_id = str(uuid.uuid4())
        response_data = {
            "status": "success",
            "patient_id": patient_id,
            "report_type": report_type,
            "report_id": report_id,
            "raw_text": raw_text  # Include for debugging / Flutter display
        }
        
        # 3. Evaluation & Summarization (if it's a lab report)
        if report_type == "lab_report":
            evaluated_data = evaluate_parameters(extracted_data.get("parameters", {}))
            summary = generate_report_summary(evaluated_data)
            
            response_data["extracted_data"] = evaluated_data
            response_data["summary"] = summary
        else:
            # Prescription
            response_data["extracted_data"] = extracted_data
            response_data["summary"] = "Prescription successfully parsed."
            
        # 4. RAG Indexing for "Chat with Report" feature
        index_status = index_report(response_data["report_id"], raw_text)
        response_data["rag_indexed"] = index_status
        
        # (Optional Future Step): Save JSON response_data to Supabase DB here!
        
        return response_data
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat")
async def chat_with_report(
    report_id: str = Form(...),
    question: str = Form(...)
):
    """
    Endpoint for the patient or doctor to ask questions about the report (RAG).
    Pipeline: Embed Question -> Search ChromaDB -> Pass Context to Llama3 -> Return Answer
    """
    try:
        answer = query_report(report_id, question)
        return {
            "status": "success",
            "report_id": report_id,
            "answer": answer
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
