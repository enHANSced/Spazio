const Space = require('../entities/Space');

class SpacesUseCase {
  async list() {
    const spaces = await Space.findAll({ where: { isActive: true }, order: [['name', 'ASC']] });
    return spaces.map(s => s.toJSON());
  }

  async getById(id) {
    const space = await Space.findByPk(id);
    if (!space || !space.isActive) {
      throw new Error('Espacio no encontrado');
    }
    return space.toJSON();
  }

  async create(data) {
    const { name, description, capacity } = data;
    if (!name || !capacity) {
      throw new Error('Nombre y capacidad son requeridos');
    }
    const exists = await Space.findOne({ where: { name } });
    if (exists) {
      throw new Error('Ya existe un espacio con ese nombre');
    }
    const space = await Space.create({ name, description, capacity });
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
}

module.exports = new SpacesUseCase();
