import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';

/// Respuesta genérica de la API
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? errors;
  
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
  });
  
  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }
  
  factory ApiResponse.error(String message, {Map<String, dynamic>? errors}) {
    return ApiResponse(
      success: false,
      message: message,
      errors: errors,
    );
  }
}

/// Excepción de API personalizada
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  
  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });
  
  @override
  String toString() => message;
}

/// Cliente HTTP para comunicación con el backend
class ApiClient {
  late final Dio _dio;
  String? _authToken;
  
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Interceptor para logging en debug
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
    
    // Interceptor para agregar token de autenticación
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Manejar errores de autenticación
          if (error.response?.statusCode == 401) {
            // Token inválido o expirado
            _authToken = null;
          }
          return handler.next(error);
        },
      ),
    );
  }
  
  /// Establece el token de autenticación
  void setAuthToken(String? token) {
    _authToken = token;
  }
  
  /// Obtiene el token actual
  String? get authToken => _authToken;
  
  /// Verifica si hay token de autenticación
  bool get hasAuthToken => _authToken != null && _authToken!.isNotEmpty;
  
  /// Realiza una petición GET
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, parser);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Realiza una petición POST
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, parser);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Realiza una petición PUT
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, parser);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Realiza una petición PATCH
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, parser);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Realiza una petición DELETE
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, parser);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Maneja la respuesta de la API
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? parser,
  ) {
    final data = response.data;
    
    if (data is Map<String, dynamic>) {
      final success = data['success'] as bool? ?? true;
      final message = data['message'] as String?;
      final responseData = data['data'];
      
      if (success) {
        final parsedData = parser != null && responseData != null
            ? parser(responseData)
            : responseData as T?;
        return ApiResponse.success(parsedData as T, message: message);
      } else {
        final errors = data['errors'] as Map<String, dynamic>?;
        throw ApiException(
          message: message ?? 'Error desconocido',
          statusCode: response.statusCode,
          errors: errors,
        );
      }
    }
    
    // Si la respuesta no es un mapa, intentar parsearla directamente
    final parsedData = parser != null ? parser(data) : data as T?;
    return ApiResponse.success(parsedData as T);
  }
  
  /// Maneja los errores de Dio
  ApiException _handleError(DioException error) {
    String message;
    int? statusCode = error.response?.statusCode;
    Map<String, dynamic>? errors;
    
    // Intentar extraer mensaje de la respuesta
    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      message = data['message'] as String? ?? _getErrorMessage(error);
      errors = data['errors'] as Map<String, dynamic>?;
    } else {
      message = _getErrorMessage(error);
    }
    
    return ApiException(
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
  
  /// Obtiene un mensaje de error legible
  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de respuesta agotado';
      case DioExceptionType.badCertificate:
        return 'Certificado inválido';
      case DioExceptionType.badResponse:
        return _getHttpErrorMessage(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Petición cancelada';
      case DioExceptionType.connectionError:
        return 'Error de conexión. Verifica tu conexión a internet.';
      case DioExceptionType.unknown:
        return 'Error de conexión desconocido';
    }
  }
  
  /// Obtiene mensaje de error según código HTTP
  String _getHttpErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Solicitud inválida';
      case 401:
        return 'No autorizado. Por favor inicia sesión nuevamente.';
      case 403:
        return 'No tienes permiso para realizar esta acción';
      case 404:
        return 'Recurso no encontrado';
      case 409:
        return 'Conflicto. El recurso ya existe o hay un conflicto de horarios.';
      case 422:
        return 'Datos de entrada inválidos';
      case 500:
        return 'Error interno del servidor';
      case 502:
        return 'Error de gateway';
      case 503:
        return 'Servicio no disponible';
      default:
        return 'Error del servidor ($statusCode)';
    }
  }
}
