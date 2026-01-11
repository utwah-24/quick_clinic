# Hospital Registration API Documentation

## Overview

This API provides endpoints for hospital registration and management in Tanzania, following the requirements for Health Facility Registration System (HFRS) compliance and legal verification.

- **Base URL**: `https://api.quickclinic.example.com/v1`
- **Authentication**: Bearer tokens obtained via OAuth 2.0 client credentials flow
- **Content Type**: `application/json` (for data), `multipart/form-data` (for document uploads)
- **Versioning**: Prefix endpoints with `/v1`

## Authentication

### Get Access Token

- **Endpoint**: `POST /v1/auth/token`
- **Description**: Issue short-lived access tokens for hospital administrators or system integrations.
- **Request Body**:
  ```json
  {
    "client_id": "string (required)",
    "client_secret": "string (required)",
    "grant_type": "client_credentials"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "access_token": "string",
    "token_type": "Bearer",
    "expires_in": 3600
  }
  ```

## Hospital Registration

### Create Hospital Registration

- **Endpoint**: `POST /v1/hospitals`
- **Description**: Register a new hospital with complete information including legal compliance, infrastructure, and personnel details.
- **Request Body**:
  ```json
  {
    "hospital_name": "string (required)",
    "is_polyclinic": "boolean (required)",
    
    "physical_address": {
      "street": "string (required)",
      "area": "string (required)",
      "ward": "string (required)",
      "district": "string (required)",
      "region": "string (required)",
      "gps_coordinates": {
        "latitude": "number (required, highly recommended)",
        "longitude": "number (required, highly recommended)"
      }
    },
    
    "contact_details": {
      "main_phone": "string (required)",
      "landline": "string (optional)",
      "mobile": "string (optional)",
      "official_email": "string (required, valid email format)",
      "website": "string (optional, valid URL)"
    },
    
    "ownership_type": "enum (required): government_public, fbo, ngo, private_for_profit",
    "affiliation": {
      "health_system": "string (optional)",
      "network_affiliation": "string (optional)",
      "other_medical_affiliation": "string (optional)"
    },
    
    "date_operation_began": {
      "year": "number (required, 4 digits)",
      "month": "number (required, 1-12)"
    },
    
    "credentialing_contact": {
      "name": "string (required)",
      "title": "string (required, e.g., Medical Officer in Charge, HR/Credentialing Officer)",
      "direct_phone": "string (required)",
      "direct_email": "string (required, valid email format)"
    },
    
    "registration_legal_compliance": {
      "hfrs_number": "string (required, official registration number from Ministry of Health)",
      "operating_license": {
        "license_number": "string (required)",
        "expiration_date": "string (required, ISO 8601 date format)"
      },
      "business_registration": {
        "brela_certificate_number": "string (required for non-government facilities)",
        "certificate_of_incorporation": "string (optional)",
        "tin_certificate_number": "string (required)",
        "registration_number": "string (optional)"
      },
      "nhif_status": {
        "accepts_nhif": "boolean (required)",
        "nhif_accreditation_number": "string (required if accepts_nhif is true)",
        "nhif_accreditation_date": "string (optional, ISO 8601 date format, required if accepts_nhif is true)"
      },
      "accreditations": [
        {
          "accreditation_body": "string (required, e.g., TMDA for medical devices)",
          "accreditation_number": "string (required)",
          "accreditation_date": "string (optional, ISO 8601 date format)",
          "expiration_date": "string (optional, ISO 8601 date format)"
        }
      ]
    },
    
    "clinical_services_infrastructure": {
      "level_of_facility": "enum (required): national_hospital, regional_referral_hospital, district_hospital, health_centre, dispensary, other",
      "services_offered": {
        "inpatient_services": "boolean (required)",
        "outpatient_services": "boolean (required)",
        "emergency_casualty_services": "boolean (required)",
        "major_specialties": [
          "string (e.g., Surgery, Paediatrics, Obstetrics/Gynaecology, Internal Medicine)"
        ],
        "ancillary_services": {
          "laboratory": "boolean (required)",
          "radiology_imaging": "boolean (required)",
          "pharmacy": "boolean (required)",
          "other": ["string (optional)"]
        }
      },
      "capacity": {
        "total_bed_capacity": "number (required)",
        "number_of_operating_theatres": "number (required if major_specialties includes Surgery)"
      },
      "utilities_infrastructure": {
        "water_supply_source": "string (required, e.g., National Grid, Borehole, Well, Tanker)",
        "power_source": {
          "national_grid": "boolean (required)",
          "backup_generator": "boolean (required)",
          "other": "string (optional)"
        },
        "waste_management": {
          "has_incinerator": "boolean (required)",
          "waste_management_contract": "string (optional, if no incinerator)"
        }
      }
    },
    
    "key_personnel_staffing": {
      "head_of_facility": {
        "name": "string (required)",
        "professional_title": "string (required)",
        "contact_phone": "string (required)",
        "contact_email": "string (required, valid email format)",
        "mct_registration_number": "string (required, Medical Council of Tanganyika registration number)"
      },
      "nursing_officer_in_charge": {
        "name": "string (required)",
        "professional_title": "string (required)",
        "contact_phone": "string (required)",
        "contact_email": "string (required, valid email format)",
        "tnmc_registration_number": "string (required, Tanzania Nursing and Midwifery Council registration number)"
      },
      "pharmacist_in_charge": {
        "name": "string (required)",
        "professional_title": "string (required, e.g., Pharmacist, Pharmacy Technician)",
        "contact_phone": "string (required)",
        "contact_email": "string (required, valid email format)",
        "pharmacy_council_registration_number": "string (required)"
      },
      "total_staff_numbers": {
        "doctors": "number (required)",
        "nurses": "number (required)",
        "clinical_officers": "number (required)",
        "allied_health_professionals": "number (required)",
        "non_clinical_staff": "number (required)"
      }
    }
  }
  ```

- **Success Response**: `201 Created`
  ```json
  {
    "hospital_id": "string (UUID)",
    "hospital_name": "string",
    "hfrs_number": "string",
    "status": "pending_verification",
    "verification_status": "pending",
    "created_at": "ISO 8601 datetime",
    "message": "Hospital registration submitted successfully. Please upload required documents."
  }
  ```

- **Error Responses**:
  - `400 Bad Request`: Validation error
    ```json
    {
      "error": {
        "code": "validation_error",
        "message": "Validation failed",
        "details": [
          {
            "field": "hospital_name",
            "issue": "Hospital name is required"
          }
        ]
      }
    }
    ```
  - `409 Conflict`: Hospital with HFRS number already exists
  - `422 Unprocessable Entity`: Invalid GPS coordinates or date format

### Upload Required Documents

- **Endpoint**: `POST /v1/hospitals/{hospital_id}/documents`
- **Description**: Upload required documents for hospital registration verification.
- **Content-Type**: `multipart/form-data`
- **Request Body** (Form Data):
  ```
  official_application_letter: File (required, PDF, DOC, DOCX, max 10MB)
  operating_license: File (required, PDF, JPG, PNG, max 5MB)
  hfrs_registration_certificate: File (required, PDF, JPG, PNG, max 5MB)
  brela_certificate: File (required for non-government facilities, PDF, JPG, PNG, max 5MB)
  tin_certificate: File (required, PDF, JPG, PNG, max 5MB)
  organizational_structure: File (optional, PDF, DOC, DOCX, max 10MB)
  floor_plan: File (optional, PDF, JPG, PNG, max 10MB)
  facility_photos: File[] (required, at least 3 photos: entrance, reception, operating_theatre/waste_area, JPG, PNG, max 5MB each)
  ```
  
  **Note**: `facility_photos` should include:
  - Entrance photo (required)
  - Reception area photo (required)
  - Operating theatre photo (if applicable)
  - Incinerator/waste area photo (required if has_incinerator is true)

- **Success Response**: `200 OK`
  ```json
  {
    "hospital_id": "string (UUID)",
    "documents_uploaded": [
      {
        "document_type": "official_application_letter",
        "file_name": "string",
        "file_size": "number (bytes)",
        "uploaded_at": "ISO 8601 datetime",
        "status": "uploaded"
      }
    ],
    "documents_required": [
      {
        "document_type": "operating_license",
        "status": "pending|uploaded|verified|rejected"
      }
    ],
    "verification_status": "documents_pending|under_review|verified|rejected"
  }
  ```

- **Error Responses**:
  - `400 Bad Request`: Invalid file type or size
  - `404 Not Found`: Hospital not found
  - `413 Payload Too Large`: File size exceeds limit

### Get Hospital Details

- **Endpoint**: `GET /v1/hospitals/{hospital_id}`
- **Description**: Retrieve complete hospital registration details including all submitted information and document status.
- **Response**: `200 OK`
  ```json
  {
    "hospital_id": "string (UUID)",
    "hospital_name": "string",
    "is_polyclinic": "boolean",
    "physical_address": { ... },
    "contact_details": { ... },
    "ownership_type": "string",
    "affiliation": { ... },
    "date_operation_began": { ... },
    "credentialing_contact": { ... },
    "registration_legal_compliance": { ... },
    "clinical_services_infrastructure": { ... },
    "key_personnel_staffing": { ... },
    "documents": [
      {
        "document_type": "string",
        "file_name": "string",
        "file_url": "string (signed URL, expires in 1 hour)",
        "uploaded_at": "ISO 8601 datetime",
        "status": "uploaded|verified|rejected",
        "verified_at": "ISO 8601 datetime (optional)",
        "rejection_reason": "string (optional)"
      }
    ],
    "verification_status": "pending|documents_pending|under_review|verified|rejected",
    "verified_at": "ISO 8601 datetime (optional)",
    "verified_by": "string (admin user ID, optional)",
    "rejection_reason": "string (optional)",
    "created_at": "ISO 8601 datetime",
    "updated_at": "ISO 8601 datetime"
  }
  ```

### Update Hospital Registration

- **Endpoint**: `PATCH /v1/hospitals/{hospital_id}`
- **Description**: Update hospital registration information. Partial updates allowed. Cannot update immutable fields after verification.
- **Request Body**: Any subset of hospital fields (same structure as create)
- **Rules**:
  - Cannot update: `hospital_id`, `hfrs_number`, `created_at`
  - After verification, some fields require re-verification: `ownership_type`, `registration_legal_compliance`, `key_personnel_staffing`
  - Status changes require admin approval
- **Response**: `200 OK` - Updated hospital object

### List Hospitals

- **Endpoint**: `GET /v1/hospitals`
- **Description**: List all hospitals with filtering, sorting, and pagination.
- **Query Parameters**:
  - `region` (string, optional): Filter by region
  - `district` (string, optional): Filter by district
  - `ward` (string, optional): Filter by ward
  - `ownership_type` (enum, optional): Filter by ownership type
  - `level_of_facility` (enum, optional): Filter by facility level
  - `is_polyclinic` (boolean, optional): Filter by polyclinic status
  - `verification_status` (enum, optional): Filter by verification status (pending, documents_pending, under_review, verified, rejected)
  - `accepts_nhif` (boolean, optional): Filter by NHIF acceptance
  - `search` (string, optional): Search by hospital name or HFRS number
  - `page` (number, default: 1): Page number
  - `limit` (number, default: 20, max: 100): Items per page
  - `sort_by` (string, default: "created_at"): Sort field (created_at, hospital_name, region)
  - `sort_order` (enum, default: "desc"): Sort order (asc, desc)
- **Response**: `200 OK`
  ```json
  {
    "hospitals": [
      {
        "hospital_id": "string (UUID)",
        "hospital_name": "string",
        "hfrs_number": "string",
        "region": "string",
        "district": "string",
        "ownership_type": "string",
        "verification_status": "string",
        "created_at": "ISO 8601 datetime"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "total_pages": 8
    }
  }
  ```

## Hospital Verification (Admin Endpoints)

### Verify Hospital Registration

- **Endpoint**: `POST /v1/hospitals/{hospital_id}/verify`
- **Description**: Admin endpoint to verify or reject hospital registration after reviewing documents and information.
- **Request Body**:
  ```json
  {
    "status": "enum (required): verified, rejected",
    "notes": "string (optional, required if status is rejected)",
    "verified_by": "string (required, admin user ID)",
    "document_feedback": [
      {
        "document_type": "string",
        "status": "verified|rejected",
        "notes": "string (optional)"
      }
    ]
  }
  ```
- **Response**: `200 OK` - Updated hospital object with verification status
- **Error Responses**:
  - `403 Forbidden`: User does not have admin permissions
  - `404 Not Found`: Hospital not found
  - `400 Bad Request`: Invalid verification status or missing required documents

### Get Hospitals Pending Verification

- **Endpoint**: `GET /v1/hospitals/pending-verification`
- **Description**: Admin endpoint to retrieve all hospitals pending verification review.
- **Query Parameters**:
  - `status` (enum, optional): Filter by pending status (pending, documents_pending, under_review)
  - `page` (number, default: 1)
  - `limit` (number, default: 20)
- **Response**: `200 OK` - Paginated list of hospitals with pending verification

## Document Management

### Get Document

- **Endpoint**: `GET /v1/hospitals/{hospital_id}/documents/{document_type}`
- **Description**: Retrieve a specific document for a hospital. Returns signed URL valid for 1 hour.
- **Response**: `200 OK`
  ```json
  {
    "document_type": "string",
    "file_name": "string",
    "file_url": "string (signed URL, expires in 1 hour)",
    "file_size": "number (bytes)",
    "uploaded_at": "ISO 8601 datetime",
    "status": "uploaded|verified|rejected",
    "verified_at": "ISO 8601 datetime (optional)"
  }
  ```

### Delete Document

- **Endpoint**: `DELETE /v1/hospitals/{hospital_id}/documents/{document_type}`
- **Description**: Delete a document. Only allowed if verification status is pending or documents_pending.
- **Response**: `204 No Content`
- **Error Responses**:
  - `400 Bad Request`: Cannot delete document - hospital is verified or under review
  - `404 Not Found`: Document not found

### List All Documents

- **Endpoint**: `GET /v1/hospitals/{hospital_id}/documents`
- **Description**: List all documents uploaded for a hospital.
- **Response**: `200 OK`
  ```json
  {
    "hospital_id": "string (UUID)",
    "documents": [
      {
        "document_type": "string",
        "file_name": "string",
        "file_size": "number (bytes)",
        "uploaded_at": "ISO 8601 datetime",
        "status": "uploaded|verified|rejected",
        "verified_at": "ISO 8601 datetime (optional)"
      }
    ],
    "documents_required": [
      {
        "document_type": "string",
        "status": "pending|uploaded|verified|rejected",
        "required": "boolean"
      }
    ]
  }
  ```

## Error Handling

### Standard Error Format

```json
{
  "error": {
    "code": "string",
    "message": "Human readable message",
    "details": [
      {
        "field": "string",
        "issue": "validation error description"
      }
    ],
    "trace_id": "UUID for support"
  }
}
```

### Common Error Codes

- `validation_error` - Request validation failed
- `hospital_exists` - Hospital with HFRS number already exists
- `hospital_not_found` - Hospital ID not found
- `document_not_found` - Document not found
- `invalid_credentials` - Authentication failed
- `invalid_location` - Invalid GPS coordinates
- `invalid_file_type` - File type not allowed
- `file_too_large` - File size exceeds limit
- `verification_required` - Hospital requires verification before operation
- `insufficient_permissions` - User does not have required permissions
- `hfrs_number_required` - HFRS number is required for registration
- `license_expired` - Operating license has expired
- `mct_registration_invalid` - MCT registration number validation failed
- `tnmc_registration_invalid` - TNMC registration number validation failed
- `pharmacy_registration_invalid` - Pharmacy council registration number validation failed

## Data Validation Rules

### GPS Coordinates
- Latitude: Must be between -90 and 90
- Longitude: Must be between -180 and 180
- Highly recommended for mapping and verification purposes

### Email Addresses
- Must be valid email format
- Official email and credentialing contact email must be different domains (recommended)

### Phone Numbers
- Must follow Tanzania phone number format
- Can include country code (+255) or local format

### Registration Numbers
- HFRS Number: Must be unique across the system
- MCT Registration Number: Validated against Medical Council of Tanganyika database (if available)
- TNMC Registration Number: Validated against Tanzania Nursing and Midwifery Council database (if available)
- Pharmacy Council Registration: Validated against Pharmacy Council database (if available)

### Dates
- All dates must be in ISO 8601 format (YYYY-MM-DD)
- Operating license expiration date must be in the future
- Date operation began must not be in the future

### File Uploads
- Accepted formats: PDF, DOC, DOCX, JPG, JPEG, PNG
- Maximum file size: 10MB per file
- Facility photos: Minimum 3 photos required, maximum 10 photos

## Rate Limiting

- Default quota: 100 requests per minute per client
- Document uploads: 10 uploads per minute per hospital
- Headers:
  - `X-RateLimit-Limit`: Maximum number of requests
  - `X-RateLimit-Remaining`: Remaining requests in current window
  - `Retry-After`: Seconds to wait before retrying (if rate limited)

## Changelog

- `v1.0.0` – Initial hospital registration API with comprehensive Tanzania health facility registration requirements, legal compliance, clinical services, key personnel, and document management endpoints.
