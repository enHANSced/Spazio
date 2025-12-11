const bookingsUseCase = require('../use-cases/bookings.usecase');
const cloudinaryService = require('../services/cloudinary.service');

class BookingsController {
  /**
   * Crear nueva reserva
   */
  async create(req, res) {
    try {
      const booking = await bookingsUseCase.create(req.body, req.user.id);
      res.status(201).json({
        success: true,
        message: 'Reserva creada exitosamente',
        data: booking
      });
    } catch (error) {
      const status = error.message.includes('no está disponible') ? 409 : 400;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener mis reservas
   */
  async getMyBookings(req, res) {
    try {
      const { startDate, endDate, status } = req.query;
      const bookings = await bookingsUseCase.getUserBookings(req.user.id, {
        startDate,
        endDate,
        status
      });
      res.status(200).json({
        success: true,
        data: bookings
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener reservas por espacio (para calendario)
   */
  async getBySpace(req, res) {
    try {
      const { spaceId } = req.params;
      const { startDate, endDate } = req.query;

      if (!startDate || !endDate) {
        return res.status(400).json({
          success: false,
          message: 'Se requieren startDate y endDate como query params'
        });
      }

      const bookings = await bookingsUseCase.getBySpace(spaceId, startDate, endDate);
      res.status(200).json({
        success: true,
        data: bookings
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener una reserva por ID
   */
  async getById(req, res) {
    try {
      const booking = await bookingsUseCase.getById(req.params.id, req.user.id);
      res.status(200).json({
        success: true,
        data: booking
      });
    } catch (error) {
      const status = error.message.includes('permiso') ? 403 : 404;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Cancelar reserva
   */
  async cancel(req, res) {
    try {
      const isAdmin = req.user.role === 'admin';
      const booking = await bookingsUseCase.cancel(req.params.id, req.user.id, isAdmin);
      res.status(200).json({
        success: true,
        message: 'Reserva cancelada',
        data: booking
      });
    } catch (error) {
      const status = error.message.includes('permiso') ? 403 : 404;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener reservas de los espacios del owner
   */
  async getOwnerBookings(req, res) {
    try {
      const { status, startDate, endDate } = req.query;
      const bookings = await bookingsUseCase.getOwnerBookings(req.user.id, {
        status,
        startDate,
        endDate
      });
      res.status(200).json({
        success: true,
        data: bookings
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Actualizar una reserva (para pagos, reprogramación, etc.)
   */
  async update(req, res) {
    try {
      const isAdmin = req.user.role === 'admin';
      const booking = await bookingsUseCase.update(
        req.params.id,
        req.user.id,
        req.body,
        isAdmin
      );
      res.status(200).json({
        success: true,
        message: 'Reserva actualizada',
        data: booking
      });
    } catch (error) {
      const status = error.message.includes('permiso') ? 403 : 404;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener todas las reservas con paginación (admin)
   */
  async getAllBookings(req, res) {
    try {
      const filters = {
        status: req.query.status,
        spaceId: req.query.spaceId,
        userId: req.query.userId,
        startDate: req.query.startDate,
        endDate: req.query.endDate
      };

      const pagination = {
        page: req.query.page,
        limit: req.query.limit
      };

      const data = await bookingsUseCase.getAllBookingsPaginated(filters, pagination);
      res.status(200).json({
        success: true,
        data: data.bookings,
        pagination: data.pagination
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Cancelar cualquier reserva (admin)
   */
  async adminCancel(req, res) {
    try {
      const booking = await bookingsUseCase.adminCancel(req.params.id);
      res.status(200).json({
        success: true,
        message: 'Reserva cancelada por administrador',
        data: booking
      });
    } catch (error) {
      const status = error.message.includes('no encontrada') ? 404 : 400;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener estadísticas generales (admin)
   */
  async getStats(req, res) {
    try {
      const stats = await bookingsUseCase.getStats();
      res.status(200).json({
        success: true,
        data: stats
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Subir comprobante de transferencia (usuario)
   */
  async uploadTransferProof(req, res) {
    try {
      const { id } = req.params;

      // Verificar que hay una imagen
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'Debe adjuntar una imagen del comprobante de transferencia'
        });
      }

      // Subir imagen a Cloudinary
      const uploadResult = await cloudinaryService.uploadBuffer(
        req.file.buffer,
        'transfer-proofs',
        {
          public_id: `transfer_${id}_${Date.now()}`,
          transformation: [
            { quality: 'auto:good' },
            { fetch_format: 'auto' }
          ]
        }
      );

      // Actualizar la reserva con la URL del comprobante
      const booking = await bookingsUseCase.uploadTransferProof(
        id,
        req.user.id,
        uploadResult.secure_url
      );

      res.status(200).json({
        success: true,
        message: 'Comprobante de transferencia subido exitosamente. El propietario lo revisará pronto.',
        data: booking
      });
    } catch (error) {
      console.error('Error uploading transfer proof:', error);
      const status = error.message.includes('permiso') ? 403 : 
                     error.message.includes('no encontrada') ? 404 : 400;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Verificar/rechazar comprobante de transferencia (owner)
   */
  async verifyTransferPayment(req, res) {
    try {
      const { id } = req.params;
      const { approved, rejectionReason } = req.body;

      if (typeof approved !== 'boolean') {
        return res.status(400).json({
          success: false,
          message: 'Debe especificar si aprueba o rechaza el comprobante'
        });
      }

      const booking = await bookingsUseCase.verifyTransferPayment(
        id,
        req.user.id,
        approved,
        rejectionReason
      );

      res.status(200).json({
        success: true,
        message: approved 
          ? 'Pago verificado exitosamente' 
          : 'Comprobante rechazado. El usuario podrá subir uno nuevo.',
        data: booking
      });
    } catch (error) {
      console.error('Error verifying transfer payment:', error);
      const status = error.message.includes('permiso') ? 403 : 
                     error.message.includes('no encontrada') ? 404 : 400;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener reservas pendientes de verificación de transferencia (owner)
   */
  async getPendingTransferVerifications(req, res) {
    try {
      const bookings = await bookingsUseCase.getPendingTransferVerifications(req.user.id);
      res.status(200).json({
        success: true,
        data: bookings
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Obtener reservas pendientes de confirmación (owner)
   */
  async getPendingBookings(req, res) {
    try {
      const bookings = await bookingsUseCase.getPendingBookings(req.user.id);
      res.status(200).json({
        success: true,
        data: bookings
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Confirmar reserva pendiente (owner)
   */
  async confirmBooking(req, res) {
    try {
      const { id } = req.params;
      const { markAsPaid } = req.body;

      const booking = await bookingsUseCase.confirmBooking(
        id,
        req.user.id,
        markAsPaid === true
      );

      res.status(200).json({
        success: true,
        message: markAsPaid 
          ? 'Reserva confirmada y marcada como pagada' 
          : 'Reserva confirmada exitosamente',
        data: booking
      });
    } catch (error) {
      console.error('Error confirming booking:', error);
      const status = error.message.includes('permiso') ? 403 : 
                     error.message.includes('no encontrada') ? 404 : 400;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Rechazar reserva pendiente (owner)
   */
  async rejectBooking(req, res) {
    try {
      const { id } = req.params;
      const { reason } = req.body;

      // La razón es ahora opcional

      const booking = await bookingsUseCase.rejectBooking(
        id,
        req.user.id,
        reason
      );

      res.status(200).json({
        success: true,
        message: 'Reserva rechazada',
        data: booking
      });
    } catch (error) {
      console.error('Error rejecting booking:', error);
      const status = error.message.includes('permiso') ? 403 : 
                     error.message.includes('no encontrada') ? 404 : 400;
      res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }
}

module.exports = new BookingsController();
