const express = require('express');
const router = express.Router();
const bookingsController = require('../controllers/bookings.controller');
const { authMiddleware } = require('../middleware/auth.middleware');
const { handleValidationErrors } = require('../middleware/validation.middleware');
const {
  validateCreateBooking,
  validateGetBySpace,
  validateGetMyBookings,
  validateBookingId
} = require('../validators/bookings.validators');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Crear nueva reserva
router.post('/', validateCreateBooking, handleValidationErrors, bookingsController.create);

// Obtener mis reservas
router.get('/my-bookings', validateGetMyBookings, handleValidationErrors, bookingsController.getMyBookings);

// Obtener reservas por espacio (para calendario)
router.get('/space/:spaceId', validateGetBySpace, handleValidationErrors, bookingsController.getBySpace);

// Obtener reserva por ID
router.get('/:id', validateBookingId, handleValidationErrors, bookingsController.getById);

// Cancelar reserva
router.delete('/:id', validateBookingId, handleValidationErrors, bookingsController.cancel);

module.exports = router;
