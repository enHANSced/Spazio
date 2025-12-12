const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Space = sequelize.define('Space', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING(120),
    allowNull: false,
    unique: true
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  capacity: {
    type: DataTypes.INTEGER.UNSIGNED,
    allowNull: false,
    defaultValue: 1,
    validate: { min: 1 }
  },
  ownerId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    },
    comment: 'Usuario owner que gestiona este espacio'
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  category: {
    type: DataTypes.STRING(50),
    allowNull: true,
    defaultValue: 'meetings',
    validate: {
      isIn: [['private', 'meetings', 'teams', 'events', 'coworking', 'studio', 'training']]
    },
    comment: 'Categoría del espacio: private, meetings, teams, events, coworking, studio, training'
  },
  images: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: [],
    get() {
      const rawValue = this.getDataValue('images');
      if (!rawValue) return [];
      // Si ya es un array, retornarlo
      if (Array.isArray(rawValue)) return rawValue;
      // Si es string, intentar parsear
      if (typeof rawValue === 'string') {
        try {
          return JSON.parse(rawValue);
        } catch (e) {
          return [];
        }
      }
      return [];
    },
    set(value) {
      // Asegurar que siempre se guarde como array JSON válido
      if (!value) {
        this.setDataValue('images', []);
      } else if (Array.isArray(value)) {
        this.setDataValue('images', value);
      } else {
        this.setDataValue('images', []);
      }
    },
    comment: 'Array de objetos { url, publicId } provenientes de Cloudinary o URLs externas'
  },
  pricePerHour: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
    defaultValue: 0,
    validate: { min: 0 },
    comment: 'Precio por hora en HNL'
  },
  amenities: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: [],
    get() {
      const rawValue = this.getDataValue('amenities');
      if (!rawValue) return [];
      if (Array.isArray(rawValue)) return rawValue;
      if (typeof rawValue === 'string') {
        try {
          return JSON.parse(rawValue);
        } catch (e) {
          return [];
        }
      }
      return [];
    },
    comment: 'Array de amenidades: ["Wi-Fi", "Aire acondicionado", etc.]'
  },
  rules: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Reglas del espacio (no fumar, etc.)'
  },
  virtualTourUrl: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'URL de tour virtual (Matterport, etc.)'
  },
  cancellationPolicy: {
    type: DataTypes.STRING(50),
    allowNull: true,
    defaultValue: 'flexible',
    validate: {
      isIn: [['flexible', 'moderate', 'strict']]
    },
    comment: 'Política de cancelación'
  },
  address: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'Dirección completa del espacio'
  },
  city: {
    type: DataTypes.STRING(100),
    allowNull: true,
    comment: 'Ciudad'
  },
  state: {
    type: DataTypes.STRING(100),
    allowNull: true,
    comment: 'Departamento/Estado'
  },
  country: {
    type: DataTypes.STRING(100),
    allowNull: true,
    defaultValue: 'Honduras',
    comment: 'País'
  },
  latitude: {
    type: DataTypes.DECIMAL(10, 8),
    allowNull: true,
    validate: { min: -90, max: 90 },
    comment: 'Latitud GPS'
  },
  longitude: {
    type: DataTypes.DECIMAL(11, 8),
    allowNull: true,
    validate: { min: -180, max: 180 },
    comment: 'Longitud GPS'
  },
  zipCode: {
    type: DataTypes.STRING(10),
    allowNull: true,
    comment: 'Código postal'
  },
  workingHours: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: { start: '08:00', end: '22:00' },
    get() {
      const rawValue = this.getDataValue('workingHours');
      if (!rawValue) return { start: '08:00', end: '22:00' };
      if (typeof rawValue === 'string') {
        try {
          return JSON.parse(rawValue);
        } catch (e) {
          return { start: '08:00', end: '22:00' };
        }
      }
      return rawValue;
    },
    comment: 'Horario de operación: { start: "08:00", end: "22:00" }'
  },
  videos: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: [],
    get() {
      const rawValue = this.getDataValue('videos');
      if (!rawValue) return [];
      if (Array.isArray(rawValue)) return rawValue;
      if (typeof rawValue === 'string') {
        try {
          return JSON.parse(rawValue);
        } catch (e) {
          return [];
        }
      }
      return [];
    },
    comment: 'Array de videos: [{ url, publicId, thumbnail }]'
  },
  images360: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: [],
    get() {
      const rawValue = this.getDataValue('images360');
      if (!rawValue) return [];
      if (Array.isArray(rawValue)) return rawValue;
      if (typeof rawValue === 'string') {
        try {
          return JSON.parse(rawValue);
        } catch (e) {
          return [];
        }
      }
      return [];
    },
    comment: 'Array de imágenes 360°: [{ url, publicId }]'
  }
}, {
  tableName: 'spaces',
  timestamps: true
});

// Asociación con User (owner)
Space.associate = (models) => {
  Space.belongsTo(models.User, {
    foreignKey: 'ownerId',
    as: 'owner'
  });
};

module.exports = Space;
