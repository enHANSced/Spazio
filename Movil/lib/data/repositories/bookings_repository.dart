import '../api/api_client.dart';
import '../models/booking_model.dart';

/// Filtros para buscar reservas
class BookingFilters {
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? spaceId;
  
  const BookingFilters({
    this.status,
    this.startDate,
    this.endDate,
    this.spaceId,
  });
  
  Map<String, dynamic> toQueryParams() {
    return {
      if (status != null && status!.isNotEmpty) 'status': status,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (spaceId != null && spaceId!.isNotEmpty) 'spaceId': spaceId,
    };
  }
}

/// Repositorio de reservas
class BookingsRepository {
  final ApiClient _apiClient;
  
  BookingsRepository(this._apiClient);
  
  /// Crea una nueva reserva
  Future<Booking> createBooking(CreateBookingData data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/bookings',
      data: data.toJson(),
      parser: (data) => data as Map<String, dynamic>,
    );
    
    if (response.success && response.data != null) {
      return Booking.fromJson(response.data!);
    }
    
    throw ApiException(message: response.message ?? 'Error al crear reserva');
  }
  
  /// Obtiene las reservas del usuario actual
  Future<List<Booking>> getMyBookings({BookingFilters? filters}) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/bookings/my-bookings',
      queryParameters: filters?.toQueryParams(),
      parser: (data) => data as List<dynamic>,
    );
    
    if (response.success && response.data != null) {
      return response.data!
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    
    throw ApiException(message: response.message ?? 'Error al obtener reservas');
  }
  
  /// Obtiene una reserva por ID
  Future<Booking> getBookingById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/bookings/$id',
      parser: (data) => data as Map<String, dynamic>,
    );
    
    if (response.success && response.data != null) {
      return Booking.fromJson(response.data!);
    }
    
    throw ApiException(message: response.message ?? 'Reserva no encontrada');
  }
  
  /// Cancela una reserva
  Future<Booking> cancelBooking(String id, {String? reason}) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/bookings/$id/cancel',
      data: {
        if (reason != null) 'reason': reason,
      },
      parser: (data) => data as Map<String, dynamic>,
    );
    
    if (response.success && response.data != null) {
      return Booking.fromJson(response.data!);
    }
    
    throw ApiException(message: response.message ?? 'Error al cancelar reserva');
  }
  
  /// Obtiene las reservas próximas del usuario
  Future<List<Booking>> getUpcomingBookings() async {
    final now = DateTime.now();
    return getMyBookings(
      filters: BookingFilters(
        startDate: now,
        status: 'confirmed',
      ),
    );
  }
  
  /// Obtiene las reservas pasadas del usuario
  Future<List<Booking>> getPastBookings() async {
    final now = DateTime.now();
    return getMyBookings(
      filters: BookingFilters(
        endDate: now,
      ),
    );
  }
  
  /// Obtiene las reservas pendientes del usuario
  Future<List<Booking>> getPendingBookings() async {
    return getMyBookings(
      filters: const BookingFilters(status: 'pending'),
    );
  }
  
  /// Calcula el precio total de una reserva
  double calculateTotalPrice({
    required double pricePerHour,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final duration = endTime.difference(startTime);
    final hours = duration.inMinutes / 60;
    return pricePerHour * hours;
  }
  
  /// Valida los datos de una reserva antes de enviarla
  String? validateBookingData(CreateBookingData data) {
    final now = DateTime.now();
    
    // Verificar que la fecha de inicio no sea en el pasado
    if (data.startTime.isBefore(now)) {
      return 'La fecha de inicio no puede ser en el pasado';
    }
    
    // Verificar que la fecha de fin sea después de la de inicio
    if (data.endTime.isBefore(data.startTime) || 
        data.endTime.isAtSameMomentAs(data.startTime)) {
      return 'La fecha de fin debe ser posterior a la de inicio';
    }
    
    // Verificar duración mínima (30 minutos)
    final duration = data.endTime.difference(data.startTime);
    if (duration.inMinutes < 30) {
      return 'La duración mínima es de 30 minutos';
    }
    
    // Verificar duración máxima (24 horas)
    if (duration.inHours > 24) {
      return 'La duración máxima es de 24 horas';
    }
    
    return null; // Validación exitosa
  }
}
