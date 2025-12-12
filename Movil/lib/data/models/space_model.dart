import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// Modelo de espacio (Space)
class Space extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final int capacity;
  final double pricePerHour;
  final String? category;
  final List<String> amenities;
  final List<SpaceMedia> media;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final String? ownerId;
  final User? owner;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  const Space({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    required this.capacity,
    required this.pricePerHour,
    this.category,
    this.amenities = const [],
    this.media = const [],
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.ownerId,
    this.owner,
    this.createdAt,
    this.updatedAt,
  });
  
  /// Crea un espacio desde JSON
  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      capacity: json['capacity'] as int? ?? 0,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String?,
      amenities: _parseAmenities(json['amenities']),
      media: _parseMedia(json['media']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      ownerId: json['ownerId'] as String?,
      owner: json['owner'] != null 
          ? User.fromJson(json['owner'] as Map<String, dynamic>) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }
  
  /// Parsea las amenities desde diferentes formatos
  static List<String> _parseAmenities(dynamic amenities) {
    if (amenities == null) return [];
    if (amenities is List) {
      return amenities.map((e) => e.toString()).toList();
    }
    if (amenities is String) {
      try {
        // Intentar parsear como JSON
        return [];
      } catch (_) {
        return amenities.split(',').map((e) => e.trim()).toList();
      }
    }
    return [];
  }
  
  /// Parsea los media desde diferentes formatos
  static List<SpaceMedia> _parseMedia(dynamic media) {
    if (media == null) return [];
    if (media is List) {
      return media.map((e) {
        if (e is Map<String, dynamic>) {
          return SpaceMedia.fromJson(e);
        }
        // Si es solo una URL string
        return SpaceMedia(url: e.toString(), type: 'image');
      }).toList();
    }
    return [];
  }
  
  /// Convierte el espacio a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'capacity': capacity,
      'pricePerHour': pricePerHour,
      'category': category,
      'amenities': amenities,
      'media': media.map((m) => m.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'ownerId': ownerId,
      'owner': owner?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  /// Obtiene la imagen principal del espacio
  String? get mainImage {
    if (media.isEmpty) return null;
    final mainMedia = media.firstWhere(
      (m) => m.isMain, 
      orElse: () => media.first,
    );
    return mainMedia.url;
  }
  
  /// Obtiene todas las imágenes del espacio
  List<String> get images {
    return media
        .where((m) => m.type == 'image')
        .map((m) => m.url)
        .toList();
  }
  
  /// Verifica si el espacio tiene ubicación
  bool get hasLocation => latitude != null && longitude != null;
  
  /// Copia con modificaciones
  Space copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? city,
    int? capacity,
    double? pricePerHour,
    String? category,
    List<String>? amenities,
    List<SpaceMedia>? media,
    double? latitude,
    double? longitude,
    bool? isActive,
    String? ownerId,
    User? owner,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Space(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      capacity: capacity ?? this.capacity,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      category: category ?? this.category,
      amenities: amenities ?? this.amenities,
      media: media ?? this.media,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, name, description, address, city, capacity, pricePerHour,
    category, amenities, media, latitude, longitude, isActive,
    ownerId, owner, createdAt, updatedAt,
  ];
}

/// Modelo de media de espacio
class SpaceMedia extends Equatable {
  final String url;
  final String type;
  final String? caption;
  final bool isMain;
  final int? order;
  
  const SpaceMedia({
    required this.url,
    required this.type,
    this.caption,
    this.isMain = false,
    this.order,
  });
  
  factory SpaceMedia.fromJson(Map<String, dynamic> json) {
    return SpaceMedia(
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? 'image',
      caption: json['caption'] as String?,
      isMain: json['isMain'] as bool? ?? false,
      order: json['order'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'caption': caption,
      'isMain': isMain,
      'order': order,
    };
  }
  
  @override
  List<Object?> get props => [url, type, caption, isMain, order];
}
