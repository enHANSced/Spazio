const Review = require('../entities/Review');
const Booking = require('../entities/Booking');
const Space = require('../entities/Space');
const User = require('../entities/User');

class ReviewsUseCase {
  /**
   * Crear nueva reseña para una reserva completada
   */
  async create(data, userId) {
    const { bookingId, rating, comment } = data;

    // Validaciones básicas
    if (!bookingId) {
      throw new Error('bookingId es requerido');
    }

    if (!rating || rating < 1 || rating > 5) {
      throw new Error('rating debe ser un número entre 1 y 5');
    }

    // Verificar que el usuario puede crear la reseña
    const canReviewResult = await Review.canReview(bookingId, userId);
    if (!canReviewResult.canReview) {
      throw new Error(canReviewResult.reason);
    }

    const booking = canReviewResult.booking;

    // Obtener el espacio para saber el ownerId
    const space = await Space.findByPk(booking.spaceId);
    if (!space) {
      throw new Error('Espacio no encontrado');
    }

    // Crear la reseña
    const review = await Review.create({
      bookingId,
      userId,
      ownerId: space.ownerId,
      spaceId: booking.spaceId,
      rating,
      comment: comment || ''
    });

    return this.enrichReview(review);
  }

  /**
   * Obtener reseñas de un propietario
   */
  async getOwnerReviews(ownerId, options = {}) {
    const { page = 1, limit = 10 } = options;
    const skip = (page - 1) * limit;

    const [reviews, total] = await Promise.all([
      Review.find({ ownerId, isActive: true })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Review.countDocuments({ ownerId, isActive: true })
    ]);

    const enrichedReviews = await Promise.all(reviews.map(r => this.enrichReview(r)));

    return {
      reviews: enrichedReviews,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  /**
   * Obtener reseñas de un espacio
   */
  async getSpaceReviews(spaceId, options = {}) {
    const { page = 1, limit = 10 } = options;
    const skip = (page - 1) * limit;

    const [reviews, total] = await Promise.all([
      Review.find({ spaceId, isActive: true })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Review.countDocuments({ spaceId, isActive: true })
    ]);

    const enrichedReviews = await Promise.all(reviews.map(r => this.enrichReview(r)));

    return {
      reviews: enrichedReviews,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  /**
   * Obtener estadísticas completas de un propietario
   */
  async getOwnerStats(ownerId) {
    // Verificar que el owner existe
    const owner = await User.findByPk(ownerId);
    if (!owner) {
      throw new Error('Propietario no encontrado');
    }

    // Obtener estadísticas de reseñas
    const reviewStats = await Review.getOwnerStats(ownerId);

    // Obtener conteo de espacios
    const spacesCount = await Space.count({
      where: { ownerId, isActive: true }
    });

    // Obtener todos los espacios del owner para buscar sus reservas
    const spaces = await Space.findAll({
      where: { ownerId, isActive: true },
      attributes: ['id']
    });
    const spaceIds = spaces.map(s => s.id);

    // Obtener conteo de reservas completadas (confirmadas y terminadas)
    const now = new Date();
    const completedBookings = await Booking.countDocuments({
      spaceId: { $in: spaceIds },
      status: 'confirmed',
      endTime: { $lte: now }
    });

    // Obtener reservas totales (no canceladas)
    const totalBookings = await Booking.countDocuments({
      spaceId: { $in: spaceIds },
      status: { $ne: 'cancelled' }
    });

    return {
      owner: {
        id: owner.id,
        name: owner.name,
        businessName: owner.businessName,
        isVerified: owner.isVerified,
        memberSince: owner.createdAt
      },
      stats: {
        spacesCount,
        totalBookings,
        completedBookings,
        ...reviewStats
      }
    };
  }

  /**
   * Obtener estadísticas de un espacio específico
   */
  async getSpaceStats(spaceId) {
    const space = await Space.findByPk(spaceId);
    if (!space) {
      throw new Error('Espacio no encontrado');
    }

    // Estadísticas de reseñas del espacio
    const reviewStats = await Review.getSpaceStats(spaceId);

    // Reservas completadas
    const now = new Date();
    const completedBookings = await Booking.countDocuments({
      spaceId,
      status: 'confirmed',
      endTime: { $lte: now }
    });

    return {
      spaceId,
      spaceName: space.name,
      completedBookings,
      ...reviewStats
    };
  }

  /**
   * Verificar si el usuario puede dejar reseña en una reserva
   */
  async canReview(bookingId, userId) {
    return Review.canReview(bookingId, userId);
  }

  /**
   * Obtener reseñas hechas por un usuario
   */
  async getUserReviews(userId, options = {}) {
    const { page = 1, limit = 10 } = options;
    const skip = (page - 1) * limit;

    const [reviews, total] = await Promise.all([
      Review.find({ userId, isActive: true })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Review.countDocuments({ userId, isActive: true })
    ]);

    const enrichedReviews = await Promise.all(reviews.map(r => this.enrichReview(r)));

    return {
      reviews: enrichedReviews,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  /**
   * Propietario responde a una reseña
   */
  async respondToReview(reviewId, ownerId, responseText) {
    const review = await Review.findById(reviewId);
    if (!review) {
      throw new Error('Reseña no encontrada');
    }

    if (review.ownerId !== ownerId) {
      throw new Error('No autorizado para responder a esta reseña');
    }

    if (review.ownerResponse?.text) {
      throw new Error('Ya existe una respuesta a esta reseña');
    }

    review.ownerResponse = {
      text: responseText,
      respondedAt: new Date()
    };

    await review.save();
    return this.enrichReview(review);
  }

  /**
   * Eliminar reseña (soft delete)
   */
  async delete(reviewId, userId, isAdmin = false) {
    const review = await Review.findById(reviewId);
    if (!review) {
      throw new Error('Reseña no encontrada');
    }

    // Solo el autor o un admin pueden eliminar
    if (review.userId !== userId && !isAdmin) {
      throw new Error('No autorizado para eliminar esta reseña');
    }

    review.isActive = false;
    await review.save();

    return { message: 'Reseña eliminada correctamente' };
  }

  /**
   * Enriquecer reseña con datos de usuario y espacio
   */
  async enrichReview(review) {
    const reviewObj = review.toObject ? review.toObject() : review;

    // Obtener datos del usuario que hizo la reseña
    const user = await User.findByPk(reviewObj.userId, {
      attributes: ['id', 'name']
    });

    // Obtener datos del espacio
    const space = await Space.findByPk(reviewObj.spaceId, {
      attributes: ['id', 'name', 'images']
    });

    return {
      ...reviewObj,
      user: user ? {
        id: user.id,
        name: user.name
      } : null,
      space: space ? {
        id: space.id,
        name: space.name,
        image: space.images?.[0] || null
      } : null
    };
  }
}

module.exports = new ReviewsUseCase();
