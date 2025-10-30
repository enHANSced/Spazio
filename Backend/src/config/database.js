const { Sequelize } = require('sequelize');
const mongoose = require('mongoose');

// Configuración MySQL con Sequelize
const sequelize = new Sequelize(
  process.env.MYSQL_DATABASE,
  process.env.MYSQL_USER,
  process.env.MYSQL_PASSWORD,
  {
    host: process.env.MYSQL_HOST,
    port: process.env.MYSQL_PORT,
    dialect: 'mysql',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

// Conectar a MySQL
const connectMySQL = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ MySQL conectado correctamente');
    
    // Sincronizar modelos (solo en desarrollo)
    if (process.env.NODE_ENV === 'development') {
      await sequelize.sync({ alter: false });
      console.log('📊 Modelos MySQL sincronizados');
    }
  } catch (error) {
    console.error('❌ Error conectando a MySQL:', error);
    throw error;
  }
};

// Conectar a MongoDB
const connectMongoDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('✅ MongoDB conectado correctamente');
  } catch (error) {
    console.error('❌ Error conectando a MongoDB:', error);
    throw error;
  }
};

module.exports = {
  sequelize,
  mongoose,
  connectMySQL,
  connectMongoDB
};
