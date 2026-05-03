# Nirmaya: Health Locker & Emergency Response System
## Complete System Documentation

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [System Architecture](#system-architecture)
3. [Backend API (AI Engine)](#backend-api-ai-engine)
4. [Frontend Application (Flutter)](#frontend-application-flutter)
5. [Data Flow & Integration](#data-flow--integration)
6. [Core Features](#core-features)
7. [Tech Stack](#tech-stack)
8. [Setup & Installation](#setup--installation)
9. [API Endpoints Reference](#api-endpoints-reference)
10. [Database Schema Overview](#database-schema-overview)

---

## Project Overview

**Nirmaya** is a comprehensive health locker and emergency response system that enables users to:
- **Digitize & Organize** medical records (lab reports, prescriptions, health data)
- **Analyze Medical Reports** using OCR and AI/ML models
- **Chat with Reports** using RAG (Retrieval-Augmented Generation) and LLMs
- **Share Access** with healthcare providers (doctors, nurses)
- **Emergency SOS** triggering with real-time ambulance coordination
- **Track Health Metrics** and critical vitals
- **Manage Nominees** and emergency contacts
- **Monitor Medications** with reminders and tracking

### Who Uses It?
- **Patients**: Store and manage their complete health records
- **Doctors**: Access patient records with proper permissions
- **Emergency Responders**: Get immediate access to critical health data during emergencies
- **Nominees/Caregivers**: Monitor patient health and emergency events

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                          │
│  (Android/iOS - Patient Portal, Doctor Portal)                 │
│                                                                 │
│  ├── Authentication (Login/Register/Profile)                   │
│  ├── Health Records Management (Upload, View, Share)           │
│  ├── Report Analysis & Chat Interface                          │
│  ├── Emergency SOS System                                       │
│  ├── Medication Tracking                                        │
│  └── Nominee Management                                         │
└────────────────────────────────┬────────────────────────────────┘
                                 │ (HTTP/REST)
                                 │
┌────────────────────────────────▼────────────────────────────────┐
│           FastAPI Backend (Nirmaya AI Engine)                   │
│  Port: 8000                                                     │
│                                                                 │
│  ├── Authentication Service                                    │
│  ├── OCR Service (Tesseract + PyMuPDF)                         │
│  ├── NLP Service (spaCy - Medical Entity Recognition)          │
│  ├── Evaluation Service (ML Risk Assessment - XGBoost)         │
│  ├── LLM Service (Ollama - Report Summarization)               │
│  ├── RAG Service (ChromaDB - Semantic Search + Chat)           │
│  └── File Storage & Management                                 │
└────────────────────────────┬───────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
   ┌─────────┐          ┌─────────┐         ┌─────────┐
   │Supabase │          │ChromaDB │         │File     │
   │(Auth &  │          │(Vector  │         │Storage  │
   │Database)│          │Search)  │         │(S3/etc) │
   └─────────┘          └─────────┘         └─────────┘
```

---

## Backend API (AI Engine)

### Location: `/ai/`

The backend is a **FastAPI application** that handles all AI/ML processing, document analysis, and data management.

### Core Services

#### 1. **OCR Service** (`services/ocr_service.py`)
**Purpose**: Extract text from medical documents (PDFs, images)

**Technology Stack**:
- **Tesseract OCR**: Character recognition from images
- **PyMuPDF (fitz)**: PDF parsing and rendering
- **Pillow (PIL)**: Image preprocessing

**Process Pipeline**:
```
Document (PDF/Image)
    ↓
[PDF Detection]
    ├─ Digital PDF? → Direct text extraction
    └─ Scanned PDF? → Convert to image → Preprocess → OCR
[Image Processing]
    ├─ Upscale (if needed)
    ├─ Convert to Grayscale
    ├─ Boost Contrast
    ├─ Sharpen
    └─ Binarize (B&W conversion)
[Tesseract OCR] → Raw extracted text
```

**Key Functions**:
- `extract_text_from_image()`: OCR for image files
- `extract_text_from_pdf()`: Handles both digital and scanned PDFs
- `_preprocess_image()`: Improves OCR accuracy through preprocessing
- `process_document()`: Main entry point determining document type

---

#### 2. **NLP Service** (`services/nlp_service.py`)
**Purpose**: Extract medical entities and structured data from raw OCR text

**Technology Stack**:
- **spaCy**: NLP entity recognition and linguistic processing
- **rapidfuzz**: Fuzzy string matching for lab test names

**Process Pipeline**:
```
Raw OCR Text
    ↓
[Medical Entity Recognition]
    ├─ Lab Test Identification (CBC, Lipid Profile, etc.)
    ├─ Value Extraction (hemoglobin: 14.5 g/dL)
    ├─ Unit Detection (mg/dL, g/dL, mmol/L, etc.)
    └─ Reference Range Parsing (Normal: 12-16)
[Structured Data Organization]
    └─ JSON Output with categorized parameters
```

**Lab Test Categories Recognized**:
- **CBC** (Complete Blood Count): Hemoglobin, RBC, WBC, Platelet, etc.
- **Blood Sugar**: Fasting glucose, PP glucose, HbA1c
- **Lipid Profile**: Cholesterol, Triglycerides, HDL, LDL, VLDL
- **Kidney Function**: Creatinine, Urea, Uric acid
- **Liver Function**: Bilirubin, SGOT, SGPT, ALP, GGT
- **Thyroid**: TSH, T3, T4, Free T3, Free T4
- **Others**: Calcium, Iron, Vitamin D, B12, ESR, CRP, Electrolytes

**Output Format**:
```json
{
  "parameters": {
    "hemoglobin": {
      "value": 14.5,
      "unit": "g/dL",
      "reference_range": "12-16",
      "status": "normal"
    },
    ...
  },
  "report_type": "lab_report"
}
```

---

#### 3. **Evaluation Service** (`services/evaluation_service.py`)
**Purpose**: Assess health risks based on lab parameters

**Technology Stack**:
- **XGBoost**: Machine learning model for risk assessment
- **scikit-learn**: Data preprocessing and metrics
- **pandas**: Data manipulation

**Risk Assessment Logic**:
- Compares extracted values against normal ranges
- Identifies abnormal findings
- Generates risk flags and severity levels
- Uses ML models to predict health conditions

**Output**: Risk scores, severity classifications, and clinical recommendations

---

#### 4. **LLM Service** (`services/llm_service.py`)
**Purpose**: Generate natural language summaries of medical reports

**Technology Stack**:
- **Ollama**: Local LLM inference engine
- **Llama 3.2**: Open-source language model

**Process**:
```
Evaluated Health Data
    ↓
[Prompt Engineering]
    ├─ Organize findings
    ├─ Highlight abnormalities
    └─ Format for LLM comprehension
    ↓
[Ollama LLM Inference] (Llama 3.2 1B)
    ↓
[Summary Generation]
    └─ Patient-friendly clinical summary
```

**Key Features**:
- Runs locally (privacy-first)
- Fast inference on CPU/GPU
- Customizable prompts for different report types
- Generates structured summaries with key findings

---

#### 5. **RAG Service** (`services/rag_service.py`)
**Purpose**: Enable "Chat with Report" feature using Retrieval-Augmented Generation

**Technology Stack**:
- **ChromaDB**: Vector database for semantic search
- **Ollama**: Embedding and LLM inference

**Process Pipeline**:
```
Report Text
    ↓
[Text Chunking] (500-char chunks with 50-char overlap)
    ↓
[Vector Embedding] (via Ollama)
    ↓
[ChromaDB Storage] (Persistent vector storage)
    
---

User Question
    ↓
[Question Embedding]
    ↓
[Semantic Search] (Find relevant chunks from ChromaDB)
    ↓
[Context Building] (Retrieve top 3 matching chunks)
    ↓
[LLM Prompt Engineering]
    ├─ System prompt: "You are a medical assistant"
    ├─ Context: Retrieved chunks
    └─ Query: User question
    ↓
[Ollama LLM Response]
    ↓
[Answer Delivery to User]
```

**Key Features**:
- Semantic understanding (not keyword matching)
- Contextual answers grounded in actual report data
- Prevents hallucinations by restricting to indexed documents
- Persistent storage (survives app restarts)

---

### Main API Endpoints

#### `POST /analyze`
**Purpose**: Upload and analyze a medical report

**Request**:
```
multipart/form-data:
  - file: (PDF or image file)
  - patient_id: (string)
  - report_type: (lab_report | prescription)
```

**Processing Pipeline**:
1. **OCR** → Extract text from document
2. **NLP** → Identify medical parameters and values
3. **Evaluation** → Assess health risks
4. **LLM** → Generate clinical summary
5. **RAG Indexing** → Store in vector DB for chat
6. **Return** → Structured JSON with all analysis

**Response**:
```json
{
  "status": "success",
  "patient_id": "abc123",
  "report_type": "lab_report",
  "report_id": "uuid",
  "raw_text": "Extracted OCR text...",
  "extracted_data": {
    "hemoglobin": {...},
    "blood_sugar": {...},
    ...
  },
  "summary": "Patient clinical summary...",
  "rag_indexed": true
}
```

---

#### `POST /chat`
**Purpose**: Ask questions about a previously analyzed report

**Request**:
```json
{
  "report_id": "uuid",
  "question": "What does my hemoglobin level mean?"
}
```

**Processing**:
1. Embed user question
2. Search ChromaDB for relevant report sections
3. Build context from top results
4. Send to Ollama LLM with context
5. Return answer

**Response**:
```json
{
  "status": "success",
  "answer": "Your hemoglobin level of 14.5 g/dL is...",
  "sources": ["chunk_1", "chunk_2", ...]
}
```

---

### Configuration

**Environment Variables** (`.env`):
```
OLLAMA_MODEL=llama3.2:1b
TESSERACT_CMD=/path/to/tesseract.exe
SUPABASE_URL=...
SUPABASE_KEY=...
```

**Dependencies** (`requirements.txt`):
```
fastapi              # Web framework
uvicorn              # ASGI server
python-multipart     # File upload handling
supabase             # Database client
pytesseract          # OCR wrapper
spacy                # NLP
chromadb             # Vector database
ollama               # LLM inference
python-dotenv        # Environment management
pandas               # Data processing
xgboost              # ML evaluation
scikit-learn         # ML utilities
pymupdf              # PDF processing
Pillow               # Image processing
rapidfuzz            # Fuzzy matching
```

---

## Frontend Application (Flutter)

### Location: `/app/`

A comprehensive **Flutter mobile application** providing patient and doctor interfaces for accessing and managing health records.

### Project Structure

```
lib/
├── main.dart                    # App entry point & Provider setup
├── app/
│   ├── models/                  # Data models (User, Report, Emergency, etc.)
│   ├── providers/               # State management (ChangeNotifier)
│   ├── services/                # API communication & business logic
│   ├── views/                   # Screens/Pages
│   └── widgets/                 # Reusable UI components
├── modules/
│   └── doctor/                  # Doctor-specific screens and logic
├── core/
│   ├── constants/               # Colors, themes, app configuration
│   └── services/                # Global services (Storage, Notifications, API)
└── test/                        # Test files
```

### State Management Architecture

**Pattern**: Provider + ChangeNotifier (MVVM-like)

**Providers** (`lib/app/providers/`):
1. **AuthProvider** - Authentication & user session
2. **HomeViewModel** - Home screen state
3. **ReportProvider** - Report list & upload management
4. **EmergencyViewModel** - Emergency SOS triggering & history
5. **MedicationProvider** - Medication tracking
6. **AccessViewModel** - Access control & sharing
7. **ShareViewModel** - Share management
8. **NomineeProvider** - Nominee/emergency contact management
9. **DoctorProvider** - Doctor-specific operations

**Example Provider Pattern**:
```dart
class ReportProvider extends ChangeNotifier {
  List<Report> _reports = [];
  bool _isLoading = false;
  
  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();
    try {
      _reports = await _reportService.getReports();
    } catch(e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
  
  Future<bool> uploadReport(File file) async {
    // Upload logic...
  }
}
```

### Key Features

#### 1. **Authentication** (`AuthProvider`)
- **Registration**: Patient creates account with profile data
- **Login**: Email/password authentication
- **Profile Management**: Update health profile info
- **Secure Storage**: JWT tokens stored in `FlutterSecureStorage`

**Related Models**:
```dart
class User {
  String id;
  String name;
  String email;
  String? phone;
  int? age;
  String? gender;
  String? bloodGroup;
  double? height;
  double? weight;
  DateTime createdAt;
  DateTime? updatedAt;
}
```

---

#### 2. **Health Records Management** (`ReportProvider`)
- **Upload Reports**: Add medical documents (PDFs, images)
- **View Reports**: Browse past medical records
- **Report Details**: Full analysis with OCR results, extracted parameters, AI summary
- **Pagination**: Infinite scroll loading
- **Filtering**: Filter by type (lab report, prescription)

**Report Model**:
```dart
class Report {
  String id;
  String title;
  String type;           // 'lab_report' or 'prescription'
  String fileUrl;
  DateTime documentDate;
  DateTime uploadedAt;
  
  // AI Analysis Results
  String? rawOcrText;
  Map<String, dynamic>? extractedData;
  String? aiSummary;
  
  // Sharing
  String privacy;        // 'private' or 'shared'
  List<String>? sharedWith;
}
```

**Screen**: [ReportDetailScreen](emergency_detail_screen.dart) (reference: Shows detailed display pattern)

---

#### 3. **Report Analysis & Chat** 
- **OCR Results**: View extracted text from documents
- **Parameter Extraction**: Display identified medical parameters with values
- **Chat Interface**: Ask questions about reports
- **RAG-Powered Answers**: Contextual responses from AI

**Chat Flow**:
```
User Types Question
    ↓
[Question Sent to AI Engine /chat endpoint]
    ↓
[Backend performs RAG search in ChromaDB]
    ↓
[LLM generates answer with context]
    ↓
[Answer displayed in chat bubble]
    ↓
[User can continue conversation]
```

**Screen**: `ChatWithReportScreen`

---

#### 4. **Emergency SOS System** (`EmergencyViewModel`)
**Purpose**: Trigger emergency response with immediate location sharing and contact notification

**Emergency Workflow**:
```
Patient Taps "SOS" Button
    ↓
[Capture User Location] (using geolocator)
    ├─ Latitude & Longitude
    └─ Accuracy check
    ↓
[Trigger Emergency API Call]
    ├─ Post emergency data to backend
    └─ Get ambulance ETA
    ↓
[Share Location & Health Data]
    ├─ Auto-share health summary
    ├─ Notify nominees
    ├─ Alert emergency services
    └─ Share critical info
    ↓
[Real-time Updates]
    ├─ Ambulance ETA tracking
    ├─ Emergency status
    └─ Contact notifications
```

**Emergency Model**:
```dart
class Emergency {
  String sosId;
  String affectedPatientId;
  String status;             // 'active', 'resolved', 'in_transit'
  
  // Location
  double latitude;
  double longitude;
  
  // Service
  List<String> serviceTypes; // 'ambulance', 'police', 'fire'
  String description;
  
  // Medical Data
  AffectedPatientProfile? affectedPatientProfile;
  LatestHealthData? latestHealthData;
  CriticalInfoShared? criticalInfoShared;
  
  // Contacts
  List<Nominee> nominees;
  
  // Tracking
  int? ambulanceEta;
  DateTime createdAt;
  DateTime? resolvedAt;
}

class CriticalInfoShared {
  List<Nominee> nominees;
  List<Allergy> allergies;
  List<ChronicCondition> chronicConditions;
}
```

**Screen**: [EmergencyDetailScreen](emergency_detail_screen.dart) (Reference file)
- **Status Card**: Current emergency status
- **Patient Profile**: Age, blood group, gender, height, weight
- **Health Data**: Latest vitals
- **Critical Info**: Allergies & chronic conditions
- **Shared Contacts**: Nominees with contact info
- **Location**: GPS coordinates
- **Action Button**: "Inform Contacts" - Send SMS to all nominees

---

#### 5. **Medication Tracking** (`MedicationProvider`)
- **Add Medications**: Create medication records with dosage/schedule
- **Reminders**: Local notifications for medication times
- **Track Adherence**: Log when medications taken
- **Management**: Edit/delete medications

**Medication Model**:
```dart
class Medication {
  String id;
  String name;
  String dosage;
  String frequency;        // 'daily', 'weekly', etc.
  List<String> times;      // ['08:00', '20:00']
  DateTime? startDate;
  DateTime? endDate;
  String? reason;
  String? notes;
  List<DateTime>? reminderTimes;
  bool remindersEnabled;
}
```

**Technology**: `flutter_local_notifications` for reminders

---

#### 6. **Access & Sharing** (`AccessViewModel`, `ShareViewModel`)
- **Share with Doctors**: Grant read access to specific reports
- **Access Management**: View who has access to your records
- **Revoke Access**: Withdraw sharing permissions
- **Audit Log**: Track who viewed what records

**Share Model**:
```dart
class Share {
  String id;
  String reportId;
  String sharedBy;
  String sharedWith;       // doctor_id
  List<String> permissions; // ['read']
  DateTime sharedAt;
  DateTime? revokedAt;
}
```

---

#### 7. **Nominee Management** (`NomineeProvider`)
- **Add Nominees**: Register emergency contacts
- **Emergency Sharing**: Nominees auto-share health data in emergencies
- **Contact Info**: Store phone, email, relationship
- **Manage**: Edit/delete nominees

**Nominee Model**:
```dart
class Nominee {
  String id;
  String name;
  String? email;
  String phone;
  String relationship;     // 'spouse', 'parent', 'friend', etc.
  int priority;
  bool receiveEmergencyNotifications;
  DateTime? invitedAt;
  DateTime? acceptedAt;
}
```

**Screen**: `NomineesScreen`

---

### Core Services

#### 1. **API Service** (`core/services/api_service.dart`)
Central HTTP client for all API communication
- Request/response interceptors
- Error handling
- JWT token injection
- Timeout management

```dart
class ApiService {
  late Dio _dio;
  
  Future<T> get<T>(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return T.fromJson(response.data);
    } catch(e) {
      handleError(e);
    }
  }
  
  Future<T> post<T>(String endpoint, dynamic data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return T.fromJson(response.data);
    } catch(e) {
      handleError(e);
    }
  }
}
```

---

#### 2. **Auth Service** (`app/services/auth_service.dart`)
- **Login/Register**: Communicate with authentication API
- **Token Management**: Store/retrieve JWT tokens
- **Session Persistence**: Remember login state

---

#### 3. **Report Service** (`app/services/report_service.dart`)
- **Upload**: Send files to backend for analysis
- **Fetch**: Load reports from database
- **Delete**: Remove reports
- **Share**: Grant access to doctors

**Upload Process**:
```dart
Future<Report> uploadReport(File file) async {
  // Create multipart request
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(file.path),
    'patient_id': currentUserId,
    'report_type': 'lab_report',
  });
  
  // Send to /analyze endpoint
  final response = await _dio.post('/analyze', data: formData);
  
  // Extract AI results
  return Report.fromJson(response.data);
}
```

---

#### 4. **Emergency Service** (`app/services/emergency_service.dart`)
- **Trigger SOS**: Create emergency record with location
- **Fetch History**: Load past emergencies
- **Update Status**: Track ambulance ETA
- **Notify Contacts**: Send SMS/notifications

---

#### 5. **AI Service** (`app/services/ai_service.dart`)
- **Chat Endpoint**: Send questions to RAG backend
- **Stream Responses**: Handle streaming answers
- **Manage Chat History**: Store conversation in local DB

---

#### 6. **Storage Service** (`core/services/storage_service.dart`)
- **Secure Storage**: Store sensitive data (JWT tokens)
- **Shared Preferences**: Store app settings and preferences
- **Local Database**: SQLite for offline data

```dart
class StorageService {
  final _secureStorage = FlutterSecureStorage();
  final _preferences = SharedPreferences;
  
  Future<void> saveToken(String token) =>
    _secureStorage.write(key: 'jwt_token', value: token);
    
  Future<String?> getToken() =>
    _secureStorage.read(key: 'jwt_token');
}
```

---

#### 7. **Notification Service** (`core/services/notification_service.dart`)
- **Local Notifications**: Medication reminders, emergency alerts
- **Permission Handling**: Request notification permissions
- **Channel Management**: Different notification types

---

### Main Screens

#### 1. **SplashScreen**
- App initialization
- Check user authentication status
- Navigate to login or home

#### 2. **LoginScreen & SignupScreen**
- User authentication
- Profile setup (health info)
- Medical history initialization

#### 3. **HomeScreen**
- Dashboard with health summary
- Quick actions (Upload Report, Emergency SOS, View Medications)
- Recent activities
- Nominee status

#### 4. **RecordsScreen**
- List all medical reports
- Search and filter
- Tap to view details
- Options to share/delete

#### 5. **ReportDetailScreen**
- Full report analysis
- OCR extracted text
- Medical parameters with values and ranges
- Patient profile info (age, blood group, gender)
- Health data (vital signs)
- Critical info (allergies, chronic conditions)
- Shared contacts
- Location map
- Chat button to ask questions

#### 6. **ChatWithReportScreen**
- Conversation interface
- Send questions about report
- AI-powered answers from RAG system
- Chat history persistence

#### 7. **MedicationsScreen**
- List all medications
- Add new medication
- View schedule
- Enable/disable reminders
- Mark as taken

#### 8. **EmergencyScreen**
- SOS trigger button
- Service type selection (ambulance, police, fire)
- Location capture
- Emergency description
- Quick access to contact nominees

#### 9. **EmergencyDetailScreen** (Reference: [emergency_detail_screen.dart](emergency_detail_screen.dart))
- View triggered emergency
- Current status
- ETA tracking
- Health data snapshot
- All shared contacts
- Option to inform contacts

#### 10. **NomineesScreen**
- List registered nominees
- Add new nominee
- Edit/delete nominees
- Manage permissions

#### 11. **AccessScreen**
- View access controls
- See who has access to records
- Revoke access
- Set granular permissions

#### 12. **DoctorPortal** (if doctor role)
- View granted access records
- Patient search
- Record analysis
- Generate reports

---

### UI/UX Components

#### Custom Widgets
- **CustomAppBar**: Consistent header across screens
- **CustomButton**: Styled buttons with loading state
- **EmergencyCard**: Display emergency status
- **HealthMetricCard**: Show vital parameters
- **ContactCard**: Display nominee/contact info
- **ReportCard**: Display report preview

#### Design System
- **AppColors**: Consistent color palette
- **AppTheme**: Material theme configuration
- **Google Fonts**: Poppins font family
- **Responsive Layout**: Works on various screen sizes

---

### Dependencies (pubspec.yaml)

**Core Framework**:
- `flutter`: Mobile SDK
- `provider`: State management

**Backend Communication**:
- `dio`: HTTP client
- `http`: Alternative HTTP client
- `supabase_flutter`: Backend-as-service
- `cloud_firestore`: Cloud database

**Storage & Security**:
- `shared_preferences`: App preferences
- `flutter_secure_storage`: Encrypted storage
- `sqflite`: Local SQLite database

**File & Media Handling**:
- `image_picker`: Select images from gallery/camera
- `file_picker`: Select any file type
- `path_provider`: File system paths

**Location & Sensors**:
- `geolocator`: GPS location
- `permission_handler`: Request permissions
- `speech_to_text`: Voice input

**Notifications & Timers**:
- `flutter_local_notifications`: Local alerts
- `timezone`: Time zone management

**UI & Styling**:
- `google_fonts`: Google Fonts library
- `smooth_page_indicator`: Page indicators
- `url_launcher`: Launch external URLs
- `qr_flutter`: Generate QR codes

**Scanning**:
- `mobile_scanner`: QR/barcode scanning

**Internationalization**:
- `intl`: Date/time formatting
- `cupertino_icons`: iOS icons

---

## Data Flow & Integration

### Complete User Journey: Uploading a Report

```
┌─── PATIENT APP ────────────────────────────────────────────────┐
│                                                                  │
│  1. Patient taps "Upload Report"                               │
│     ↓                                                           │
│  2. Select PDF/Image from device                               │
│     ↓                                                           │
│  3. Input title, type, document date                           │
│     ↓                                                           │
│  4. Tap "Upload" button                                        │
│                                                                  │
└──────────────┬──────────────────────────────────────────────────┘
               │ (HTTP multipart POST)
               │
┌──────────────▼──────────────────────────────────────────────────┐
│           FASTAPI BACKEND - /analyze endpoint                   │
│                                                                  │
│  1. Receive file bytes                                          │
│     ├─ Save temporarily                                        │
│     └─ Determine file type (PDF vs Image)                      │
│     ↓                                                           │
│  2. OCR Service                                                │
│     ├─ Extract text from PDF/Image                             │
│     ├─ Preprocess images (resize, enhance, binarize)           │
│     ├─ Run Tesseract OCR                                       │
│     └─ Return raw_text                                         │
│     ↓                                                           │
│  3. NLP Service                                                │
│     ├─ Parse raw_text                                          │
│     ├─ Identify lab test names (hemoglobin, glucose, etc.)    │
│     ├─ Extract values and units                                │
│     ├─ Match against 60+ medical test patterns                 │
│     └─ Return extracted_data JSON                              │
│     ↓                                                           │
│  4. Evaluation Service                                         │
│     ├─ Compare values vs normal ranges                         │
│     ├─ Flag abnormalities                                      │
│     ├─ Run ML models (XGBoost)                                 │
│     └─ Generate risk scores                                    │
│     ↓                                                           │
│  5. LLM Service                                                │
│     ├─ Format data for Ollama LLM                              │
│     ├─ Send prompt to Llama 3.2 model                          │
│     └─ Receive natural language summary                        │
│     ↓                                                           │
│  6. RAG Indexing                                               │
│     ├─ Chunk raw_text (500-char chunks)                        │
│     ├─ Generate embeddings                                     │
│     ├─ Store in ChromaDB                                       │
│     └─ Return rag_indexed: true                                │
│     ↓                                                           │
│  7. Prepare Response                                           │
│     {                                                          │
│       "status": "success",                                     │
│       "report_id": "uuid123",                                  │
│       "raw_text": "...",                                       │
│       "extracted_data": {...},                                 │
│       "summary": "...",                                        │
│       "rag_indexed": true                                      │
│     }                                                          │
│                                                                  │
└──────────────┬──────────────────────────────────────────────────┘
               │ (HTTP JSON response)
               │
┌──────────────▼──────────────────────────────────────────────────┐
│           PATIENT APP (Back in ReportProvider)                  │
│                                                                  │
│  1. Receive response                                           │
│     ↓                                                           │
│  2. Save report metadata to Supabase                           │
│     ├─ Report title, type, date                               │
│     ├─ AI analysis results                                    │
│     └─ Sharing status                                         │
│     ↓                                                           │
│  3. Show success message                                       │
│     ↓                                                           │
│  4. Navigate to ReportDetailScreen                            │
│     ├─ Display extracted parameters                            │
│     ├─ Show AI summary                                         │
│     ├─ Enable "Chat with Report"                              │
│     └─ Option to share with doctors                           │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

### Chat with Report Flow

```
┌─── PATIENT ASKS QUESTION ──────────────────────────────────────┐
│                                                                  │
│  Question: "What does my hemoglobin level mean?"               │
│                                                                  │
└──────────────┬──────────────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────────────┐
│           PATIENT APP (ChatWithReportScreen)                    │
│                                                                  │
│  1. User types question in text field                          │
│  2. Tap send button                                            │
│  3. Show loading indicator                                     │
│  4. HTTP POST to /chat endpoint with:                          │
│     {                                                          │
│       "report_id": "uuid123",                                  │
│       "question": "What does my hemoglobin level mean?"        │
│     }                                                          │
│                                                                  │
└──────────────┬──────────────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────────────┐
│           FASTAPI BACKEND - /chat endpoint                      │
│                                                                  │
│  1. Receive report_id and question                             │
│     ↓                                                           │
│  2. Generate Embedding for question                            │
│     ├─ Send question to Ollama                                 │
│     └─ Get vector representation                               │
│     ↓                                                           │
│  3. Query ChromaDB                                             │
│     ├─ Search for chunks similar to question                  │
│     ├─ Filter by report_id                                    │
│     ├─ Retrieve top 3 most relevant chunks                    │
│     └─ Extract context from chunks                            │
│     ↓                                                           │
│  4. Build LLM Prompt                                           │
│     {                                                          │
│       "system": "You are a medical assistant...",              │
│       "context": "From report: [chunks text]",                 │
│       "question": "What does my hemoglobin level mean?"        │
│     }                                                          │
│     ↓                                                           │
│  5. Call Ollama LLM (Llama 3.2)                                │
│     ├─ Use retrieved context                                   │
│     ├─ Generate response based on report content              │
│     └─ Prevent hallucination by constraining to context       │
│     ↓                                                           │
│  6. Return Response                                            │
│     {                                                          │
│       "answer": "Your hemoglobin level of 14.5 g/dL...",      │
│       "sources": ["chunk_1", "chunk_2"]                        │
│     }                                                          │
│                                                                  │
└──────────────┬──────────────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────────────┐
│           PATIENT APP (Display Answer)                          │
│                                                                  │
│  1. Receive answer from backend                                │
│  2. Display as chat bubble                                     │
│  3. Allow follow-up questions                                 │
│  4. Maintain conversation history                             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

### Emergency SOS Flow

```
┌─── PATIENT EMERGENCY ──────────────────────────────────────────┐
│                                                                  │
│  1. Patient taps "SOS" button                                  │
│  2. Confirm emergency (modal)                                  │
│  3. Select service type (ambulance, police, fire)              │
│  4. Enter emergency description                                │
│                                                                  │
└──────────────┬──────────────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────────────┐
│           PATIENT APP (EmergencyViewModel)                      │
│                                                                  │
│  1. Request GPS location (geolocator)                          │
│  2. Get latitude, longitude, accuracy                          │
│  3. Prepare emergency data:                                    │
│     {                                                          │
│       "affected_patient_id": "user123",                        │
│       "latitude": 40.7128,                                     │
│       "longitude": -74.0060,                                   │
│       "service_types": ["ambulance"],                          │
│       "description": "Chest pain, difficulty breathing"        │
│     }                                                          │
│  4. Fetch latest user health data                              │
│  5. HTTP POST to /emergency/trigger                            │
│                                                                  │
└──────────────┬──────────────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────────────┐
│           BACKEND - /emergency/trigger endpoint                 │
│                                                                  │
│  1. Validate patient identity                                  │
│  2. Create emergency record in database                        │
│     ├─ status: "active"                                       │
│     ├─ timestamp: now()                                       │
│     ├─ sos_id: generate UUID                                  │
│     └─ location data                                          │
│  3. Auto-share health data                                    │
│     ├─ Get patient's latest health metrics                    │
│     ├─ Get critical info (allergies, conditions)              │
│     ├─ Get nominee list                                       │
│     └─ Store snapshot in emergency record                     │
│  4. Query ambulance service API                                │
│     ├─ Get nearest ambulance                                  │
│     └─ Provide ETA                                            │
│  5. Send notifications                                        │
│     ├─ SMS to all nominees with location link                 │
│     ├─ Alert emergency services                               │
│     ├─ In-app notifications to sharing doctors                │
│     └─ Return emergency details                               │
│                                                                  │
└──────────────┬──────────────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────────────┐
│           PATIENT APP (EmergencyDetailScreen)                  │
│                                                                  │
│  1. Display emergency status "ACTIVE"                          │
│  2. Show current location on map                               │
│  3. Display ETA: "Ambulance arriving in 8 minutes"             │
│  4. Show shared contacts list                                  │
│  5. Display patient health snapshot                            │
│  6. Option to "Inform Contacts" (send SMS)                     │
│  7. Real-time updates                                          │
│     ├─ Poll backend for ETA updates                            │
│     ├─ Update status when resolved                             │
│     └─ Log to emergency history                                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

┌─── NOMINEES RECEIVE NOTIFICATION ─────────────────────────────┐
│                                                                  │
│  SMS: "EMERGENCY: [PatientName] needs help!                   │
│        Location: [Location Link]                              │
│        Blood Type: O+                                          │
│        Allergies: Penicillin                                   │
│        SOS ID: [ID]"                                           │
│                                                                  │
│  Doctor (if sharing enabled):                                 │
│  - In-app notification with emergency details                │
│  - Can view emergency page with full health data              │
│  - Access to all shared health records                        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Core Features

### 1. **Document Digitization & Analysis**
- Upload medical documents (PDF, JPG, PNG)
- Automatic text extraction via OCR
- Medical parameter identification
- Health risk assessment
- Clinical summaries via LLM
- All powered by local AI (privacy-first)

### 2. **Intelligent Chat Interface**
- Ask questions about medical reports
- Semantic search (not keyword-based)
- Context-aware answers from RAG system
- Prevents hallucinations by restricting to indexed documents
- Multi-turn conversation support

### 3. **Emergency Response System**
- One-tap SOS triggering
- Real-time location sharing
- Auto-contact notification to nominees
- Ambulance ETA tracking
- Critical health data auto-sharing
- Emergency response status updates

### 4. **Access Control & Sharing**
- Grant read access to doctors
- Granular permission management
- Revoke access anytime
- Audit trail of access
- One-time link sharing

### 5. **Health Tracking**
- Manual vital entry (BP, glucose, HR, temp, weight)
- Health history visualization
- Trend analysis
- Medication adherence tracking
- Appointment management

### 6. **Medication Management**
- Add/edit/delete medications
- Set dosage and frequency
- Local reminders via notifications
- Track medication adherence
- Medication history

### 7. **Nominee Management**
- Register emergency contacts
- Manage multiple nominees
- Set notification preferences
- Store relationship info
- Contact priority ranking

### 8. **Doctor Portal**
- View granted access records
- Patient search
- Record analysis and notes
- Secure messaging
- Prescription generation

---

## Tech Stack

### Backend (Python)
| Component | Technology | Purpose |
|-----------|-----------|---------|
| Framework | FastAPI | REST API with async support |
| Server | Uvicorn | ASGI application server |
| OCR | Tesseract + PyMuPDF | Document text extraction |
| NLP | spaCy | Medical entity recognition |
| ML | XGBoost | Health risk assessment |
| LLM | Ollama + Llama 3.2 | Natural language generation |
| Vector DB | ChromaDB | Semantic search & RAG |
| Database | Supabase (PostgreSQL) | Data persistence |
| File Upload | python-multipart | Form data handling |
| Data | pandas, numpy | Data manipulation |
| Utilities | python-dotenv | Environment config |

### Frontend (Dart)
| Component | Technology | Purpose |
|-----------|-----------|---------|
| Framework | Flutter | Cross-platform mobile |
| State Mgmt | Provider | Reactive state management |
| HTTP | Dio | API communication |
| Database | Supabase Flutter | Backend services |
| Local DB | sqflite | Offline data storage |
| Auth | JWT + Secure Storage | Authentication & tokens |
| Location | geolocator | GPS coordinates |
| Notifications | flutter_local_notifications | Reminders & alerts |
| File Picking | file_picker, image_picker | File selection |
| QR Scanning | mobile_scanner | QR code reading |
| Fonts | google_fonts | Typography |

### Infrastructure
- **Cloud**: Supabase (Authentication + PostgreSQL database)
- **Backend Hosting**: Can run locally or cloud (AWS EC2, DigitalOcean, etc.)
- **Local AI**: Ollama (runs locally on backend server)
- **Storage**: Local or S3-compatible (for documents)

---

## Setup & Installation

### Backend Setup

#### 1. **Install Python Dependencies**
```bash
cd ai/
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### 2. **Install System Dependencies**
**Tesseract OCR**:
- **Windows**: Download installer from [Tesseract GitHub](https://github.com/UB-Mannheim/tesseract/wiki)
- **macOS**: `brew install tesseract`
- **Linux**: `sudo apt-get install tesseract-ocr`

**Ollama**:
- Download from [ollama.ai](https://ollama.ai)
- Install and start Ollama service
- Pull the model: `ollama pull llama3.2:1b`

**spaCy Model**:
```bash
python -m spacy download en_core_web_sm
```

#### 3. **Environment Configuration**
Create `.env` file:
```
OLLAMA_MODEL=llama3.2:1b
TESSERACT_CMD=/path/to/tesseract.exe  # Windows path
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
```

#### 4. **Start Backend Server**
```bash
uvicorn main:app --reload --port 8000
```
Server runs at: `http://localhost:8000`
API Docs: `http://localhost:8000/docs`

---

### Frontend Setup

#### 1. **Install Flutter Dependencies**
```bash
cd app/
flutter pub get
```

#### 2. **Install Required SDKs**
- **Android SDK**: Min API 21 (Android 5.0)
- **iOS SDK**: iOS 12.0+
- **macOS/Windows**: Required for development

#### 3. **Configure Supabase**
Update in `main.dart`:
```dart
await Supabase.initialize(
  url: 'your_supabase_url',
  anonKey: 'your_supabase_anon_key',
);
```

#### 4. **Update Backend URL**
In `core/services/api_service.dart`:
```dart
final String baseUrl = 'http://192.168.x.x:8000';  // Backend server IP
```

#### 5. **Run Application**
```bash
flutter run
```

---

## API Endpoints Reference

### Health Check
```
GET /
Response: { "status": "ok", "message": "Nirmaya AI Engine is running" }
```

### Report Analysis
```
POST /analyze
Content-Type: multipart/form-data

Form Fields:
  - file: (binary file)
  - patient_id: (string)
  - report_type: "lab_report" | "prescription"

Response:
{
  "status": "success",
  "patient_id": "abc123",
  "report_type": "lab_report",
  "report_id": "uuid",
  "raw_text": "Extracted text...",
  "extracted_data": { ... },
  "summary": "Clinical summary...",
  "rag_indexed": true
}
```

### Chat with Report
```
POST /chat
Content-Type: application/x-www-form-urlencoded

Form Fields:
  - report_id: (string)
  - question: (string)

Response:
{
  "status": "success",
  "answer": "Answer text...",
  "sources": ["chunk_1", "chunk_2"]
}
```

---

## Database Schema Overview

### Core Tables (Supabase PostgreSQL)

#### `users` Table
```sql
id (UUID, PK)
email (VARCHAR)
name (VARCHAR)
phone (VARCHAR)
age (INT)
gender (VARCHAR)
blood_group (VARCHAR)
height (FLOAT)
weight (FLOAT)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

#### `reports` Table
```sql
id (UUID, PK)
user_id (UUID, FK → users)
title (VARCHAR)
type (VARCHAR) -- 'lab_report', 'prescription'
file_url (VARCHAR)
document_date (DATE)
uploaded_at (TIMESTAMP)
raw_text (TEXT) -- OCR extracted text
extracted_data (JSONB) -- Parsed medical parameters
summary (TEXT) -- AI-generated summary
privacy (VARCHAR) -- 'private', 'shared'
created_at (TIMESTAMP)
```

#### `emergencies` Table
```sql
id (UUID, PK)
sos_id (VARCHAR, UNIQUE)
patient_id (UUID, FK → users)
status (VARCHAR) -- 'active', 'resolved', 'in_transit'
latitude (FLOAT)
longitude (FLOAT)
service_types (VARCHAR[]) -- ['ambulance', 'police', 'fire']
description (TEXT)
ambulance_eta (INT) -- minutes
nominees (JSONB) -- Auto-shared nominees
health_snapshot (JSONB) -- Latest vitals + critical info
created_at (TIMESTAMP)
resolved_at (TIMESTAMP)
```

#### `nominees` Table
```sql
id (UUID, PK)
patient_id (UUID, FK → users)
name (VARCHAR)
email (VARCHAR)
phone (VARCHAR)
relationship (VARCHAR)
priority (INT)
receive_notifications (BOOLEAN)
created_at (TIMESTAMP)
```

#### `medications` Table
```sql
id (UUID, PK)
patient_id (UUID, FK → users)
name (VARCHAR)
dosage (VARCHAR)
frequency (VARCHAR) -- 'daily', 'weekly', 'as_needed'
times (TIME[]) -- ['08:00', '20:00']
start_date (DATE)
end_date (DATE)
reason (TEXT)
notes (TEXT)
created_at (TIMESTAMP)
```

#### `shares` Table
```sql
id (UUID, PK)
report_id (UUID, FK → reports)
shared_by (UUID, FK → users)
shared_with (UUID, FK → users)
permissions (VARCHAR[]) -- ['read', 'comment']
shared_at (TIMESTAMP)
revoked_at (TIMESTAMP)
```

### Vector Database (ChromaDB)

#### `nirmaya_reports` Collection
**Documents**: Text chunks from reports (500-char chunks)
**IDs**: `{report_id}_{chunk_index}`
**Metadata**: `{ "report_id": "uuid" }`
**Embeddings**: Generated by Ollama

---

## Key Design Patterns & Decisions

### 1. **Privacy-First Architecture**
- All AI/ML processing on-device or local backend
- Ollama runs locally (no cloud API calls for LLM)
- ChromaDB persistent storage (user data never leaves)
- HTTPS only for network communication
- End-to-end encrypted sensitive data

### 2. **Offline-First Mobile**
- SQLite local database for offline access
- Sync when connection returns
- Medication reminders work offline
- Emergency data cached locally

### 3. **Modular Service Architecture**
- Each AI service independent and reusable
- Microservice-like separation (OCR, NLP, LLM, RAG)
- Easy to upgrade individual components
- Clear API boundaries

### 4. **RAG over Fine-tuning**
- Retrieve-Augmented Generation prevents hallucinations
- No need for model fine-tuning
- Works with any LLM (swappable)
- Semantic search for better results
- User data stays indexed locally

### 5. **Progressive Enhancement**
- Core functionality works without AI
- AI features enhance but don't block
- Graceful degradation on AI service failure
- Fallback options available

---

## Future Enhancements

### Planned Features
1. **Wearable Integration**: Connect smartwatches for continuous monitoring
2. **Doctor Messaging**: Secure in-app messaging with doctors
3. **Appointment Management**: Schedule and track appointments
4. **Prescription QR**: Generate QR codes for pharmacy refills
5. **Insurance Integration**: Claim tracking and submission
6. **Multi-language Support**: Localization for regional languages
7. **Voice Commands**: Voice-based health logging
8. **Predictive Analytics**: ML-based health risk prediction
9. **Family Sharing**: Multi-user access for family members
10. **Blockchain Verification**: Immutable record verification

### Technical Roadmap
- [ ] GraphQL API option
- [ ] WebRTC for telemedicine
- [ ] Advanced biometric auth (fingerprint, face)
- [ ] Improved OCR for handwritten records
- [ ] Real-time health monitoring dashboard
- [ ] Enhanced RAG with multi-document correlation
- [ ] Automated claim submission workflow

---

## Troubleshooting

### Common Issues

**OCR not working**
- Verify Tesseract installation path in `.env`
- Ensure PDF has text layer (not image-only)
- Check file permissions

**LLM slow responses**
- Verify Ollama service is running
- Reduce model size (switch to llama2:7b)
- Ensure sufficient RAM

**Flutter connection issues**
- Update backend URL in `api_service.dart`
- Verify backend is accessible from device network
- Check CORS configuration on backend

**Emergency SOS not working**
- Request location permissions
- Verify geolocator service is running
- Check network connectivity

---

## Performance Optimization

### Backend
- **OCR**: 2-5 seconds per page (depends on image quality)
- **NLP**: 1-3 seconds per report
- **LLM**: 5-10 seconds per summary (depends on model)
- **RAG Query**: 2-3 seconds per question

### Frontend
- **Report Upload**: < 10 seconds for typical lab report
- **Chat Response**: 5-10 seconds end-to-end
- **Emergency Trigger**: < 2 seconds
- **Home Screen Load**: < 1 second with caching

---

## Security Considerations

1. **Authentication**: JWT tokens with expiration
2. **Authorization**: Role-based access control
3. **Data Encryption**: TLS for transport, encryption at rest
4. **Input Validation**: Sanitize all user inputs
5. **Rate Limiting**: Prevent abuse on API endpoints
6. **HIPAA Compliance**: If handling PHI (Protected Health Information)
7. **Audit Logging**: Track all sensitive operations
8. **Secure Deletion**: Permanent deletion of sensitive data

---

## Support & Contact

For issues, features, or documentation updates:
- **Repository**: [GitHub Nirmaya](https://github.com/...)
- **Issues**: Report bugs on GitHub
- **Documentation**: See `nirmaya_api_docs.md`

---

## License

Proprietary - All rights reserved

---

**Document Version**: 1.0  
**Last Updated**: May 4, 2026  
**Status**: Complete System Documentation
