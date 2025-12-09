import 'package:flutter/foundation.dart';
import '../../data/api/api_client.dart';
import '../../data/models/space_model.dart';
import '../../data/repositories/spaces_repository.dart';

/// Estado de carga de espacios
enum SpacesStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Provider para el estado de espacios
class SpacesProvider extends ChangeNotifier {
  final SpacesRepository _spacesRepository;
  
  SpacesStatus _status = SpacesStatus.initial;
  List<Space> _spaces = [];
  Space? _selectedSpace;
  String? _errorMessage;
  SpaceFilters? _currentFilters;
  
  SpacesProvider({
    required SpacesRepository spacesRepository,
  }) : _spacesRepository = spacesRepository;
  
  // Getters
  SpacesStatus get status => _status;
  List<Space> get spaces => _spaces;
  Space? get selectedSpace => _selectedSpace;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == SpacesStatus.loading;
  bool get hasError => _status == SpacesStatus.error;
  
  /// Carga la lista de espacios
  Future<void> loadSpaces({SpaceFilters? filters}) async {
    _status = SpacesStatus.loading;
    _errorMessage = null;
    _currentFilters = filters;
    notifyListeners();
    
    try {
      _spaces = await _spacesRepository.getSpaces(filters: filters);
      _status = SpacesStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = SpacesStatus.error;
    } catch (e) {
      _errorMessage = 'Error al cargar espacios';
      _status = SpacesStatus.error;
    }
    
    notifyListeners();
  }
  
  /// Recarga los espacios con los filtros actuales
  Future<void> refreshSpaces() async {
    await loadSpaces(filters: _currentFilters);
  }
  
  /// Carga un espacio por ID
  Future<void> loadSpaceById(String id) async {
    _status = SpacesStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _selectedSpace = await _spacesRepository.getSpaceById(id);
      _status = SpacesStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = SpacesStatus.error;
    } catch (e) {
      _errorMessage = 'Error al cargar espacio';
      _status = SpacesStatus.error;
    }
    
    notifyListeners();
  }
  
  /// Busca espacios por término de búsqueda
  Future<void> searchSpaces(String query) async {
    if (query.isEmpty) {
      await loadSpaces();
      return;
    }
    
    await loadSpaces(filters: SpaceFilters(search: query));
  }
  
  /// Filtra espacios por ciudad
  Future<void> filterByCity(String? city) async {
    final filters = SpaceFilters(
      city: city,
      category: _currentFilters?.category,
      minCapacity: _currentFilters?.minCapacity,
      maxCapacity: _currentFilters?.maxCapacity,
      minPrice: _currentFilters?.minPrice,
      maxPrice: _currentFilters?.maxPrice,
    );
    await loadSpaces(filters: filters);
  }
  
  /// Filtra espacios por categoría
  Future<void> filterByCategory(String? category) async {
    final filters = SpaceFilters(
      city: _currentFilters?.city,
      category: category,
      minCapacity: _currentFilters?.minCapacity,
      maxCapacity: _currentFilters?.maxCapacity,
      minPrice: _currentFilters?.minPrice,
      maxPrice: _currentFilters?.maxPrice,
    );
    await loadSpaces(filters: filters);
  }
  
  /// Aplica múltiples filtros
  Future<void> applyFilters(SpaceFilters filters) async {
    await loadSpaces(filters: filters);
  }
  
  /// Limpia todos los filtros
  Future<void> clearFilters() async {
    _currentFilters = null;
    await loadSpaces();
  }
  
  /// Selecciona un espacio de la lista local
  void selectSpace(Space space) {
    _selectedSpace = space;
    notifyListeners();
  }
  
  /// Limpia el espacio seleccionado
  void clearSelectedSpace() {
    _selectedSpace = null;
    notifyListeners();
  }
  
  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    if (_status == SpacesStatus.error) {
      _status = _spaces.isNotEmpty 
          ? SpacesStatus.loaded 
          : SpacesStatus.initial;
    }
    notifyListeners();
  }
  
  /// Obtiene espacios destacados (primeros 6)
  List<Space> get featuredSpaces => _spaces.take(6).toList();
  
  /// Obtiene espacios por categoría (de la lista local)
  List<Space> getSpacesByCategory(String category) {
    return _spaces.where((s) => s.category == category).toList();
  }
  
  /// Obtiene categorías únicas de los espacios cargados
  List<String> get categories {
    return _spaces
        .where((s) => s.category != null)
        .map((s) => s.category!)
        .toSet()
        .toList();
  }
  
  /// Obtiene ciudades únicas de los espacios cargados
  List<String> get cities {
    return _spaces
        .where((s) => s.city != null)
        .map((s) => s.city!)
        .toSet()
        .toList();
  }
}
