const Booking = require('../entities/Booking');
const Space = require('../entities/Space');
const User = require('../entities/User');

class BookingsUseCase {
  /**
   * Crear nueva reserva con validación de disponibilidad
   */
  async create(data, userId) {
    const { 
      spaceId, 
      startTime, 
      endTime, 
      notes,
      paymentMethod,
      paymentStatus,
      totalAmount,
      subtotal,
      serviceFee,
      pricePerHour,
      durationHours
    } = data;

    // Validaciones básicas
    if (!spaceId || !startTime || !endTime) {
      throw new Error('spaceId, startTime y endTime son requeridos');
    }

    const start = new Date(startTime);
    const end = new Date(endTime);

    // Validar fechas
    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      throw new Error('Formato de fecha inválido');
    }

    if (end <= start) {
      throw new Error('La hora de fin debe ser posterior a la hora de inicio');
    }

    // Validar que no sea en el pasado
    if (start < new Date()) {
      throw new Error('No se pueden crear reservas en el pasado');
    }

    // Verificar que el espacio existe y está activo
    const space = await Space.findByPk(spaceId);
    if (!space || !space.isActive) {
      throw new Error('Espacio no encontrado o inactivo');
    }

    // Verificar que el usuario existe
    const user = await User.findByPk(userId);
    if (!user || !user.isActive) {
      throw new Error('Usuario no válido');
    }

    // RESTRICCIÓN: Owners no pueden reservar espacios
    if (user.role === 'owner') {
      throw new Error('Los propietarios no pueden realizar reservas. Si deseas reservar espacios, crea una cuenta de usuario.');
    }

    // CRITICAL: Verificar disponibilidad (prevenir double-booking)
    const overlap = await Booking.checkOverlap(spaceId, start, end);
    if (overlap) {
      throw new Error('El espacio no está disponible en el horario seleccionado');
    }

    // Determinar estado inicial basado en método de pago
    // - Tarjeta (simulada): confirmed + paid (pago inmediato)
    // - Efectivo/Transferencia: pending + pending (requiere confirmación del owner)
    const getInitialStatus = (method, payStatus) => {
      // Si el pago ya está marcado como 'paid' (ej: tarjeta simulada), confirmar inmediatamente
      if (payStatus === 'paid') {
        return 'confirmed';
      }
      // Efectivo y transferencia empiezan como pendientes hasta que el owner confirme
      return 'pending';
    };

    const initialStatus = getInitialStatus(paymentMethod, paymentStatus);

    // Preparar datos de la reserva
    const bookingData = {
      spaceId,
      userId,
      startTime: start,
      endTime: end,
      notes,
      status: initialStatus
    };

    // Agregar campos de pago si se proporcionan
    if (paymentMethod) bookingData.paymentMethod = paymentMethod;
    if (paymentStatus) {
      bookingData.paymentStatus = paymentStatus;
      if (paymentStatus === 'paid') {
        bookingData.paidAt = new Date();
      }
    }
    if (totalAmount !== undefined) bookingData.totalAmount = totalAmount;
    if (subtotal !== undefined) bookingData.subtotal = subtotal;
    if (serviceFee !== undefined) bookingData.serviceFee = serviceFee;
    if (pricePerHour !== undefined) bookingData.pricePerHour = pricePerHour;
    if (durationHours !== undefined) bookingData.durationHours = durationHours;

    // Crear reserva
    const booking = await Booking.create(bookingData);

    return this.enrichBooking(booking);
  }

  /**
   * Obtener reservas del usuario autenticado
   */
  async getUserBookings(userId, filters = {}) {
    const query = { userId };

    // Filtrar por status si se proporciona (incluyendo 'cancelled')
    if (filters.status) {
      query.status = filters.status;
    }
    // Ya no excluimos canceladas por defecto - el usuario debe ver todas sus reservas

    // Filtrar por fecha si se proporciona
    if (filters.startDate) {
      query.startTime = { $gte: new Date(filters.startDate) };
    }
    if (filters.endDate) {
      query.endTime = { $lte: new Date(filters.endDate) };
    }

    const bookings = await Booking.find(query).sort({ startTime: -1 }); // Más recientes primero
    return Promise.all(bookings.map(b => this.enrichBooking(b)));
  }

  /**
   * Obtener reservas por espacio y rango de fechas (para calendario)
   */
  async getBySpace(spaceId, startDate, endDate) {
    const query = {
      spaceId,
      status: { $ne: 'cancelled' }
    };

    if (startDate && endDate) {
      query.$or = [
        { startTime: { $gte: new Date(startDate), $lte: new Date(endDate) } },
        { endTime: { $gte: new Date(startDate), $lte: new Date(endDate) } },
        { startTime: { $lte: new Date(startDate) }, endTime: { $gte: new Date(endDate) } }
      ];
    }

    const bookings = await Booking.find(query).sort({ startTime: 1 });
    return Promise.all(bookings.map(b => this.enrichBooking(b)));
  }

  /**
   * Obtener una reserva por ID
   */
  async getById(bookingId, userId) {
    const booking = await Booking.findById(bookingId);
    if (!booking) {
      throw new Error('Reserva no encontrada');
    }

    // Solo el dueño puede ver la reserva (o admin, pero eso se maneja en controller)
    if (booking.userId !== userId) {
      throw new Error('No tienes permiso para ver esta reserva');
    }

    return this.enrichBooking(booking);
  }

  /**
   * Cancelar una reserva
   */
  async cancel(bookingId, userId, isAdmin = false) {
    const booking = await Booking.findById(bookingId);
    if (!booking) {
      throw new Error('Reserva no encontrada');
    }

    if (booking.status === 'cancelled') {
      throw new Error('La reserva ya está cancelada');
    }

    // Solo el dueño o un admin pueden cancelar
    if (booking.userId !== userId && !isAdmin) {
      throw new Error('No tienes permiso para cancelar esta reserva');
    }

    booking.status = 'cancelled';
    await booking.save();

    return this.enrichBooking(booking);
  }

  /**
   * Actualizar una reserva
   */
  async update(bookingId, userId, updates, isAdmin = false) {
    const booking = await Booking.findById(bookingId);
    if (!booking) {
      throw new Error('Reserva no encontrada');
    }

    // Solo el dueño o un admin pueden actualizar
    if (booking.userId !== userId && !isAdmin) {
      throw new Error('No tienes permiso para actualizar esta reserva');
    }

    // Campos permitidos para actualización
    const allowedFields = [
      'status',
      'paymentMethod',
      'paymentStatus',
      'notes',
      'totalAmount',
      'subtotal',
      'serviceFee',
      'pricePerHour',
      'durationHours',
      'transferProofUrl',
      'transferProofUploadedAt'
    ];

    // Actualizar solo campos permitidos
    Object.keys(updates).forEach(key => {
      if (allowedFields.includes(key)) {
        booking[key] = updates[key];
      }
    });

    // Si se marca como pagado, registrar la fecha
    if (updates.paymentStatus === 'paid' && !booking.paidAt) {
      booking.paidAt = new Date();
    }

    await booking.save();

    return this.enrichBooking(booking);
  }

  /**
   * Subir comprobante de transferencia (usuario)
   */
  async uploadTransferProof(bookingId, userId, proofUrl) {
    const booking = await Booking.findById(bookingId);
    if (!booking) {
      throw new Error('Reserva no encontrada');
    }

    // Verificar que el usuario es el dueño de la reserva
    if (booking.userId !== userId) {
      throw new Error('No tienes permiso para actualizar esta reserva');
    }

    // Verificar que el método de pago es transferencia
    if (booking.paymentMethod !== 'transfer') {
      throw new Error('Esta reserva no está configurada para pago por transferencia');
    }

    // Verificar que el pago está pendiente
    if (booking.paymentStatus === 'paid') {
      throw new Error('Esta reserva ya ha sido pagada');
    }

    // Actualizar con el comprobante
    booking.transferProofUrl = proofUrl;
    booking.transferProofUploadedAt = new Date();
    booking.transferRejectedAt = null;
    booking.transferRejectionReason = null;

    await booking.save();

    return this.enrichBooking(booking);
  }

  /**
   * Verificar comprobante de transferencia (owner)
   */
  async verifyTransferPayment(bookingId, ownerId, approved, rejectionReason = null) {
    const booking = await Booking.findById(bookingId);
    if (!booking) {
      throw new Error('Reserva no encontrada');
    }

    // Verificar que el owner tiene un espacio asociado a esta reserva
    const space = await Space.findByPk(booking.spaceId);
    if (!space || space.ownerId !== ownerId) {
      throw new Error('No tienes permiso para verificar esta reserva');
    }

    // Verificar que hay un comprobante subido
    if (!booking.transferProofUrl) {
      throw new Error('No hay comprobante de transferencia para verificar');
    }

    // Verificar que el pago está pendiente
    if (booking.paymentStatus === 'paid') {
      throw new Error('Esta reserva ya ha sido pagada');
    }

    if (approved) {
      booking.paymentStatus = 'paid';
      booking.status = 'confirmed'; // También confirmar la reserva
      booking.paidAt = new Date();
      booking.transferVerifiedAt = new Date();
      booking.transferVerifiedBy = ownerId;
      booking.transferRejectedAt = null;
      booking.transferRejectionReason = null;
    } else {
      if (!rejectionReason) {
        throw new Error('Debe proporcionar una razón para rechazar el comprobante');
      }
      booking.transferRejectedAt = new Date();
      booking.transferRejectionReason = rejectionReason;
      // Limpiar el comprobante para que el usuario pueda subir uno nuevo
      booking.transferProofUrl = null;
      booking.transferProofUploadedAt = null;
    }

    await booking.save();

    return this.enrichBooking(booking);
  }

  /**
   * Confirmar reserva pendiente (owner)
   * Para reservas con pago en efectivo o que el owner quiera aprobar manualmente
   */
  async confirmBooking(bookingId, ownerId, markAsPaid = false) {
    const booking = await Booking.findById(bookingId);
    if (!booking) {
      throw new Error('Reserva no encontrada');
    }

    // Verificar que el owner tiene un espacio asociado a esta reserva
    const space = await Space.findByPk(booking.spaceId);
    if (!space || space.ownerId !== ownerId) {
      throw new Error('No tienes permiso para confirmar esta reserva');
    }

    // Solo se pueden confirmar reservas pendientes
    if (booking.status !== 'pending') {
      throw new Error(`No se puede confirmar una reserva con estado "${booking.status}"`);
    }

    // Confirmar la reserva
    booking.status = 'confirmed';
    booking.confirmedAt = new Date();
    booking.confirmedBy = ownerId;

    // Si el owner indica que ya recibió el pago (efectivo)
    if (markAsPaid && booking.paymentStatus !== 'paid') {
      booking.paymentStatus = 'paid';
      booking.paidAt = new Date();
    }

    await booking.save();

    return this.enrichBooking(booking);
  }

  /**
   * Rechazar reserva pendiente (owner)
   */
  async rejectBooking(bookingId, ownerId, reason) {
    const booking = await Booking.findById(bookingId);
    if (!booking) {
      throw new Error('Reserva no encontrada');
    }

    // Verificar que el owner tiene un espacio asociado a esta reserva
    const space = await Space.findByPk(booking.spaceId);
    if (!space || space.ownerId !== ownerId) {
      throw new Error('No tienes permiso para rechazar esta reserva');
    }

    // Solo se pueden rechazar reservas pendientes
    if (booking.status !== 'pending') {
      throw new Error(`No se puede rechazar una reserva con estado "${booking.status}"`);
    }

    // La razón es ahora opcional
    // Rechazar = cancelar con razón opcional
    booking.status = 'cancelled';
    booking.rejectedAt = new Date();
    booking.rejectedBy = ownerId;
    if (reason && reason.trim().length > 0) {
      booking.rejectionReason = reason.trim();
    }

    await booking.save();

    return this.enrichBooking(booking);
  }

  /**
   * Obtener reservas pendientes de confirmación (owner)
   */
  async getPendingBookings(ownerId) {
    // Obtener todos los espacios del owner
    const spaces = await Space.findAll({
      where: { ownerId, isActive: true },
      attributes: ['id']
    });

    const spaceIds = spaces.map(s => s.id);

    if (spaceIds.length === 0) {
      return [];
    }

    // Buscar reservas pendientes
    const bookings = await Booking.find({
      spaceId: { $in: spaceIds },
      status: 'pending'
    }).sort({ createdAt: 1 });

    return Promise.all(bookings.map(b => this.enrichBooking(b)));
  }

  /**
   * Obtener reservas pendientes de verificación de transferencia (owner)
   */
  async getPendingTransferVerifications(ownerId) {
    // Obtener todos los espacios del owner
    const spaces = await Space.findAll({
      where: { ownerId, isActive: true },
      attributes: ['id']
    });

    const spaceIds = spaces.map(s => s.id);

    if (spaceIds.length === 0) {
      return [];
    }

    // Buscar reservas con comprobante subido pero no verificadas
    const bookings = await Booking.find({
      spaceId: { $in: spaceIds },
      paymentMethod: 'transfer',
      paymentStatus: 'pending',
      transferProofUrl: { $ne: null },
      transferVerifiedAt: null,
      status: { $ne: 'cancelled' }
    }).sort({ transferProofUploadedAt: 1 });

    return Promise.all(bookings.map(b => this.enrichBooking(b)));
  }

  /**
   * Enriquecer reserva con información de espacio y usuario
   */
  async enrichBooking(booking) {
    const bookingObj = booking.toObject ? booking.toObject() : booking;

    try {
      const [space, user] = await Promise.all([
        Space.findByPk(bookingObj.spaceId),
        User.findByPk(bookingObj.userId)
      ]);

      return {
        ...bookingObj,
        space: space ? { 
          id: space.id, 
          name: space.name, 
          capacity: space.capacity,
          address: space.address,
          size: space.size,
          type: space.type,
          description: space.description
        } : null,
        user: user ? { id: user.id, name: user.name, email: user.email } : null
      };
    } catch (error) {
      // Si falla el enriquecimiento, devolver la reserva básica
      return bookingObj;
    }
  }

  /**
   * Obtener todas las reservas de los espacios de un owner
   */
  async getOwnerBookings(ownerId, filters = {}) {
    // Obtener todos los espacios del owner
    const spaces = await Space.findAll({
      where: { ownerId, isActive: true },
      attributes: ['id']
    });

    const spaceIds = spaces.map(s => s.id);

    if (spaceIds.length === 0) {
      return [];
    }

    // Construir query para las reservas
    const query = {
      spaceId: { $in: spaceIds }
    };

    // Filtrar por status si se proporciona
    if (filters.status) {
      query.status = filters.status;
    }
    // Ya no excluimos canceladas por defecto - el owner debe ver todas las reservas

    // Filtrar por fecha si se proporciona
    if (filters.startDate) {
      query.startTime = { $gte: new Date(filters.startDate) };
    }
    if (filters.endDate) {
      query.endTime = { $lte: new Date(filters.endDate) };
    }

    const bookings = await Booking.find(query).sort({ startTime: -1 });
    return Promise.all(bookings.map(b => this.enrichBooking(b)));
  }

  /**
   * Obtener todas las reservas del sistema con paginación (admin)
   */
  async getAllBookingsPaginated(filters = {}, pagination = {}) {
    const query = {};

    // Filtrar por status si se proporciona
    if (filters.status) {
      query.status = filters.status;
    }

    // Filtrar por espacio si se proporciona
    if (filters.spaceId) {
      query.spaceId = filters.spaceId;
    }

    // Filtrar por usuario si se proporciona
    if (filters.userId) {
      query.userId = filters.userId;
    }

    // Filtrar por rango de fechas
    if (filters.startDate || filters.endDate) {
      query.startTime = {};
      if (filters.startDate) {
        query.startTime.$gte = new Date(filters.startDate);
      }
      if (filters.endDate) {
        query.startTime.$lte = new Date(filters.endDate);
      }
    }

    const page = parseInt(pagination.page) || 1;
    const limit = parseInt(pagination.limit) || 10;
    const skip = (page - 1) * limit;

    const [bookings, total] = await Promise.all([
      Booking.find(query).sort({ startTime: -1 }).skip(skip).limit(limit),
      Booking.countDocuments(query)
    ]);

    const enrichedBookings = await Promise.all(bookings.map(b => this.enrichBooking(b)));

    return {
      bookings: enrichedBookings,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  /**
   * Cancelar cualquier reserva (admin)
   */
  async adminCancel(bookingId) {
    const booking = await Booking.findById(bookingId);
    if (!booking) {
      throw new Error('Reserva no encontrada');
    }

    if (booking.status === 'cancelled') {
      throw new Error('La reserva ya está cancelada');
    }

    booking.status = 'cancelled';
    await booking.save();

    return this.enrichBooking(booking);
  }

  /**
   * Obtener estadísticas generales (admin)
   */
  async getStats() {
    const [
      totalUsers,
      totalOwners,
      pendingOwners,
      totalSpaces,
      activeSpaces,
      totalBookings,
      confirmedBookings,
      cancelledBookings
    ] = await Promise.all([
      User.count({ where: { role: 'user', isActive: true } }),
      User.count({ where: { role: 'owner', isActive: true } }),
      User.count({ where: { role: 'owner', isVerified: false, isActive: true } }),
      Space.count(),
      Space.count({ where: { isActive: true } }),
      Booking.countDocuments(),
      Booking.countDocuments({ status: 'confirmed' }),
      Booking.countDocuments({ status: 'cancelled' })
    ]);

    // Reservas de los últimos 30 días
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const recentBookings = await Booking.countDocuments({
      createdAt: { $gte: thirtyDaysAgo }
    });

    // Reservas de hoy
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const todayBookings = await Booking.countDocuments({
      startTime: { $gte: today, $lt: tomorrow },
      status: 'confirmed'
    });

    return {
      users: {
        total: totalUsers,
        owners: totalOwners,
        pendingOwners
      },
      spaces: {
        total: totalSpaces,
        active: activeSpaces,
        inactive: totalSpaces - activeSpaces
      },
      bookings: {
        total: totalBookings,
        confirmed: confirmedBookings,
        cancelled: cancelledBookings,
        recentThirtyDays: recentBookings,
        today: todayBookings
      }
    };
  }
}

module.exports = new BookingsUseCase();
