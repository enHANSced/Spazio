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
        attributes: ['id', 'businessName', 'name', 'businessDescription', 'whatsappNumber', 'instagram', 'facebook', 'linkedin']
      }]
    });
    if (!space || !space.isActive) {
      throw new Error('Espacio no encontrado');
    }
    return space.toJSON();
  }

  async create(data) {
    const { 
      name, description, capacity, ownerId, images,
      pricePerHour, amenities, rules, virtualTourUrl, cancellationPolicy,
      address, city, state, country, latitude, longitude, zipCode,
      workingHours, videos, images360
    } = data;
    
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
    
    let processedImages = [];
    if (Array.isArray(images) && images.length) {
      const { uploadImages } = require('../services/cloudinary.service');
      processedImages = await uploadImages(images);
    }

    const spaceData = {
      name, 
      description, 
      capacity, 
      ownerId, 
      images: processedImages,
      pricePerHour: pricePerHour || 0,
      amenities: amenities || [],
      rules: rules || '',
      virtualTourUrl: virtualTourUrl || null,
      cancellationPolicy: cancellationPolicy || 'flexible',
      address: address || null,
      city: city || null,
      state: state || null,
      country: country || 'Honduras',
      latitude: latitude || null,
      longitude: longitude || null,
      zipCode: zipCode || null,
      workingHours: workingHours || { start: '08:00', end: '22:00' },
      videos: videos || [],
      images360: images360 || []
    };

    const space = await Space.create(spaceData);
    return space.toJSON();
  }

  async update(id, data) {
    const space = await Space.findByPk(id);
    if (!space) {
      throw new Error('Espacio no encontrado');
    }
    
    const fields = [
      'name', 'description', 'capacity', 'isActive',
      'pricePerHour', 'amenities', 'rules', 'virtualTourUrl', 'cancellationPolicy',
      'address', 'city', 'state', 'country', 'latitude', 'longitude', 'zipCode',
      'workingHours', 'videos', 'images360'
    ];
    
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

    // Manejo de imágenes
    const { images: newImages, imagesToDelete } = data;
    let changed = false;
    if (Array.isArray(imagesToDelete) && imagesToDelete.length && Array.isArray(space.images)) {
      const { deleteImage } = require('../services/cloudinary.service');
      space.images = space.images.filter(img => {
        if (img.publicId && imagesToDelete.includes(img.publicId)) {
          deleteImage(img.publicId).catch(() => {}); // Best-effort
          changed = true;
          return false;
        }
        return true;
      });
    }
    if (Array.isArray(newImages) && newImages.length) {
      const { uploadImages } = require('../services/cloudinary.service');
      const uploaded = await uploadImages(newImages);
      if (!Array.isArray(space.images)) space.images = [];
      space.images = space.images.concat(uploaded);
      changed = true;
    }
    if (changed) {
      // Garantizar no duplicados por URL pública
      const seen = new Set();
      space.images = space.images.filter(img => {
        if (!img || !img.url) return false;
        if (seen.has(img.url)) return false;
        seen.add(img.url);
        return true;
      });
    }

    await space.save();
    return space.toJSON();
  }

  async remove(id) {
    const space = await Space.findByPk(id);
    if (!space) {
      throw new Error('Espacio no encontrado');
    }
    // Soft delete - marcar como inactivo
    space.isActive = false;
    await space.save();
    return { id: space.id };
  }

  /**
   * Obtener espacios de un owner específico (incluyendo inactivos)
   */
  async findByOwner(ownerId) {
    const spaces = await Space.findAll({
      where: { ownerId },
      order: [['createdAt', 'DESC']]
    });
    return spaces.map(s => s.toJSON());
  }
}

module.exports = new SpacesUseCase();
