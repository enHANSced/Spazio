import '../api/api_client.dart';
import '../models/space_model.dart';

/// Filtros para buscar espacios
class SpaceFilters {
  final String? search;
  final String? city;
  final String? category;
  final int? minCapacity;
  final int? maxCapacity;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? amenities;
  
  const SpaceFilters({
    this.search,
    this.city,
    this.category,
    this.minCapacity,
    this.maxCapacity,
    this.minPrice,
    this.maxPrice,
    this.amenities,
  });
  
  Map<String, dynamic> toQueryParams() {
    return {
      if (search != null && search!.isNotEmpty) 'search': search,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (minCapacity != null) 'minCapacity': minCapacity.toString(),
      if (maxCapacity != null) 'maxCapacity': maxCapacity.toString(),
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (amenities != null && amenities!.isNotEmpty) 
        'amenities': amenities!.join(','),
    };
  }
}

/// Repositorio de espacios
class SpacesRepository {
  final ApiClient _apiClient;
  
  SpacesRepository(this._apiClient);
  
  /// Obtiene la lista de espacios disponibles (público)
  Future<List<Space>> getSpaces({SpaceFilters? filters}) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/spaces',
      queryParameters: filters?.toQueryParams(),
      parser: (data) => data as List<dynamic>,
    );
    
    if (response.success && response.data != null) {
      return response.data!
          .map((json) => Space.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    
    throw ApiException(message: response.message ?? 'Error al obtener espacios');
  }
  
  /// Obtiene un espacio por ID (público)
  Future<Space> getSpaceById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/spaces/$id',
      parser: (data) => data as Map<String, dynamic>,
    );
    
    if (response.success && response.data != null) {
      return Space.fromJson(response.data!);
    }
    
    throw ApiException(message: response.message ?? 'Espacio no encontrado');
  }
  
  /// Busca espacios por término de búsqueda
  Future<List<Space>> searchSpaces(String query) async {
    return getSpaces(filters: SpaceFilters(search: query));
  }
  
  /// Obtiene espacios por ciudad
  Future<List<Space>> getSpacesByCity(String city) async {
    return getSpaces(filters: SpaceFilters(city: city));
  }
  
  /// Obtiene espacios por categoría
  Future<List<Space>> getSpacesByCategory(String category) async {
    return getSpaces(filters: SpaceFilters(category: category));
  }
  
  /// Obtiene las ciudades disponibles
  Future<List<String>> getCities() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/spaces/cities',
      parser: (data) => data as List<dynamic>,
    );
    
    if (response.success && response.data != null) {
      return response.data!.map((e) => e.toString()).toList();
    }
    
    // Si no hay endpoint específico, obtener de los espacios
    final spaces = await getSpaces();
    final cities = spaces
        .where((s) => s.city != null)
        .map((s) => s.city!)
        .toSet()
        .toList();
    return cities;
  }
  
  /// Obtiene las categorías disponibles
  Future<List<String>> getCategories() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/spaces/categories',
      parser: (data) => data as List<dynamic>,
    );
    
    if (response.success && response.data != null) {
      return response.data!.map((e) => e.toString()).toList();
    }
    
    // Si no hay endpoint específico, obtener de los espacios
    final spaces = await getSpaces();
    final categories = spaces
        .where((s) => s.category != null)
        .map((s) => s.category!)
        .toSet()
        .toList();
    return categories;
  }
  
  /// Verifica la disponibilidad de un espacio en un rango de fechas
  Future<bool> checkAvailability({
    required String spaceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/spaces/$spaceId/availability',
        queryParameters: {
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        },
        parser: (data) => data as Map<String, dynamic>,
      );
      
      if (response.success && response.data != null) {
        return response.data!['available'] as bool? ?? false;
      }
      
      return false;
    } catch (e) {
      // Si no existe el endpoint, asumir que está disponible
      // La validación real se hará al crear la reserva
      return true;
    }
  }
}
