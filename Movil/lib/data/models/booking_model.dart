import 'package:equatable/equatable.dart';
import 'space_model.dart';
import 'user_model.dart';

/// Estados posibles de una reserva
enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed;
  
  static BookingStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }
  
  String get value => name;
  
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pendiente';
      case BookingStatus.confirmed:
        return 'Confirmada';
      case BookingStatus.cancelled:
        return 'Cancelada';
      case BookingStatus.completed:
        return 'Completada';
    }
  }
}

/// Modelo de reserva (Booking)
class Booking extends Equatable {
  final String id;
  final String spaceId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final double totalPrice;
  final String? notes;
  final String? paymentMethod;
  final double? depositAmount;
  final double? remainingAmount;
  final bool? depositPaid;
  final String? transferProofUrl;
  final bool? ownerConfirmed;
  final String? ownerNotes;
  final String? rejectionReason;
  final Space? space;
  final User? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  const Booking({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    this.status = BookingStatus.pending,
    required this.totalPrice,
    this.notes,
    this.paymentMethod,
    this.depositAmount,
    this.remainingAmount,
    this.depositPaid,
    this.transferProofUrl,
    this.ownerConfirmed,
    this.ownerNotes,
    this.rejectionReason,
    this.space,
    this.user,
    this.createdAt,
    this.updatedAt,
  });
  
  /// Crea una reserva desde JSON
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] as String? ?? json['id'] as String,
      spaceId: json['spaceId'] as String,
      userId: json['userId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: BookingStatus.fromString(json['status'] as String? ?? 'pending'),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      depositAmount: (json['depositAmount'] as num?)?.toDouble(),
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble(),
      depositPaid: json['depositPaid'] as bool?,
      transferProofUrl: json['transferProofUrl'] as String?,
      ownerConfirmed: json['ownerConfirmed'] as bool?,
      ownerNotes: json['ownerNotes'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      space: json['space'] != null 
          ? Space.fromJson(json['space'] as Map<String, dynamic>) 
          : null,
      user: json['user'] != null 
          ? User.fromJson(json['user'] as Map<String, dynamic>) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }
  
  /// Convierte la reserva a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spaceId': spaceId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.value,
      'totalPrice': totalPrice,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'depositAmount': depositAmount,
      'remainingAmount': remainingAmount,
      'depositPaid': depositPaid,
      'transferProofUrl': transferProofUrl,
      'ownerConfirmed': ownerConfirmed,
      'ownerNotes': ownerNotes,
      'rejectionReason': rejectionReason,
      'space': space?.toJson(),
      'user': user?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  /// Calcula la duración de la reserva en horas
  double get durationHours {
    return endTime.difference(startTime).inMinutes / 60;
  }
  
  /// Verifica si la reserva está en el pasado
  bool get isPast => endTime.isBefore(DateTime.now());
  
  /// Verifica si la reserva está en curso
  bool get isOngoing {
    final now = DateTime.now();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }
  
  /// Verifica si la reserva está próxima (dentro de las próximas 24 horas)
  bool get isUpcoming {
    final now = DateTime.now();
    final in24Hours = now.add(const Duration(hours: 24));
    return startTime.isAfter(now) && startTime.isBefore(in24Hours);
  }
  
  /// Verifica si se puede cancelar la reserva
  bool get canCancel {
    return status == BookingStatus.pending || 
           (status == BookingStatus.confirmed && startTime.isAfter(DateTime.now()));
  }
  
  /// Copia con modificaciones
  Booking copyWith({
    String? id,
    String? spaceId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    BookingStatus? status,
    double? totalPrice,
    String? notes,
    String? paymentMethod,
    double? depositAmount,
    double? remainingAmount,
    bool? depositPaid,
    String? transferProofUrl,
    bool? ownerConfirmed,
    String? ownerNotes,
    String? rejectionReason,
    Space? space,
    User? user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      depositAmount: depositAmount ?? this.depositAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      depositPaid: depositPaid ?? this.depositPaid,
      transferProofUrl: transferProofUrl ?? this.transferProofUrl,
      ownerConfirmed: ownerConfirmed ?? this.ownerConfirmed,
      ownerNotes: ownerNotes ?? this.ownerNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      space: space ?? this.space,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, spaceId, userId, startTime, endTime, status, totalPrice,
    notes, paymentMethod, depositAmount, remainingAmount, depositPaid,
    transferProofUrl, ownerConfirmed, ownerNotes, rejectionReason,
    space, user, createdAt, updatedAt,
  ];
}

/// Datos para crear una nueva reserva
class CreateBookingData {
  final String spaceId;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  
  const CreateBookingData({
    required this.spaceId,
    required this.startTime,
    required this.endTime,
    this.notes,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'spaceId': spaceId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}
