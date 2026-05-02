# Nirmaya Medical Records API - Complete Real Implementation Documentation

## Base Configuration

- **Base URL**: `/api/v1`
- **Authentication**: JWT Bearer Token
- **Error Formats**: Standardized JSON wrapped via `errorHandler.ts`
- **Application Port**: Defined by environment configuration

---

## Authentication

### Standard Response Objects
Common definitions across the application logic. All API JSON responses abide by the standard wrapper configuration inside `utils/appError.ts` / express `res.json()`.

```json
{
  "status": "success",
  "data": { ... },
  "message": "Optional contextual message string"
}
```

---

## Public General Routes

### `GET /health`
System health check endpoint ensuring DB, Supabase, and Environmental stability.
- **Auth required:** None

---

## Authentication (`/api/v1/auth`)

### `POST /auth/register/patient`
Register a new patient account and initialize them within the DB `users` and `patients` schema blocks.

**Request Body** *(Derived from `auth.validators.ts`)*:
```json
{
  "name": "Jane Example",
  "email": "jane@example.com",
  "password": "Password123!",
  "phone": "+1234567890",
  "age": 35,
  "gender": "female",
  "bloodGroup": "O+",
  "height": 165,
  "weight": 60,
  "allergies": [
    {
      "name": "Peanut",
      "severity": "severe",
      "description": "Detailed allergy notes"
    }
  ],
  "chronicConditions": [
    {
      "name": "Asthma",
      "diagnosisDate": "2020-01-15",
      "status": "active",
      "notes": "Mild inhaler usage"
    }
  ],
  "emergencyContacts": [
    {
      "name": "Dad Example",
      "phone": "+1987654321",
      "relationship": "parent",
      "priority": 1
    }
  ]
}
```
**Notes:** `phone`, `age`, `gender`, `bloodGroup`, `height`, `weight`, `allergies`, `chronicConditions`, and `emergencyContacts` are strictly optional.

### `POST /auth/login`
Authenticate user identity against database constraints.

**Request Body**:
```json
{
  "email": "jane@example.com",
  "password": "Password123!"
}
```

### `POST /auth/forgot-password`
Request magic password reset link capabilities via email delivery trigger.

**Request Body**:
```json
{
  "email": "jane@example.com"
}
```

### `POST /auth/reset-password`
Reset the patient's password securely completing the `forgot-password` loop.

**Request Body**:
```json
{
  "token": "PROVIDED_RESET_TOKEN",
  "password": "NewSecurePassword123!"
}
```

---

## Patient Endpoints (`/api/v1/patient`)

**Authorization Header Constraint**: `Authorization: Bearer <your_jwt_here>` strictly mandated by the `authenticate` middleware. Restricted specifically to the 'patient' level role.

### Profile & Vitals

#### `GET /patient/me`
Pull completely normalized authenticated patient profile information.

#### `GET /patient/health`
Get an absolute history array of tracked vital metrics across the patient's records history.

#### `POST /patient/health`
Submit/Log a brand new health telemetry reading mapping straight into the `healthData` database schema.

**Request Body** *(Derived from `patient.validators.ts`)*:
```json
{
  "bloodPressure": "120/80",
  "bloodGlucose": 95,
  "heartRate": 75,
  "temperature": 98.6,
  "weight": 65,
  "notes": "Felt completely ordinary today.",
  "recordedAt": "2023-10-31T09:00:00Z"
}
```
*Note: All keys here are universally optional.*


### Reporting & Clinical File Storage

#### `GET /patient/reports`
Return all associated clinical reports filed locally securely for that user UUID.

#### `POST /patient/reports`
Establish a new clinical Document pointer mapped to database tracking.

**Request Body**:
```json
{
  "type": "report", 
  "title": "Complete Blood Count",
  "fileUrl": "https://<supabase-or-s3>/bucket/path_reference",
  "originalContent": "Raw OCR content optional data",
  "documentDate": "2026-05-02T10:00:00Z",
  "privacy": "private",
  "metadata": {}
}
```
*(Valid `type` values: "prescription", "report", "scan", "vaccination", "other")*

#### `PUT /patient/reports/:reportId`
Patch modification updates into existing document tracking logs recursively.
*(Takes partial body mappings of the `POST` interface)*

#### `DELETE /patient/reports/:reportId`
Obliterate a specific clinical report securely.

---

### Prescriptions Tracker

#### `GET /patient/prescriptions`
Fetch a list of exclusively loaded prescription tracking sheets.

#### `POST /patient/prescriptions`
Upload clinical prescription referencing. (Shares mapping fields with reporting structures).

#### `PUT /patient/prescriptions/:prescriptionId`
Patch updates into specific prescription IDs incrementally.

#### `DELETE /patient/prescriptions/:prescriptionId`
Oblatarate a specific clinical prescription entirely by UUID.

---

### Emergency Operations SOS

#### `POST /patient/emergency`
Trigger a physical emergency broadcasting system alert directly referencing the `emergencySos` repository structures.

**Request Body**:
```json
{
  "latitude": "40.7128",
  "longitude": "-74.0060",
  "ambulanceCalled": true,
  "voiceMessageSent": false,
  "contactsNotified": ["<uuid-of-contact-1>", "<uuid-of-contact-2>"]
}
```
*All fields are optional default boolean fallbacks to `false`*.

#### `GET /patient/emergency`
Pull physical SOS history log timestamps structurally over time.

#### `GET /patient/emergency/:sosId`
Return verbose detail map of specific SOS triggering identifier.

#### `PUT /patient/emergency/:sosId`
Amend active status flags across initialized active emergency states. (e.g. resolve event status updates).

---

### Share Tokens Generator (`/api/v1/patient/share-tokens`)
Manages generating unique viewing windows explicitly for clinical access parameters explicitly restricted to your access definitions.

#### `POST /patient/share-tokens`
Construct an isolated data sharing capability reference token securely.

#### `GET /patient/share-tokens`
List historically requested sharing configurations.

#### `DELETE /patient/share-tokens/:tokenId`
Forced revocation capabilities manually ending access prematurely globally bypassing time delays.

---

### Access Tracking & Security Audits

#### `GET /patient/audit-logs`
Observe standard interaction records associated with physical actions within database records.

#### `GET /patient/access-logs`
Observe standard security validations generated by Share Tokens mapping third-party access identifiers against local viewing.

#### `POST /patient/access-logs`
Allow applications to register custom Access manual markers against token viewing interactions natively.

#### `PUT /patient/access-logs/:accessLogId`
Ability for tracking controllers to update status blocks across access log identifiers incrementally.

---

### External Uploading Handling (`/api/v1/patient/uploads`)
Supabase/S3 Storage Interaction Interfaces locally wrapped natively.

#### `POST /patient/uploads/file`
Upload file directly using physical local multer interception formatting mappings. Uses explicit `multipart/form-data`.

#### `POST /patient/uploads/sign`
Authorize an empty pre-signed secure blob window reference for your direct client-front-side implementations explicitly optimizing large data offloads securely.
**Request Body**:
```json
{
  "fileName": "document.pdf",
  "contentType": "application/pdf",
  "folder": "reports"
}
```
*(Folder Types limited strictly locally natively to: "reports", "prescriptions", "scans", "other")*

#### `POST /patient/uploads/finalize`
Lock frontend successful uploads to system DB integration mappings natively structurally mimicking exactly the native `POST /reports` definition.

---

## Admin Subsystem (`/api/v1/admin`)

*Strictly enforces both `authenticate` AND `requireAdmin` custom middlewares comprehensively mapped over endpoints native configurations globally.*

### `POST /admin/doctors`
Establish explicit Doctor role accounts administratively securely avoiding general registration pathways exclusively natively explicitly.

**Request Body**:
```json
{
  "name": "Dr Example",
  "email": "doctor@hospital.com",
  "password": "StrongPassword123!",
  "licenseNumber": "MED12345678",
  "specialization": "Cardiology",
  "phone": "+1234555666",
  "age": 45,
  "gender": "male",
  "bio": "Certified specialist details",
  "verified": true
}
```
*(Only `name`, `email`, `password`, `licenseNumber`, and `specialization` natively required)*

### `GET /admin/patients`
Global patient index array pulling functionally for root system administrations.

### `GET /admin/patients/:patientId`
Global direct patient view extraction targeting manually explicit parameters.

### `PUT /admin/patients/:patientId`
Direct absolute data administration mutator explicit bypass capabilities over standard limitations.

### `DELETE /admin/patients/:patientId`
Critical deletion handling permanently restricting account existence.

---

## Secure Public Viewing Engine (`/api/v1/share`)

#### `POST /share/:token/access`
Allow programmatic third parties natively verified validation across specific tokens accessing isolated payloads mapped tightly exclusively to scopes allocated independently locally natively structured securely inside Token middleware evaluations correctly.