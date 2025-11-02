const express = require('express');
const router = express.Router();
const bookingsController = require('../controllers/bookings.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Crear nueva reserva
router.post('/', bookingsController.create);

// Obtener mis reservas
router.get('/my-bookings', bookingsController.getMyBookings);

// Obtener reservas por espacio (para calendario)
router.get('/space/:spaceId', bookingsController.getBySpace);

// Obtener reserva por ID
router.get('/:id', bookingsController.getById);

// Cancelar reserva
router.delete('/:id', bookingsController.cancel);

module.exports = router;
