const express = require('express');
const router = express.Router();
const multer = require('multer');
const bookingsController = require('../controllers/bookings.controller');
const { authMiddleware, isAdmin } = require('../middleware/auth.middleware');
const { isOwnerOrAdmin, isVerifiedOwner } = require('../middleware/role.middleware');
const { handleValidationErrors } = require('../middleware/validation.middleware');
const {
  validateCreateBooking,
  validateGetBySpace,
  validateGetMyBookings,
  validateBookingId
} = require('../validators/bookings.validators');

// Configurar multer para recibir imágenes en memoria
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB máximo
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Solo se permiten imágenes'), false);
    }
  }
});

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Rutas admin - Deben ir antes de rutas con parámetros
router.get('/admin/all', isAdmin, bookingsController.getAllBookings);
router.get('/admin/stats', isAdmin, bookingsController.getStats);
router.delete('/admin/:id', isAdmin, validateBookingId, handleValidationErrors, bookingsController.adminCancel);

// Crear nueva reserva (solo users, no owners)
router.post('/', validateCreateBooking, handleValidationErrors, bookingsController.create);

// Obtener mis reservas (solo para users)
router.get('/my-bookings', validateGetMyBookings, handleValidationErrors, bookingsController.getMyBookings);

// Obtener reservas de mis espacios (solo para owners verificados)
router.get('/owner/bookings', isOwnerOrAdmin, isVerifiedOwner, bookingsController.getOwnerBookings);

// Obtener reservas pendientes de confirmación (solo para owners verificados)
router.get('/owner/pending', isOwnerOrAdmin, isVerifiedOwner, bookingsController.getPendingBookings);

// Obtener reservas pendientes de verificación de transferencia (solo para owners verificados)
router.get('/owner/pending-transfers', isOwnerOrAdmin, isVerifiedOwner, bookingsController.getPendingTransferVerifications);

// Confirmar reserva pendiente (owner)
router.patch('/owner/:id/confirm', validateBookingId, handleValidationErrors, isOwnerOrAdmin, isVerifiedOwner, bookingsController.confirmBooking);

// Rechazar reserva pendiente (owner)
router.patch('/owner/:id/reject', validateBookingId, handleValidationErrors, isOwnerOrAdmin, isVerifiedOwner, bookingsController.rejectBooking);

// Marcar reserva como pagada (owner) - Para efectivo
router.patch('/owner/:id/mark-paid', validateBookingId, handleValidationErrors, isOwnerOrAdmin, isVerifiedOwner, bookingsController.markAsPaid);

// Obtener reservas confirmadas pendientes de pago en efectivo (owner)
router.get('/owner/pending-cash', isOwnerOrAdmin, isVerifiedOwner, bookingsController.getPendingCashPayments);

// Obtener reservas por espacio (para calendario)
router.get('/space/:spaceId', validateGetBySpace, handleValidationErrors, bookingsController.getBySpace);

// Obtener reserva por ID
router.get('/:id', validateBookingId, handleValidationErrors, bookingsController.getById);

// Subir comprobante de transferencia (usuario)
router.post('/:id/transfer-proof', validateBookingId, handleValidationErrors, upload.single('proof'), bookingsController.uploadTransferProof);

// Verificar/rechazar comprobante de transferencia (owner)
router.patch('/:id/verify-transfer', validateBookingId, handleValidationErrors, isOwnerOrAdmin, isVerifiedOwner, bookingsController.verifyTransferPayment);

// Actualizar reserva (para pagos, reprogramación, etc.)
router.patch('/:id', validateBookingId, handleValidationErrors, bookingsController.update);

// Cancelar reserva
router.delete('/:id', validateBookingId, handleValidationErrors, bookingsController.cancel);

module.exports = router;
