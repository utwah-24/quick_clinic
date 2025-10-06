### Doctor Login API

#### Endpoint
- **Method**: POST
- **URL**: `/api/auth/doctor/login`

#### Headers
- `Content-Type: application/json`

#### Request Body
```json
{
  "email": "doctor@example.com",
  "password": "StrongPassword123!",
  "rememberMe": true,
  "twoFactorCode": "123456"
}
```

- **email**: string, required
- **password**: string, required
- **rememberMe**: boolean, optional
- **twoFactorCode**: string, optional (required if 2FA is enabled)

#### Success Response (200)
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOi...",
  "data": {
    "id": "doc_123",
    "name": "Dr. Jane Doe",
    "email": "doctor@example.com",
    "phone": "+255700000000",
    "licenseNumber": "TMC-123456",
    "specialty": "Cardiology",
    "yearsOfExperience": 8,
    "clinicName": "Sunrise Clinic",
    "clinicAddress": "123 Main St, Dar es Salaam",
    "bio": "Cardiologist with a focus on preventive care"
  }
}
```

Notes:
- **success/message**: mirrors registration response structure used in the app
- **token**: JWT string stored by the app for authenticated calls
- **data**: doctor profile fields aligned with registration payload
- Some backends may return the profile under `user` instead of `data`; the app supports both.

#### Error Responses

- 400 Bad Request
```json
{
  "success": false,
  "error": {
    "code": "BAD_REQUEST",
    "message": "Invalid payload",
    "details": [
      { "field": "email", "message": "Email is required" }
    ]
  }
}
```

- 401 Unauthorized (invalid credentials)
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Email or password is incorrect"
  }
}
```

- 401 Unauthorized (2FA required)
```json
{
  "success": false,
  "error": {
    "code": "MFA_REQUIRED",
    "message": "Two-factor code required",
    "mfa": {
      "methods": ["totp", "sms"],
      "method": "totp",
      "expiresIn": 300
    }
  }
}
```

- 403 Forbidden (not a doctor)
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Account not authorized for doctor access"
  }
}
```

- 423 Locked (account locked)
```json
{
  "success": false,
  "error": {
    "code": "ACCOUNT_LOCKED",
    "message": "Account locked due to multiple failed attempts",
    "retryAfter": 900
  }
}
```

- 429 Too Many Requests
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many login attempts. Please try again later."
  }
}
```

- 500 Server Error
```json
{
  "success": false,
  "error": {
    "code": "SERVER_ERROR",
    "message": "An unexpected error occurred"
  }
}
```

#### Example cURL
```bash
curl -X POST "https://api.example.com/api/auth/doctor/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"doctor@example.com","password":"StrongPassword123!","rememberMe":true}'
```

#### Authorization Usage
- Include `Authorization: Bearer <accessToken>` on subsequent requests.
- Refresh with `/api/v1/auth/refresh` using `refreshToken` when the access token expires.


