// Registrar todos los modelos de Sequelize aquí para que sequelize.sync() los detecte

const User = require('./User');
const Space = require('./Space');

// Inicializar asociaciones si existen
const models = { User, Space };

Object.keys(models).forEach(modelName => {
  if (models[modelName].associate) {
    models[modelName].associate(models);
  }
});

module.exports = {
  User,
  Space,
};
