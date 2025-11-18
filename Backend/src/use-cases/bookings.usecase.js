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

    // Preparar datos de la reserva
    const bookingData = {
      spaceId,
      userId,
      startTime: start,
      endTime: end,
      notes,
      status: 'confirmed'
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
    const query = { userId, status: { $ne: 'cancelled' } };

    // Filtrar por fecha si se proporciona
    if (filters.startDate) {
      query.startTime = { $gte: new Date(filters.startDate) };
    }
    if (filters.endDate) {
      query.endTime = { $lte: new Date(filters.endDate) };
    }

    const bookings = await Booking.find(query).sort({ startTime: 1 });
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
      'durationHours'
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
    } else {
      // Por defecto, no mostrar canceladas
      query.status = { $ne: 'cancelled' };
    }

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
}

module.exports = new BookingsUseCase();
