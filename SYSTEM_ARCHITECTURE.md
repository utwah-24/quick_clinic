# Quick Clinic - System Architecture

## Table of Contents
1. [Overview](#overview)
2. [High-Level Architecture](#high-level-architecture)
3. [Project Structure](#project-structure)
4. [Layer Architecture](#layer-architecture)
5. [Component Diagram](#component-diagram)
6. [Data Flow](#data-flow)
7. [Technology Stack](#technology-stack)
8. [Key Components](#key-components)
9. [Service Layer Details](#service-layer-details)
10. [State Management](#state-management)

---

## Overview

**Quick Clinic** is a Flutter-based medical booking application that enables patients to find hospitals, book appointments, schedule home visits, and manage their medical records. The application follows a clean architecture pattern with separation of concerns across presentation, business logic, and data layers.

### Key Features
- Hospital discovery and search
- Appointment booking system
- Home visit scheduling
- User authentication (Patient & Doctor)
- Location-based services
- Push notifications
- Payment integration
- Emergency services

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Patient    │  │    Doctor    │  │   Shared     │     │
│  │   Screens    │  │   Screens    │  │   Widgets    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │    Data      │  │  Location    │  │ Notification │     │
│  │   Service    │  │   Service    │  │   Service    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Home Visit   │  │  Directions  │  │ Localization│     │
│  │   Service    │  │   Service    │  │   Service    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   API        │  │   Local      │  │   Models     │     │
│  │   Client     │  │   Storage    │  │              │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    External Services                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Backend    │  │   Location    │  │ Notification │     │
│  │     API      │  │   Services    │  │   Provider   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
lib/
├── main.dart                          # Application entry point
│
├── models/                            # Data Models
│   ├── user.dart                      # User model (Patient/Doctor)
│   ├── hospital.dart                  # Hospital model
│   ├── appointment.dart               # Appointment model
│   ├── home_visit.dart                # Home visit provider model
│   ├── home_visit_booking.dart        # Home visit booking model
│   ├── payment_method.dart            # Payment method model
│   └── in_app_notification.dart       # Notification model
│
├── screens/                           # UI Screens
│   ├── splash_screen.dart             # App splash screen
│   ├── intro_screen.dart              # Introduction screen
│   ├── user_type_screen.dart          # User type selection
│   │
│   ├── patient/                       # Patient Screens
│   │   ├── home_screen.dart           # Patient dashboard
│   │   ├── hospitals_screen.dart      # Hospital listing
│   │   ├── hospital_profile_screen.dart
│   │   ├── doctor_details_screen.dart
│   │   ├── booking_screen.dart        # Appointment booking
│   │   ├── appointment_summary_screen.dart
│   │   ├── schedule_screen.dart       # Appointments list
│   │   ├── patient_profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── emergency_screen.dart
│   │   ├── notification_screen.dart
│   │   ├── home_visit_screen.dart
│   │   ├── home_visit_booking_screen.dart
│   │   ├── popular_doctors_screen.dart
│   │   ├── category_hospitals_screen.dart
│   │   ├── subscription_prompt_screen.dart
│   │   ├── add_payment_method_screen.dart
│   │   └── add_card_details_screen.dart
│   │
│   ├── doctor/                        # Doctor Screens
│   │   ├── doctor_home_screen.dart    # Doctor dashboard
│   │   ├── doctor_login_screen.dart
│   │   ├── doctor_register_screen.dart
│   │   ├── doctor_profile_screen.dart
│   │   ├── doctor_selection_screen.dart
│   │   ├── doctor_requests_screen.dart
│   │   └── doctor_screen.dart
│   │
│   └── location_permission_screen.dart
│
├── services/                          # Business Logic Services
│   ├── data_service.dart              # Main data service (API calls)
│   ├── api_client.dart                # HTTP client wrapper
│   ├── location_service.dart          # Location & geolocation
│   ├── notification_service.dart      # Push notifications
│   ├── home_visit_service.dart        # Home visit management
│   ├── directions_service.dart        # Navigation directions
│   └── localization_service.dart      # i18n support
│
├── widgets/                           # Reusable UI Components
│   ├── drawer.dart                    # Navigation drawer
│   ├── dynamic_app_bar.dart           # Custom app bar
│   └── custom_bottom_nav_bar.dart     # Bottom navigation
│
└── utils/                             # Utility Functions
    └── responsive.dart                # Responsive design helpers
```

---

## Layer Architecture

### 1. Presentation Layer
**Location:** `lib/screens/`, `lib/widgets/`

**Responsibilities:**
- UI rendering and user interaction
- Navigation and routing
- Form validation
- User feedback (loading states, errors)

**Key Components:**
- **Screens:** Full-page UI components
- **Widgets:** Reusable UI components
- **Navigation:** Flutter Navigator with named routes

**Pattern:** Stateless/Stateful widgets following Material Design

### 2. Business Logic Layer
**Location:** `lib/services/`

**Responsibilities:**
- Business rules and logic
- Data transformation
- Service orchestration
- State management

**Key Services:**
- **DataService:** Central data management, API orchestration
- **LocationService:** Geolocation, distance calculations
- **NotificationService:** Push notification handling
- **HomeVisitService:** Home visit booking logic
- **DirectionsService:** Navigation and routing

**Pattern:** Singleton services with static methods

### 3. Data Layer
**Location:** `lib/models/`, `lib/services/api_client.dart`

**Responsibilities:**
- Data models and serialization
- API communication
- Local storage
- Data caching

**Key Components:**
- **Models:** Data structures (User, Hospital, Appointment, etc.)
- **ApiClient:** HTTP request handling
- **SharedPreferences:** Local data persistence

**Pattern:** Repository pattern (implicit through services)

---

## Component Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                         main.dart                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │          MedicalBookingApp (StatefulWidget)           │  │
│  │  - Initializes services                                │  │
│  │  - Sets up routing                                     │  │
│  │  - Loads environment variables                         │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    Route Configuration                        │
│  / → SplashScreen                                            │
│  /intro → IntroScreen                                        │
│  /user-type → UserTypeScreen                                │
│  /home → HomeScreen (Patient)                               │
│  /hospitals → HospitalsScreen                               │
│  /appointments → ScheduleScreen                             │
│  /profile → PatientProfileScreen                            │
│  /doctor-home → DoctorHomeScreen                            │
│  ...                                                         │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    Service Initialization                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Location     │  │ Notification │  │ Data         │     │
│  │ Service      │  │ Service      │  │ Service      │     │
│  │ .initialize()│  │ .initialize()│  │ .loadUser()  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Authentication Flow
```
User Input (Login Screen)
    │
    ▼
DataService.login()
    │
    ▼
ApiClient.post('/api/auth/login')
    │
    ▼
Backend API
    │
    ▼
Response (User + Token)
    │
    ▼
DataService.saveUser() → SharedPreferences
    │
    ▼
Navigate to Home Screen
```

### Hospital Search Flow
```
User Request (Hospitals Screen)
    │
    ▼
DataService.getNearbyHospitals()
    │
    ├─→ LocationService.getCurrentLocation()
    │
    ├─→ ApiClient.get('/api/hospitals')
    │
    └─→ Calculate distances
    │
    ▼
Sort by distance
    │
    ▼
Display in UI
```

### Appointment Booking Flow
```
User Selects Hospital/Doctor
    │
    ▼
Booking Screen
    │
    ├─→ Select Date & Time
    ├─→ Enter Problem Description
    └─→ Choose Payment Method
    │
    ▼
Appointment Summary Screen
    │
    ▼
DataService.createAppointment()
    │
    ▼
ApiClient.post('/api/appointments')
    │
    ▼
Backend API
    │
    ▼
Response (Appointment Confirmation)
    │
    ▼
Save to Local Storage
    │
    ▼
Show Success Message
    │
    ▼
Navigate to Schedule Screen
```

---

## Technology Stack

### Frontend Framework
- **Flutter SDK:** 3.32.4
- **Dart:** 3.8.1
- **Material Design:** Material 3 support

### Core Dependencies
```yaml
# State & Storage
shared_preferences: ^2.2.2        # Local data persistence

# Networking
http: ^1.2.2                      # HTTP client
flutter_dotenv: ^5.1.0            # Environment variables

# Location Services
geolocator: ^14.0.2               # GPS and location services
flutter_map: ^7.0.2               # Map rendering
latlong2: ^0.9.1                  # Geographic calculations

# Notifications
flutter_local_notifications: ^19.4.0  # Push notifications

# Media
image_picker: ^1.0.4              # Image selection

# Utilities
url_launcher: ^6.2.2              # External links
http_parser: ^4.0.2               # HTTP parsing
```

### Platform Support
- ✅ **Android** (Primary)
- ✅ **Windows** (Desktop)
- ✅ **Web** (Chrome, Edge)
- ⚠️ **iOS** (Not configured)

---

## Key Components

### 1. DataService (`lib/services/data_service.dart`)
**Purpose:** Central service for all data operations

**Key Methods:**
- `getNearbyHospitals()` - Fetch hospitals with distance calculation
- `getHospitalById()` - Get hospital details
- `createAppointment()` - Book appointment
- `getAppointments()` - Fetch user appointments
- `login()` / `register()` - Authentication
- `saveUser()` / `loadUser()` - User persistence
- `updateProfile()` - Update user profile
- `addPaymentMethod()` - Payment management

**Dependencies:**
- ApiClient (HTTP requests)
- LocationService (distance calculations)
- SharedPreferences (local storage)

### 2. LocationService (`lib/services/location_service.dart`)
**Purpose:** Handle all location-related operations

**Key Features:**
- GPS location tracking
- Permission handling
- Distance calculations (Haversine formula)
- Periodic location updates
- Fallback to Tanzania coordinates

**Key Methods:**
- `initialize()` - Service initialization
- `getCurrentLocation()` - Get user's current location
- `calculateDistance()` - Calculate distance between coordinates
- `startLocationUpdates()` - Start periodic updates

### 3. NotificationService (`lib/services/notification_service.dart`)
**Purpose:** Manage push notifications

**Key Features:**
- Local notifications
- Notification scheduling
- Notification handling
- Badge management

### 4. ApiClient (`lib/services/api_client.dart`)
**Purpose:** HTTP client wrapper

**Key Features:**
- Base URL configuration
- Request/response handling
- Error handling
- Authentication token management

### 5. Models
**Purpose:** Data structures and serialization

**Key Models:**
- **User:** Patient/Doctor information
- **Hospital:** Hospital details with location
- **Appointment:** Booking information
- **HomeVisit:** Home visit provider details
- **HomeVisitBooking:** Home visit booking details
- **PaymentMethod:** Payment options

---

## Service Layer Details

### DataService Architecture
```
DataService (Singleton)
│
├── ApiClient (HTTP Client)
│   └── Base URL: Environment variable
│
├── LocationService (Location)
│   └── Distance calculations
│
├── SharedPreferences (Storage)
│   ├── User data
│   ├── Auth token
│   └── Appointments cache
│
└── Static State
    ├── _currentUser
    ├── _authToken
    ├── _appointments
    └── _userRole
```

### LocationService Architecture
```
LocationService (Singleton)
│
├── Geolocator Plugin
│   ├── Permission handling
│   ├── Location tracking
│   └── Accuracy settings
│
├── Static State
│   ├── _currentLatitude
│   ├── _currentLongitude
│   └── _locationUpdateTimer
│
└── Methods
    ├── getCurrentLocation()
    ├── calculateDistance()
    └── startLocationUpdates()
```

---

## State Management

### Current Approach
The application uses **stateless services with static state** rather than a dedicated state management solution.

**State Storage:**
- **Services:** Static variables in service classes
- **Local Storage:** SharedPreferences for persistence
- **Widget State:** StatefulWidget for UI state

**State Flow:**
```
User Action
    │
    ▼
Service Method Call
    │
    ▼
Update Static State
    │
    ▼
Save to SharedPreferences (if needed)
    │
    ▼
Widget Rebuild (setState)
```

### Recommended Improvements
For future scalability, consider:
- **Provider** or **Riverpod** for state management
- **BLoC** pattern for complex business logic
- **GetX** for reactive state management

---

## Security Considerations

### Current Implementation
- Environment variables for API keys (`.env` file)
- SharedPreferences for local data storage
- HTTP client for API communication
- Token-based authentication

### Recommendations
- Implement token refresh mechanism
- Add encryption for sensitive local data
- Use HTTPS for all API calls
- Implement certificate pinning
- Add input validation and sanitization

---

## Performance Optimizations

### Current Optimizations
- Location caching to reduce API calls
- Static service instances (singleton pattern)
- Local data caching in SharedPreferences
- Lazy loading of screens

### Recommendations
- Implement image caching
- Add pagination for large lists
- Use const constructors where possible
- Implement code splitting
- Add performance monitoring

---

## Testing Strategy

### Current Status
- No test files detected

### Recommended Tests
- **Unit Tests:** Service methods, utility functions
- **Widget Tests:** UI components
- **Integration Tests:** User flows (booking, authentication)
- **E2E Tests:** Complete user journeys

---

## Deployment

### Build Targets
- **Android:** APK/AAB via `flutter build apk/appbundle`
- **Windows:** Executable via `flutter build windows`
- **Web:** Static files via `flutter build web`

### Environment Configuration
- `.env` file for environment variables
- Separate configs for dev/staging/production

---

## Future Enhancements

### Planned Features
- Real-time provider tracking
- Video consultations
- Prescription delivery
- Follow-up scheduling
- Multi-language support (i18n)
- Offline mode support

### Architecture Improvements
- Implement proper state management
- Add dependency injection
- Implement repository pattern explicitly
- Add error handling middleware
- Implement logging system

---

## Documentation

### Related Documents
- `DOCUMENTATION.md` - Feature documentation
- `HOME_VISIT_FEATURES.md` - Home visit feature details
- `APPOINTMENT_STRUCTURE.md` - Appointment model documentation
- `DOCTOR_STRUCTURE.md` - Doctor model documentation

---

**Last Updated:** February 13, 2026
**Version:** 1.0.0
**Maintainer:** Development Team
