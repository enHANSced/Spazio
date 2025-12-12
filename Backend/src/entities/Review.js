const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  // ID de la reserva asociada (debe estar completada)
  bookingId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'Booking',
    index: true
  },
  // ID del usuario que hace la reseña (quien reservó)
  userId: {
    type: String,
    required: true,
    index: true
  },
  // ID del propietario que recibe la reseña
  ownerId: {
    type: String,
    required: true,
    index: true
  },
  // ID del espacio reservado
  spaceId: {
    type: String,
    required: true,
    index: true
  },
  // Calificación de 1 a 5 estrellas
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  // Comentario opcional
  comment: {
    type: String,
    maxlength: 1000,
    default: ''
  },
  // Estado de la reseña
  isActive: {
    type: Boolean,
    default: true
  },
  // Respuesta del propietario (opcional)
  ownerResponse: {
    text: {
      type: String,
      maxlength: 500,
      default: null
    },
    respondedAt: {
      type: Date,
      default: null
    }
  }
}, {
  timestamps: true
});

// Índice compuesto para evitar reseñas duplicadas por reserva
reviewSchema.index({ bookingId: 1 }, { unique: true });

// Índice para buscar reseñas por propietario ordenadas por fecha
reviewSchema.index({ ownerId: 1, createdAt: -1 });

// Índice para buscar reseñas por espacio
reviewSchema.index({ spaceId: 1, createdAt: -1 });

// Método estático para obtener estadísticas de un propietario
reviewSchema.statics.getOwnerStats = async function(ownerId) {
  const stats = await this.aggregate([
    { 
      $match: { 
        ownerId, 
        isActive: true 
      } 
    },
    {
      $group: {
        _id: null,
        totalReviews: { $sum: 1 },
        averageRating: { $avg: '$rating' },
        ratings: {
          $push: '$rating'
        }
      }
    },
    {
      $project: {
        _id: 0,
        totalReviews: 1,
        averageRating: { $round: ['$averageRating', 1] },
        ratingDistribution: {
          $reduce: {
            input: [1, 2, 3, 4, 5],
            initialValue: {},
            in: {
              $mergeObjects: [
                '$$value',
                {
                  $arrayToObject: [[{
                    k: { $toString: '$$this' },
                    v: {
                      $size: {
                        $filter: {
                          input: '$ratings',
                          as: 'r',
                          cond: { $eq: ['$$r', '$$this'] }
                        }
                      }
                    }
                  }]]
                }
              ]
            }
          }
        }
      }
    }
  ]);

  if (stats.length === 0) {
    return {
      totalReviews: 0,
      averageRating: 0,
      ratingDistribution: { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 }
    };
  }

  return stats[0];
};

// Método estático para obtener estadísticas de un espacio
reviewSchema.statics.getSpaceStats = async function(spaceId) {
  const stats = await this.aggregate([
    { 
      $match: { 
        spaceId, 
        isActive: true 
      } 
    },
    {
      $group: {
        _id: null,
        totalReviews: { $sum: 1 },
        averageRating: { $avg: '$rating' }
      }
    },
    {
      $project: {
        _id: 0,
        totalReviews: 1,
        averageRating: { $round: ['$averageRating', 1] }
      }
    }
  ]);

  if (stats.length === 0) {
    return {
      totalReviews: 0,
      averageRating: 0
    };
  }

  return stats[0];
};

// Verificar que el usuario puede crear una reseña (reserva completada y sin reseña previa)
reviewSchema.statics.canReview = async function(bookingId, userId) {
  const Booking = mongoose.model('Booking');
  
  // Verificar que la reserva existe y está completada
  const booking = await Booking.findById(bookingId);
  if (!booking) {
    return { canReview: false, reason: 'Reserva no encontrada' };
  }
  
  if (booking.userId !== userId) {
    return { canReview: false, reason: 'No autorizado para reseñar esta reserva' };
  }
  
  if (booking.status !== 'confirmed') {
    return { canReview: false, reason: 'Solo se pueden reseñar reservas confirmadas' };
  }
  
  // Verificar que la reserva ya terminó
  if (new Date(booking.endTime) > new Date()) {
    return { canReview: false, reason: 'La reserva aún no ha terminado' };
  }
  
  // Verificar que no existe una reseña previa
  const existingReview = await this.findOne({ bookingId });
  if (existingReview) {
    return { canReview: false, reason: 'Ya existe una reseña para esta reserva' };
  }
  
  return { canReview: true, booking };
};

const Review = mongoose.model('Review', reviewSchema);

module.exports = Review;
