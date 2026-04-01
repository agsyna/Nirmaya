import pytesseract
from PIL import Image, ImageFilter, ImageEnhance
import fitz  # PyMuPDF
import os
from dotenv import load_dotenv
import io

load_dotenv()

# Configure Tesseract path for Windows
_default_path = os.path.join("C:", os.sep, "Program Files", "Tesseract-OCR", "tesseract.exe")
TESSERACT_CMD = os.getenv("TESSERACT_CMD", _default_path)
if not os.path.isfile(TESSERACT_CMD):
    TESSERACT_CMD = _default_path
pytesseract.pytesseract.tesseract_cmd = TESSERACT_CMD
print(f"Tesseract configured at: {TESSERACT_CMD}")


def _preprocess_image(image: Image.Image) -> Image.Image:
    """
    Preprocess image to dramatically improve OCR accuracy.
    Steps: Resize -> Grayscale -> Contrast boost -> Sharpen -> Binarize
    """
    # 1. Upscale small images (Tesseract works best at 300+ DPI)
    width, height = image.size
    if width < 2000:
        scale = 2000 / width
        image = image.resize((int(width * scale), int(height * scale)), Image.LANCZOS)
    
    # 2. Convert to grayscale
    image = image.convert("L")
    
    # 3. Boost contrast
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(2.0)
    
    # 4. Sharpen
    image = image.filter(ImageFilter.SHARPEN)
    
    # 5. Binarize (convert to pure black & white)
    threshold = 150
    image = image.point(lambda p: 255 if p > threshold else 0)
    
    return image


def extract_text_from_image(image_bytes: bytes) -> str:
    """
    Extracts raw text from an image file (JPG, PNG) using Tesseract OCR
    with image preprocessing for better accuracy.
    """
    try:
        image = Image.open(io.BytesIO(image_bytes))
        
        # Preprocess for better OCR
        processed = _preprocess_image(image)
        
        # Use Tesseract with optimized config for structured documents
        custom_config = r'--oem 3 --psm 6'
        text = pytesseract.image_to_string(processed, config=custom_config)
        return text
    except Exception as e:
        print(f"OCR Error: {e}")
        return ""


def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    """
    Extracts text from a PDF. Tries direct text extraction first,
    falls back to OCR with preprocessing for scanned PDFs.
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
                # 2. Scanned PDF: extract as image, preprocess, then OCR
                pix = page.get_pixmap(dpi=300)  # Higher DPI for better quality
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                processed = _preprocess_image(img)
                
                custom_config = r'--oem 3 --psm 6'
                ocr_text = pytesseract.image_to_string(processed, config=custom_config)
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
