/// Constantes de la aplicación
class AppConstants {
  AppConstants._();
  
  // App info
  static const String appName = 'Spazio';
  static const String appVersion = '1.0.0';
  
  // API
  static const String apiBaseUrl = 'http://10.0.2.2:3001/api'; // Android emulator localhost
  static const String apiBaseUrlPhysical = 'http://192.168.1.100:3001/api'; // For physical device - update IP
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage keys
  static const String tokenKey = 'spazio_token';
  static const String userKey = 'spazio_user';
  static const String onboardingKey = 'spazio_onboarding_complete';
  
  // Booking constraints
  static const int minBookingDurationMinutes = 30;
  static const int maxBookingDurationHours = 24;
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Image placeholders
  static const String placeholderImage = 'assets/images/placeholder.png';
  static const String avatarPlaceholder = 'assets/images/avatar_placeholder.png';
  
  // Roles
  static const String roleUser = 'user';
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';
  
  // Booking status
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusCancelled = 'cancelled';
  static const String statusCompleted = 'completed';
}
