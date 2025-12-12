const reviewsUseCase = require('../use-cases/reviews.usecase');

class ReviewsController {
  /**
   * Crear nueva reseña
   */
  async create(req, res) {
    try {
      const review = await reviewsUseCase.create(req.body, req.user.id);
      res.status(201).json({
        success: true,
        message: 'Reseña creada exitosamente',
        data: review
      });
    } catch (error) {
      const status = error.message.includes('No autorizado') ? 403 : 400;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener reseñas de un propietario
   */
  async getOwnerReviews(req, res) {
    try {
      const { ownerId } = req.params;
      const { page, limit } = req.query;
      
      const result = await reviewsUseCase.getOwnerReviews(ownerId, {
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 10
      });
      
      res.status(200).json({
        success: true,
        data: result.reviews,
        pagination: result.pagination
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener estadísticas de un propietario
   */
  async getOwnerStats(req, res) {
    try {
      const { ownerId } = req.params;
      const stats = await reviewsUseCase.getOwnerStats(ownerId);
      
      res.status(200).json({
        success: true,
        data: stats
      });
    } catch (error) {
      const status = error.message.includes('no encontrado') ? 404 : 500;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener reseñas de un espacio
   */
  async getSpaceReviews(req, res) {
    try {
      const { spaceId } = req.params;
      const { page, limit } = req.query;
      
      const result = await reviewsUseCase.getSpaceReviews(spaceId, {
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 10
      });
      
      res.status(200).json({
        success: true,
        data: result.reviews,
        pagination: result.pagination
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener estadísticas de un espacio
   */
  async getSpaceStats(req, res) {
    try {
      const { spaceId } = req.params;
      const stats = await reviewsUseCase.getSpaceStats(spaceId);
      
      res.status(200).json({
        success: true,
        data: stats
      });
    } catch (error) {
      const status = error.message.includes('no encontrado') ? 404 : 500;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Verificar si el usuario puede dejar reseña
   */
  async canReview(req, res) {
    try {
      const { bookingId } = req.params;
      const result = await reviewsUseCase.canReview(bookingId, req.user.id);
      
      res.status(200).json({
        success: true,
        data: result
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener mis reseñas (como usuario)
   */
  async getMyReviews(req, res) {
    try {
      const { page, limit } = req.query;
      
      const result = await reviewsUseCase.getUserReviews(req.user.id, {
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 10
      });
      
      res.status(200).json({
        success: true,
        data: result.reviews,
        pagination: result.pagination
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Propietario responde a una reseña
   */
  async respondToReview(req, res) {
    try {
      const { reviewId } = req.params;
      const { response } = req.body;
      
      if (!response || response.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'La respuesta es requerida'
        });
      }
      
      const review = await reviewsUseCase.respondToReview(
        reviewId, 
        req.user.id, 
        response.trim()
      );
      
      res.status(200).json({
        success: true,
        message: 'Respuesta agregada exitosamente',
        data: review
      });
    } catch (error) {
      const status = error.message.includes('No autorizado') ? 403 : 400;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Eliminar reseña
   */
  async delete(req, res) {
    try {
      const { reviewId } = req.params;
      const isAdmin = req.user.role === 'admin';
      
      const result = await reviewsUseCase.delete(reviewId, req.user.id, isAdmin);
      
      res.status(200).json({
        success: true,
        message: result.message
      });
    } catch (error) {
      const status = error.message.includes('No autorizado') ? 403 : 
                     error.message.includes('no encontrada') ? 404 : 400;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }
}

module.exports = new ReviewsController();
