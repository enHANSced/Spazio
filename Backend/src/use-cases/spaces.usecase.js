const Space = require('../entities/Space');
const User = require('../entities/User');

class SpacesUseCase {
  async list() {
    const spaces = await Space.findAll({ 
      where: { isActive: true }, 
      order: [['name', 'ASC']],
      include: [{
        model: User,
        as: 'owner',
        attributes: ['id', 'businessName', 'name']
      }]
    });
    return spaces.map(s => s.toJSON());
  }

  async getById(id) {
    const space = await Space.findByPk(id, {
      include: [{
        model: User,
        as: 'owner',
        attributes: ['id', 'businessName', 'name', 'businessDescription']
      }]
    });
    if (!space || !space.isActive) {
      throw new Error('Espacio no encontrado');
    }
    return space.toJSON();
  }

  async create(data) {
    const { name, description, capacity, ownerId } = data;
    if (!name || !capacity || !ownerId) {
      throw new Error('Nombre, capacidad y propietario son requeridos');
    }
    
    // Verificar que el owner existe y es un owner verificado
    const owner = await User.findByPk(ownerId);
    if (!owner) {
      throw new Error('Propietario no encontrado');
    }
    if (owner.role !== 'owner' && owner.role !== 'admin') {
      throw new Error('El usuario debe tener rol de propietario');
    }
    if (owner.role === 'owner' && !owner.isVerified) {
      throw new Error('El propietario debe estar verificado para crear espacios');
    }
    
    const exists = await Space.findOne({ where: { name } });
    if (exists) {
      throw new Error('Ya existe un espacio con ese nombre');
    }
    const space = await Space.create({ name, description, capacity, ownerId });
    return space.toJSON();
  }

  async update(id, data) {
    const space = await Space.findByPk(id);
    if (!space || !space.isActive) {
      throw new Error('Espacio no encontrado');
    }
    const fields = ['name', 'description', 'capacity', 'isActive'];
    fields.forEach((f) => {
      if (data[f] !== undefined) space[f] = data[f];
    });

    // Si cambian el nombre, validar duplicado
    if (data.name && data.name !== space.name) {
      const dup = await Space.findOne({ where: { name: data.name } });
      if (dup && dup.id !== space.id) {
        throw new Error('Ya existe un espacio con ese nombre');
      }
    }

    await space.save();
    return space.toJSON();
  }

  async remove(id) {
    const space = await Space.findByPk(id);
    if (!space || !space.isActive) {
      throw new Error('Espacio no encontrado');
    }
    space.isActive = false;
    await space.save();
    return { id: space.id };
  }

  /**
   * Obtener espacios de un owner específico
   */
  async findByOwner(ownerId) {
    const spaces = await Space.findAll({
      where: { ownerId, isActive: true },
      order: [['createdAt', 'DESC']]
    });
    return spaces.map(s => s.toJSON());
  }
}

module.exports = new SpacesUseCase();
