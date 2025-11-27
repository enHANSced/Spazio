const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const bcrypt = require('bcryptjs');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  email: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  password: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  role: {
    type: DataTypes.ENUM('user', 'owner', 'admin'),
    defaultValue: 'user'
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  isVerified: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    comment: 'Para usuarios owner, requiere aprobación de admin'
  },
  businessName: {
    type: DataTypes.STRING(150),
    allowNull: true,
    comment: 'Nombre del negocio para usuarios owner'
  },
  businessDescription: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Descripción del negocio para usuarios owner'
  },
  phone: {
    type: DataTypes.STRING(20),
    allowNull: true,
    comment: 'Número de teléfono'
  },
  whatsappNumber: {
    type: DataTypes.STRING(20),
    allowNull: true,
    comment: 'Número de WhatsApp (formato internacional recomendado: +504XXXXXXXX)'
  },
  instagram: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'URL de perfil de Instagram'
  },
  facebook: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'URL de perfil de Facebook'
  },
  linkedin: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'URL de perfil de LinkedIn'
  }
}, {
  tableName: 'users',
  timestamps: true,
  hooks: {
    beforeCreate: async (user) => {
      if (user.password) {
        user.password = await bcrypt.hash(user.password, 10);
      }
    },
    beforeUpdate: async (user) => {
      if (user.changed('password')) {
        user.password = await bcrypt.hash(user.password, 10);
      }
    }
  }
});

// Método para comparar contraseñas
User.prototype.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Método para convertir a JSON sin password
User.prototype.toJSON = function() {
  const values = { ...this.get() };
  delete values.password;
  return values;
};

// Asociación con Spaces (para owners)
User.associate = (models) => {
  User.hasMany(models.Space, {
    foreignKey: 'ownerId',
    as: 'spaces'
  });
};

module.exports = User;
