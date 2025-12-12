import 'package:flutter/foundation.dart';
import '../../data/api/api_client.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/bookings_repository.dart';

/// Estado de carga de reservas
enum BookingsStatus {
  initial,
  loading,
  loaded,
  creating,
  created,
  error,
}

/// Provider para el estado de reservas
class BookingsProvider extends ChangeNotifier {
  final BookingsRepository _bookingsRepository;
  
  BookingsStatus _status = BookingsStatus.initial;
  List<Booking> _bookings = [];
  Booking? _selectedBooking;
  Booking? _lastCreatedBooking;
  String? _errorMessage;
  BookingFilters? _currentFilters;
  
  BookingsProvider({
    required BookingsRepository bookingsRepository,
  }) : _bookingsRepository = bookingsRepository;
  
  // Getters
  BookingsStatus get status => _status;
  List<Booking> get bookings => _bookings;
  Booking? get selectedBooking => _selectedBooking;
  Booking? get lastCreatedBooking => _lastCreatedBooking;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == BookingsStatus.loading;
  bool get isCreating => _status == BookingsStatus.creating;
  bool get hasError => _status == BookingsStatus.error;
  
  /// Carga las reservas del usuario
  Future<void> loadMyBookings({BookingFilters? filters}) async {
    _status = BookingsStatus.loading;
    _errorMessage = null;
    _currentFilters = filters;
    notifyListeners();
    
    try {
      _bookings = await _bookingsRepository.getMyBookings(filters: filters);
      _status = BookingsStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = BookingsStatus.error;
    } catch (e) {
      _errorMessage = 'Error al cargar reservas';
      _status = BookingsStatus.error;
    }
    
    notifyListeners();
  }
  
  /// Recarga las reservas con los filtros actuales
  Future<void> refreshBookings() async {
    await loadMyBookings(filters: _currentFilters);
  }
  
  /// Crea una nueva reserva
  Future<bool> createBooking(CreateBookingData data) async {
    // Validar datos antes de enviar
    final validationError = _bookingsRepository.validateBookingData(data);
    if (validationError != null) {
      _errorMessage = validationError;
      _status = BookingsStatus.error;
      notifyListeners();
      return false;
    }
    
    _status = BookingsStatus.creating;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _lastCreatedBooking = await _bookingsRepository.createBooking(data);
      _bookings.insert(0, _lastCreatedBooking!);
      _status = BookingsStatus.created;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = BookingsStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al crear reserva';
      _status = BookingsStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Carga una reserva por ID
  Future<void> loadBookingById(String id) async {
    _status = BookingsStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _selectedBooking = await _bookingsRepository.getBookingById(id);
      _status = BookingsStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = BookingsStatus.error;
    } catch (e) {
      _errorMessage = 'Error al cargar reserva';
      _status = BookingsStatus.error;
    }
    
    notifyListeners();
  }
  
  /// Cancela una reserva
  Future<bool> cancelBooking(String id, {String? reason}) async {
    _status = BookingsStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final cancelledBooking = await _bookingsRepository.cancelBooking(
        id,
        reason: reason,
      );
      
      // Actualizar en la lista
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index >= 0) {
        _bookings[index] = cancelledBooking;
      }
      
      // Actualizar si es la seleccionada
      if (_selectedBooking?.id == id) {
        _selectedBooking = cancelledBooking;
      }
      
      _status = BookingsStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = BookingsStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al cancelar reserva';
      _status = BookingsStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Filtra reservas por estado
  Future<void> filterByStatus(String? status) async {
    final filters = BookingFilters(
      status: status,
      startDate: _currentFilters?.startDate,
      endDate: _currentFilters?.endDate,
    );
    await loadMyBookings(filters: filters);
  }
  
  /// Selecciona una reserva de la lista local
  void selectBooking(Booking booking) {
    _selectedBooking = booking;
    notifyListeners();
  }
  
  /// Limpia la reserva seleccionada
  void clearSelectedBooking() {
    _selectedBooking = null;
    notifyListeners();
  }
  
  /// Limpia la última reserva creada
  void clearLastCreatedBooking() {
    _lastCreatedBooking = null;
    notifyListeners();
  }
  
  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    if (_status == BookingsStatus.error) {
      _status = _bookings.isNotEmpty 
          ? BookingsStatus.loaded 
          : BookingsStatus.initial;
    }
    notifyListeners();
  }
  
  /// Reinicia el estado a loaded después de crear
  void resetStatus() {
    if (_status == BookingsStatus.created) {
      _status = BookingsStatus.loaded;
      notifyListeners();
    }
  }
  
  /// Calcula el precio total de una reserva
  double calculateTotalPrice({
    required double pricePerHour,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return _bookingsRepository.calculateTotalPrice(
      pricePerHour: pricePerHour,
      startTime: startTime,
      endTime: endTime,
    );
  }
  
  // Reservas filtradas localmente
  
  /// Reservas próximas (futuras confirmadas o pendientes)
  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    return _bookings
        .where((b) => 
            b.startTime.isAfter(now) && 
            (b.status == BookingStatus.confirmed || b.status == BookingStatus.pending))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  /// Reservas pasadas
  List<Booking> get pastBookings {
    final now = DateTime.now();
    return _bookings
        .where((b) => b.endTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Más recientes primero
  }
  
  /// Reservas pendientes
  List<Booking> get pendingBookings {
    return _bookings
        .where((b) => b.status == BookingStatus.pending)
        .toList();
  }
  
  /// Reservas confirmadas
  List<Booking> get confirmedBookings {
    return _bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .toList();
  }
  
  /// Reservas canceladas
  List<Booking> get cancelledBookings {
    return _bookings
        .where((b) => b.status == BookingStatus.cancelled)
        .toList();
  }
}
