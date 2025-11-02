require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { connectMySQL, connectMongoDB } = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rutas básicas
app.get('/', (req, res) => {
  res.json({ 
    message: 'Bienvenido a Spazio API',
    version: '1.0.0',
    status: 'active'
  });
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    timestamp: new Date().toISOString()
  });
});

// Importar rutas
const authRoutes = require('./routes/auth.routes');
const spacesRoutes = require('./routes/spaces.routes');
const bookingsRoutes = require('./routes/bookings.routes');

// Usar rutas
app.use('/api/auth', authRoutes);
app.use('/api/spaces', spacesRoutes);
app.use('/api/bookings', bookingsRoutes);

// Manejo de errores 404
app.use((req, res) => {
  res.status(404).json({ message: 'Ruta no encontrada' });
});

// Manejo de errores global
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    message: 'Error interno del servidor',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Iniciar servidor
const startServer = async () => {
  try {
    const skipDB = process.env.SKIP_DB === 'true';
    if (skipDB) {
      console.log('⚠️  SKIP_DB habilitado: No se conectará a MySQL/MongoDB');
    } else {
      // Conectar a las bases de datos
      await connectMySQL();
      await connectMongoDB();
    }
    
    app.listen(PORT, () => {
      console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
      console.log(`📍 Ambiente: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    console.error('❌ Error al iniciar el servidor:', error);
    process.exit(1);
  }
};

startServer();
