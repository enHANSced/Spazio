const express = require('express');
const router = express.Router();
const bookingsController = require('../controllers/bookings.controller');
const { authMiddleware } = require('../middleware/auth.middleware');
const { isOwnerOrAdmin, isVerifiedOwner } = require('../middleware/role.middleware');
const { handleValidationErrors } = require('../middleware/validation.middleware');
const {
  validateCreateBooking,
  validateGetBySpace,
  validateGetMyBookings,
  validateBookingId
} = require('../validators/bookings.validators');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Crear nueva reserva (solo users, no owners)
router.post('/', validateCreateBooking, handleValidationErrors, bookingsController.create);

// Obtener mis reservas (solo para users)
router.get('/my-bookings', validateGetMyBookings, handleValidationErrors, bookingsController.getMyBookings);

// Obtener reservas de mis espacios (solo para owners verificados)
router.get('/owner/bookings', isOwnerOrAdmin, isVerifiedOwner, bookingsController.getOwnerBookings);

// Obtener reservas por espacio (para calendario)
router.get('/space/:spaceId', validateGetBySpace, handleValidationErrors, bookingsController.getBySpace);

// Obtener reserva por ID
router.get('/:id', validateBookingId, handleValidationErrors, bookingsController.getById);

// Actualizar reserva (para pagos, reprogramación, etc.)
router.patch('/:id', validateBookingId, handleValidationErrors, bookingsController.update);

// Cancelar reserva
router.delete('/:id', validateBookingId, handleValidationErrors, bookingsController.cancel);

module.exports = router;
