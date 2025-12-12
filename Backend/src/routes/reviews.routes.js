const express = require('express');
const router = express.Router();
const reviewsController = require('../controllers/reviews.controller');
const { authMiddleware } = require('../middleware/auth.middleware');
const { isOwnerOrAdmin, isVerifiedOwner } = require('../middleware/role.middleware');

// Rutas públicas - Estadísticas y reseñas de propietarios/espacios

// Obtener estadísticas de un propietario (público)
router.get('/owner/:ownerId/stats', reviewsController.getOwnerStats);

// Obtener reseñas de un propietario (público)
router.get('/owner/:ownerId', reviewsController.getOwnerReviews);

// Obtener estadísticas de un espacio (público)
router.get('/space/:spaceId/stats', reviewsController.getSpaceStats);

// Obtener reseñas de un espacio (público)
router.get('/space/:spaceId', reviewsController.getSpaceReviews);

// Rutas que requieren autenticación
router.use(authMiddleware);

// Verificar si puede dejar reseña en una reserva
router.get('/can-review/:bookingId', reviewsController.canReview);

// Obtener mis reseñas (como usuario)
router.get('/my-reviews', reviewsController.getMyReviews);

// Crear nueva reseña (solo usuarios que hayan completado una reserva)
router.post('/', reviewsController.create);

// Propietario responde a una reseña
router.post('/:reviewId/respond', isOwnerOrAdmin, isVerifiedOwner, reviewsController.respondToReview);

// Eliminar reseña (autor o admin)
router.delete('/:reviewId', reviewsController.delete);

module.exports = router;
