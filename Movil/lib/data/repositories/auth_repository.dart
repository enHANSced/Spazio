import '../api/api_client.dart';
import '../models/user_model.dart';

/// Datos de respuesta del login
class AuthResponse {
  final String token;
  final User user;
  
  const AuthResponse({
    required this.token,
    required this.user,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Repositorio de autenticación
class AuthRepository {
  final ApiClient _apiClient;
  
  AuthRepository(this._apiClient);
  
  /// Inicia sesión con email y contraseña
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      parser: (data) => data as Map<String, dynamic>,
    );
    
    if (response.success && response.data != null) {
      final authResponse = AuthResponse.fromJson(response.data!);
      _apiClient.setAuthToken(authResponse.token);
      return authResponse;
    }
    
    throw ApiException(message: response.message ?? 'Error de autenticación');
  }
  
  /// Registra un nuevo usuario
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
      },
      parser: (data) => data as Map<String, dynamic>,
    );
    
    if (response.success && response.data != null) {
      final authResponse = AuthResponse.fromJson(response.data!);
      _apiClient.setAuthToken(authResponse.token);
      return authResponse;
    }
    
    throw ApiException(message: response.message ?? 'Error de registro');
  }
  
  /// Obtiene el perfil del usuario actual
  Future<User> getProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/auth/profile',
      parser: (data) => data as Map<String, dynamic>,
    );
    
    if (response.success && response.data != null) {
      return User.fromJson(response.data!);
    }
    
    throw ApiException(message: response.message ?? 'Error al obtener perfil');
  }
  
  /// Actualiza el perfil del usuario
  Future<User> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/auth/profile',
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (avatar != null) 'avatar': avatar,
      },
      parser: (data) => data as Map<String, dynamic>,
    );
    
    if (response.success && response.data != null) {
      return User.fromJson(response.data!);
    }
    
    throw ApiException(message: response.message ?? 'Error al actualizar perfil');
  }
  
  /// Cambia la contraseña del usuario
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.put<void>(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    
    if (!response.success) {
      throw ApiException(message: response.message ?? 'Error al cambiar contraseña');
    }
  }
  
  /// Cierra la sesión (limpia el token local)
  void logout() {
    _apiClient.setAuthToken(null);
  }
}
