import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../data/api/api_client.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Estado de autenticación
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Provider para el estado de autenticación
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage;
  final ApiClient _apiClient;
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;
  String? _errorMessage;
  
  AuthProvider({
    required AuthRepository authRepository,
    required FlutterSecureStorage storage,
    required ApiClient apiClient,
  })  : _authRepository = authRepository,
        _storage = storage,
        _apiClient = apiClient;
  
  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isUser => _user?.isUser ?? false;
  bool get isOwner => _user?.isOwner ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get canBook => _user?.canBook ?? false;
  
  /// Inicializa el estado de autenticación desde el almacenamiento
  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();
    
    try {
      final storedToken = await _storage.read(key: AppConstants.tokenKey);
      final storedUser = await _storage.read(key: AppConstants.userKey);
      
      if (storedToken != null && storedUser != null) {
        _token = storedToken;
        _user = User.fromJson(jsonDecode(storedUser) as Map<String, dynamic>);
        _apiClient.setAuthToken(_token);
        
        // Intentar refrescar el perfil del usuario
        try {
          _user = await _authRepository.getProfile();
          await _saveUserToStorage(_user!);
        } catch (_) {
          // Si falla, usar los datos almacenados
        }
        
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      await _clearStorage();
    }
    
    notifyListeners();
  }
  
  /// Inicia sesión con email y contraseña
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
      );
      
      _token = response.token;
      _user = response.user;
      
      await _saveTokenToStorage(_token!);
      await _saveUserToStorage(_user!);
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Registra un nuevo usuario
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      
      _token = response.token;
      _user = response.user;
      
      await _saveTokenToStorage(_token!);
      await _saveUserToStorage(_user!);
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Cierra sesión
  Future<void> logout() async {
    _authRepository.logout();
    await _clearStorage();
    
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    
    notifyListeners();
  }
  
  /// Actualiza el perfil del usuario
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    try {
      _user = await _authRepository.updateProfile(
        name: name,
        phone: phone,
        avatar: avatar,
      );
      await _saveUserToStorage(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Refresca los datos del usuario
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;
    
    try {
      _user = await _authRepository.getProfile();
      await _saveUserToStorage(_user!);
      notifyListeners();
    } catch (_) {
      // Ignorar errores de refresco
    }
  }
  
  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _user != null 
          ? AuthStatus.authenticated 
          : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
  
  // Helpers privados
  Future<void> _saveTokenToStorage(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }
  
  Future<void> _saveUserToStorage(User user) async {
    await _storage.write(
      key: AppConstants.userKey, 
      value: jsonEncode(user.toJson()),
    );
  }
  
  Future<void> _clearStorage() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }
}
