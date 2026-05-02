# Nirmaya AI Engine

FastAPI backend for Nirmaya Health Locker providing:
- Document analysis (OCR, NLP, ML evaluation)
- Medical report chat with RAG
- LLM summaries using Ollama

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run
uvicorn main:app --reload --port 8000
```

## API Endpoints

- `POST /analyze` - Upload and analyze medical reports
- `POST /chat` - Ask questions about indexed reports

