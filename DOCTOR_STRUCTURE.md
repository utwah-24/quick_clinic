### Doctor Model Structure

This documents the `Doctor` data model used in the app.

#### Fields

```text
id                : String        // Unique identifier
name              : String        // Doctor's full name
specialty         : String        // Primary specialty (e.g., Cardiology)
qualification     : String        // Qualifications/degree(s)
experience        : int           // Years of experience
rating            : double        // Average rating (e.g., 4.7)
imageUrl          : String        // URL to profile image
availableDays     : List<String>  // Days available (e.g., ["Mon","Tue"])
availableTime     : String        // Time window (e.g., "09:00 - 17:00")
consultationFee   : double        // Fee amount
bio               : String        // Short biography/summary
languages         : List<String>  // Languages spoken (e.g., ["English","Swahili"]) 
```

#### Dart Class (reference)

```dart
class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String qualification;
  final int experience;
  final double rating;
  final String imageUrl;
  final List<String> availableDays;
  final String availableTime;
  final double consultationFee;
  final String bio;
  final List<String> languages;
}
```

#### Example JSON

```json
{
  "id": "doc_123",
  "name": "Dr. Jane Doe",
  "specialty": "Cardiology",
  "qualification": "MBChB, MMed (Cardiology)",
  "experience": 12,
  "rating": 4.8,
  "imageUrl": "https://example.com/images/jane.jpg",
  "availableDays": ["Mon", "Wed", "Fri"],
  "availableTime": "09:00 - 16:00",
  "consultationFee": 3500.0,
  "bio": "Cardiologist with a focus on preventive care and patient education.",
  "languages": ["English", "Swahili"]
}
```

Notes:
- **experience** is an integer (years).
- **rating** and **consultationFee** are doubles.
- **availableDays** and **languages** are arrays of strings.

