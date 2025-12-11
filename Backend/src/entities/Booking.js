const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  spaceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: String,
    required: true,
    index: true
  },
  startTime: {
    type: Date,
    required: true,
    index: true
  },
  endTime: {
    type: Date,
    required: true,
    index: true
  },
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'cancelled'],
    default: 'confirmed',
    index: true
  },
  notes: {
    type: String,
    maxlength: 500
  },
  // Campos de pago
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'transfer', 'pending'],
    default: 'pending'
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'refunded'],
    default: 'pending'
  },
  totalAmount: {
    type: Number,
    min: 0
  },
  subtotal: {
    type: Number,
    min: 0
  },
  serviceFee: {
    type: Number,
    min: 0
  },
  pricePerHour: {
    type: Number,
    min: 0
  },
  durationHours: {
    type: Number,
    min: 0.5,
    max: 24
  },
  paidAt: {
    type: Date
  },
  // Campos específicos para transferencia
  transferProofUrl: {
    type: String,
    default: null
  },
  transferProofUploadedAt: {
    type: Date,
    default: null
  },
  transferVerifiedAt: {
    type: Date,
    default: null
  },
  transferVerifiedBy: {
    type: String,
    default: null
  },
  transferRejectedAt: {
    type: Date,
    default: null
  },
  transferRejectionReason: {
    type: String,
    default: null
  },
  // Campos para confirmación/rechazo de reserva por owner
  confirmedAt: {
    type: Date,
    default: null
  },
  confirmedBy: {
    type: String,
    default: null
  },
  rejectedAt: {
    type: Date,
    default: null
  },
  rejectedBy: {
    type: String,
    default: null
  },
  rejectionReason: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

// Índice compuesto para queries de disponibilidad
bookingSchema.index({ spaceId: 1, startTime: 1, endTime: 1, status: 1 });

// Validación: endTime debe ser después de startTime
bookingSchema.pre('save', function(next) {
  if (this.endTime <= this.startTime) {
    next(new Error('La hora de fin debe ser posterior a la hora de inicio'));
  }
  next();
});

// Método para verificar si dos reservas se solapan
bookingSchema.statics.checkOverlap = function(spaceId, startTime, endTime, excludeId = null) {
  const query = {
    spaceId,
    status: { $ne: 'cancelled' },
    $or: [
      // Nueva reserva empieza durante una existente
      { startTime: { $lte: startTime }, endTime: { $gt: startTime } },
      // Nueva reserva termina durante una existente
      { startTime: { $lt: endTime }, endTime: { $gte: endTime } },
      // Nueva reserva contiene completamente una existente
      { startTime: { $gte: startTime }, endTime: { $lte: endTime } }
    ]
  };

  if (excludeId) {
    query._id = { $ne: excludeId };
  }

  return this.findOne(query);
};

const Booking = mongoose.model('Booking', bookingSchema);

module.exports = Booking;
