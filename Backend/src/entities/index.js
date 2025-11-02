// Registrar todos los modelos de Sequelize aquí para que sequelize.sync() los detecte

const User = require('./User');
const Space = require('./Space');

module.exports = {
  User,
  Space,
};
