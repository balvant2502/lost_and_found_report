class AppConstants {
  static const String appName = 'CampusFound';

  // Categories specified for CampusFound
  static const String categoryElectronics = 'Electronics';
  static const String categoryBooks = 'Books';
  static const String categoryAccessories = 'Accessories';
  static const String categoryIdCards = 'ID Cards';
  static const String categoryOther = 'Other';

  static const List<String> categories = [
    categoryElectronics,
    categoryBooks,
    categoryAccessories,
    categoryIdCards,
    categoryOther,
  ];

  // Maximum local image size (10 MB in bytes)
  static const int maxImageSizeBytes = 10 * 1024 * 1024;

  // Firestore collections
  static const String collectionUsers = 'users';
  static const String collectionItems = 'items';
  static const String collectionChats = 'chats';
  static const String subcollectionMessages = 'messages';

  // Sample universities for quick selection
  static const List<String> defaultUniversities = [
    'Darshan University, Rajkot',
    'Dharmsinh Desai University (DDU)',
    'Stanford University',
    'UC Berkeley',
    'MIT',
    'Harvard University',
    'University of Washington',
    'UT Austin',
    'NYU',
    'Georgia Tech',
    'UCLA',
    'Other University',
  ];
}
