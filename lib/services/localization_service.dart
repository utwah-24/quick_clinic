class LocalizationService {
  static String _currentLanguage = 'en';
  
  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'Medical Booking',
      'welcome': 'Welcome to Medical Booking',
      'find_hospitals': 'Find Nearby Hospitals',
      'emergency': 'Emergency',
      'my_appointments': 'My Appointments',
      'profile': 'Profile',
      'location_permission': 'Location Permission Required',
      'location_permission_desc': 'We need your location to find nearby hospitals',
      'allow_location': 'Allow Location',
      'deny': 'Deny',
      'hospitals_nearby': 'Hospitals Nearby',
      'book_appointment': 'Book Appointment',
      'emergency_call': 'Emergency Call',
      'ambulance_request': 'Request Ambulance',
      'doctor_specialties': 'Doctor Specialties',
      'general_doctor': 'General Doctor',
      'eye_doctor': 'Eye Doctor',
      'heart_doctor': 'Heart Doctor',
      'payment_method': 'Payment Method',
      'mpesa': 'M-Pesa',
      'card': 'Credit/Debit Card',
      'cash': 'Cash',
      'insurance': 'Insurance',
      'book_now': 'Book Now',
      'appointment_details': 'Appointment Details',
      'patient_name': 'Patient Name',
      'phone_number': 'Phone Number',
      'appointment_date': 'Appointment Date',
      'time_slot': 'Time Slot',
      'problem_description': 'Problem Description',
      'consultation_fee': 'Consultation Fee',
      'total_amount': 'Total Amount',
      'confirm_booking': 'Confirm Booking',
      'booking_successful': 'Booking Successful!',
      'appointment_confirmed': 'Your appointment has been confirmed',
      'doctor_not_available': 'Doctor Not Available',
      'alternative_dates': 'Alternative Dates Available',
      'language': 'Language',
      'english': 'English',
      'kiswahili': 'Kiswahili',
    },
    'sw': {
      'app_title': 'Uhifadhi wa Matibabu',
      'welcome': 'Karibu kwenye Uhifadhi wa Matibabu',
      'find_hospitals': 'Tafuta Hospitali Karibu',
      'emergency': 'Dharura',
      'my_appointments': 'Miadi Yangu',
      'profile': 'Wasifu',
      'location_permission': 'Ruhusa ya Mahali Inahitajika',
      'location_permission_desc': 'Tunahitaji mahali pako ili kupata hospitali karibu',
      'allow_location': 'Ruhusu Mahali',
      'deny': 'Kataa',
      'hospitals_nearby': 'Hospitali Karibu',
      'book_appointment': 'Weka Miadi',
      'emergency_call': 'Simu ya Dharura',
      'ambulance_request': 'Omba Ambulensi',
      'doctor_specialties': 'Utaalamu wa Madaktari',
      'general_doctor': 'Daktari wa Jumla',
      'eye_doctor': 'Daktari wa Macho',
      'heart_doctor': 'Daktari wa Moyo',
      'payment_method': 'Njia ya Malipo',
      'mpesa': 'M-Pesa',
      'card': 'Kadi ya Benki',
      'cash': 'Pesa Taslimu',
      'insurance': 'Bima',
      'book_now': 'Weka Sasa',
      'appointment_details': 'Maelezo ya Miadi',
      'patient_name': 'Jina la Mgonjwa',
      'phone_number': 'Nambari ya Simu',
      'appointment_date': 'Tarehe ya Miadi',
      'time_slot': 'Muda',
      'problem_description': 'Maelezo ya Tatizo',
      'consultation_fee': 'Ada ya Ushauri',
      'total_amount': 'Jumla ya Kiasi',
      'confirm_booking': 'Thibitisha Uhifadhi',
      'booking_successful': 'Uhifadhi Umefanikiwa!',
      'appointment_confirmed': 'Miadi yako imethibitishwa',
      'doctor_not_available': 'Daktari Hayupo',
      'alternative_dates': 'Tarehe Mbadala Zinapatikana',
      'language': 'Lugha',
      'english': 'Kiingereza',
      'kiswahili': 'Kiswahili',
    },
  };

  static String get currentLanguage => _currentLanguage;

  static void setLanguage(String languageCode) {
    if (_translations.containsKey(languageCode)) {
      _currentLanguage = languageCode;
    }
  }

  static String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  static List<String> get supportedLanguages => ['en', 'sw'];
  
  static String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'sw':
        return 'Kiswahili';
      default:
        return code;
    }
  }
}
