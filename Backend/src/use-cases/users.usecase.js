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
    const allowedFields = ['name', 'businessName', 'businessDescription'];
    
    allowedFields.forEach(field => {
      if (data[field] !== undefined) {
        user[field] = data[field];
      }
    });
    
    await user.save();
    return user.toJSON();
  }
}

module.exports = new UsersUseCase();
