import pytesseract
from PIL import Image
import fitz  # PyMuPDF
import os
from dotenv import load_dotenv
import io

load_dotenv()

# Configure Tesseract path for Windows
_default_path = os.path.join("C:", os.sep, "Program Files", "Tesseract-OCR", "tesseract.exe")
TESSERACT_CMD = os.getenv("TESSERACT_CMD", _default_path)
# Verify file exists, fallback to default if env var was mangled
if not os.path.isfile(TESSERACT_CMD):
    TESSERACT_CMD = _default_path
pytesseract.pytesseract.tesseract_cmd = TESSERACT_CMD
print(f"Tesseract configured at: {TESSERACT_CMD}")

def extract_text_from_image(image_bytes: bytes) -> str:
    """
    Extracts raw text from an image file (JPG, PNG) using Tesseract OCR.
    """
    try:
        image = Image.open(io.BytesIO(image_bytes))
        text = pytesseract.image_to_string(image)
        return text
    except Exception as e:
        print(f"OCR Error: {e}")
        return ""

def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    """
    Extracts text from a PDF. It tries direct extraction first, 
    and if it's a scanned PDF, it converts pages to images and runs OCR.
    """
    try:
        doc = fitz.open("pdf", pdf_bytes)
        full_text = ""
        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            
            # 1. Try direct text extraction (works for digital PDFs)
            page_text = page.get_text("text").strip()
            
            if page_text:
                full_text += page_text + "\n"
            else:
                # 2. If no text (Scanned PDF), extract images and run OCR
                pix = page.get_pixmap()
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                ocr_text = pytesseract.image_to_string(img)
                full_text += ocr_text + "\n"
                
        return full_text
    except Exception as e:
        print(f"PDF OCR Error: {e}")
        return ""

def process_document(file_bytes: bytes, filename: str) -> str:
    """
    Determines file type and routes to the correct OCR function.
    """
    if filename.lower().endswith('.pdf'):
        return extract_text_from_pdf(file_bytes)
    else:
        return extract_text_from_image(file_bytes)
