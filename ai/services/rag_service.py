import os
import chromadb
import ollama as ollama_client
from dotenv import load_dotenv

load_dotenv()

OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2:1b")
CHROMA_DB_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "chromadb")

# Ensure directory exists
os.makedirs(CHROMA_DB_DIR, exist_ok=True)

# Initialize ChromaDB with persistent storage
try:
    chroma_client = chromadb.PersistentClient(path=CHROMA_DB_DIR)
    collection = chroma_client.get_or_create_collection(name="nirmaya_reports")
except Exception as e:
    print(f"Failed to initialize ChromaDB: {e}")
    chroma_client = None
    collection = None

def _chunk_text(text: str, chunk_size: int = 500, overlap: int = 50):
    """Split text into overlapping chunks."""
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks

def index_report(report_id: str, text: str) -> bool:
    """
    Splits the extracted OCR text into chunks and stores them in ChromaDB.
    """
    if not collection:
        return False

    try:
        chunks = _chunk_text(text)
        ids = [f"{report_id}_{i}" for i in range(len(chunks))]
        metadatas = [{"report_id": report_id}] * len(chunks)

        collection.add(
            documents=chunks,
            ids=ids,
            metadatas=metadatas
        )
        return True
    except Exception as e:
        print(f"Error indexing report {report_id}: {e}")
        return False

def query_report(report_id: str, question: str) -> str:
    """
    Takes a user question, searches ChromaDB for relevant chunks,
    and uses Ollama LLM to answer.
    """
    if not collection:
        return "Chat service is unavailable. ChromaDB not initialized."

    try:
        # 1. Search for relevant chunks from this specific report
        results = collection.query(
            query_texts=[question],
            n_results=3,
            where={"report_id": report_id}
        )

        documents = results.get("documents", [[]])[0]
        if not documents:
            return "I couldn't find any relevant information in that report."

        context = "\n".join(documents)

        # 2. Ask the LLM using the retrieved context
        prompt = (
            f"You are a helpful medical assistant. Based ONLY on the following medical report text, "
            f"answer the patient's question clearly and concisely.\n\n"
            f"--- REPORT TEXT ---\n{context}\n--- END ---\n\n"
            f"Patient's Question: {question}\n\n"
            f"Answer:"
        )

        response = ollama_client.chat(
            model=OLLAMA_MODEL,
            messages=[{"role": "user", "content": prompt}]
        )
        return response["message"]["content"].strip()

    except Exception as e:
        print(f"RAG query error for {report_id}: {e}")
        return "An error occurred while answering your question."
