const User = require('../entities/User');

class UsersUseCase {
  /**
   * Obtener todos los usuarios (solo admin)
   */
  async list(filters = {}) {
    const where = {};
    
    if (filters.role) {
      where.role = filters.role;
    }
    
    if (filters.isVerified !== undefined) {
      where.isVerified = filters.isVerified;
    }
    
    if (filters.isActive !== undefined) {
      where.isActive = filters.isActive;
    }
    
    const users = await User.findAll({
      where,
      order: [['createdAt', 'DESC']]
    });
    
    return users.map(u => u.toJSON());
  }

  /**
   * Obtener usuario por ID
   */
  async getById(id) {
    const user = await User.findByPk(id);
    if (!user) {
      throw new Error('Usuario no encontrado');
    }
    return user.toJSON();
  }

  /**
   * Actualizar estado de verificación de un owner (solo admin)
   */
  async verifyOwner(ownerId, isVerified) {
    const user = await User.findByPk(ownerId);
    
    if (!user) {
      throw new Error('Usuario no encontrado');
    }
    
    if (user.role !== 'owner') {
      throw new Error('El usuario no es un propietario');
    }
    
    user.isVerified = isVerified;
    await user.save();
    
    return user.toJSON();
  }

  /**
   * Obtener lista de owners pendientes de verificación
   */
  async getPendingOwners() {
    const owners = await User.findAll({
      where: {
        role: 'owner',
        isVerified: false,
        isActive: true
      },
      order: [['createdAt', 'ASC']]
    });
    
    return owners.map(o => o.toJSON());
  }

  /**
   * Actualizar información del perfil de usuario
   */
  async updateProfile(userId, data) {
    const user = await User.findByPk(userId);
    
    if (!user) {
      throw new Error('Usuario no encontrado');
    }
    
    // Campos que el usuario puede actualizar
    const allowedFields = [
      'name', 'businessName', 'businessDescription', 
      'phone', 'whatsappNumber', 'instagram', 'facebook', 'linkedin'
    ];
    
    allowedFields.forEach(field => {
      if (data[field] !== undefined) {
        user[field] = data[field];
      }
    });
    
    await user.save();
    return user.toJSON();
  }

  /**
   * Actualizar usuario por admin (con más campos permitidos)
   */
  async updateByAdmin(userId, data) {
    const user = await User.findByPk(userId);
    
    if (!user) {
      throw new Error('Usuario no encontrado');
    }
    
    // Admin puede actualizar más campos
    const allowedFields = [
      'name', 'role', 'isActive', 'isVerified',
      'businessName', 'businessDescription', 
      'phone', 'whatsappNumber', 'instagram', 'facebook', 'linkedin'
    ];
    
    allowedFields.forEach(field => {
      if (data[field] !== undefined) {
        user[field] = data[field];
      }
    });
    
    await user.save();
    return user.toJSON();
  }

  /**
   * Activar/desactivar usuario (soft-delete)
   */
  async toggleActive(userId) {
    const user = await User.findByPk(userId);
    
    if (!user) {
      throw new Error('Usuario no encontrado');
    }
    
    // No permitir desactivar admins
    if (user.role === 'admin') {
      throw new Error('No se puede desactivar a un administrador');
    }
    
    user.isActive = !user.isActive;
    await user.save();
    
    return user.toJSON();
  }

  /**
   * Listar usuarios con paginación (solo admin)
   */
  async listPaginated(filters = {}, pagination = {}) {
    const where = {};
    
    if (filters.role) {
      where.role = filters.role;
    }
    
    if (filters.isVerified !== undefined) {
      where.isVerified = filters.isVerified;
    }
    
    if (filters.isActive !== undefined) {
      where.isActive = filters.isActive;
    }

    if (filters.search) {
      const { Op } = require('sequelize');
      where[Op.or] = [
        { name: { [Op.like]: `%${filters.search}%` } },
        { email: { [Op.like]: `%${filters.search}%` } },
        { businessName: { [Op.like]: `%${filters.search}%` } }
      ];
    }

    const page = parseInt(pagination.page) || 1;
    const limit = parseInt(pagination.limit) || 10;
    const offset = (page - 1) * limit;

    const { count, rows } = await User.findAndCountAll({
      where,
      order: [['createdAt', 'DESC']],
      limit,
      offset
    });

    return {
      users: rows.map(u => u.toJSON()),
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit)
      }
    };
  }
}

module.exports = new UsersUseCase();
