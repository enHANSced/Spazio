const { body, param, query } = require('express-validator');

/**
 * Validaciones para crear reserva
 */
const validateCreateBooking = [
  body('spaceId')
    .trim()
    .notEmpty()
    .withMessage('El ID del espacio es requerido')
    .isUUID()
    .withMessage('ID de espacio inválido'),

  body('startTime')
    .notEmpty()
    .withMessage('La hora de inicio es requerida')
    .isISO8601()
    .withMessage('Formato de fecha inválido. Use ISO 8601 (ej: 2025-11-05T10:00:00Z)')
    .toDate()
    .custom((value) => {
      if (value < new Date()) {
        throw new Error('No se pueden crear reservas en el pasado');
      }
      return true;
    }),

  body('endTime')
    .notEmpty()
    .withMessage('La hora de fin es requerida')
    .isISO8601()
    .withMessage('Formato de fecha inválido. Use ISO 8601 (ej: 2025-11-05T12:00:00Z)')
    .toDate()
    .custom((value, { req }) => {
      const startTime = new Date(req.body.startTime);
      if (value <= startTime) {
        throw new Error('La hora de fin debe ser posterior a la hora de inicio');
      }
      
      // Validar que la reserva no sea mayor a 24 horas
      const diffHours = (value - startTime) / (1000 * 60 * 60);
      if (diffHours > 24) {
        throw new Error('La reserva no puede exceder 24 horas');
      }
      
      // Validar que la reserva sea de al menos 30 minutos
      if (diffHours < 0.5) {
        throw new Error('La reserva debe ser de al menos 30 minutos');
      }
      
      return true;
    }),

  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Las notas no pueden exceder 500 caracteres')
];

/**
 * Validaciones para obtener reservas por espacio
 */
const validateGetBySpace = [
  param('spaceId')
    .trim()
    .notEmpty()
    .withMessage('El ID del espacio es requerido')
    .isUUID()
    .withMessage('ID de espacio inválido'),

  query('startDate')
    .notEmpty()
    .withMessage('La fecha de inicio es requerida')
    .isISO8601()
    .withMessage('Formato de fecha inválido para startDate')
    .toDate(),

  query('endDate')
    .notEmpty()
    .withMessage('La fecha de fin es requerida')
    .isISO8601()
    .withMessage('Formato de fecha inválido para endDate')
    .toDate()
    .custom((value, { req }) => {
      const startDate = new Date(req.query.startDate);
      if (value <= startDate) {
        throw new Error('endDate debe ser posterior a startDate');
      }
      
      // Validar que el rango no sea mayor a 6 meses
      const diffMonths = (value - startDate) / (1000 * 60 * 60 * 24 * 30);
      if (diffMonths > 6) {
        throw new Error('El rango de fechas no puede exceder 6 meses');
      }
      
      return true;
    })
];

/**
 * Validaciones para obtener mis reservas
 */
const validateGetMyBookings = [
  query('startDate')
    .optional()
    .isISO8601()
    .withMessage('Formato de fecha inválido para startDate')
    .toDate(),

  query('endDate')
    .optional()
    .isISO8601()
    .withMessage('Formato de fecha inválido para endDate')
    .toDate()
    .custom((value, { req }) => {
      if (req.query.startDate) {
        const startDate = new Date(req.query.startDate);
        if (value <= startDate) {
          throw new Error('endDate debe ser posterior a startDate');
        }
      }
      return true;
    })
];

/**
 * Validación de ID de reserva (MongoDB ObjectId)
 */
const validateBookingId = [
  param('id')
    .trim()
    .notEmpty()
    .withMessage('El ID de la reserva es requerido')
    .isMongoId()
    .withMessage('ID de reserva inválido')
];

module.exports = {
  validateCreateBooking,
  validateGetBySpace,
  validateGetMyBookings,
  validateBookingId
};
