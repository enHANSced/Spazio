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
  images: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'Array de objetos { url, publicId } provenientes de Cloudinary o URLs externas'
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
