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
