require('dotenv').config();
const { connectMySQL, connectMongoDB } = require('./src/config/database');
const User = require('./src/entities/User');
const Space = require('./src/entities/Space');
const Booking = require('./src/entities/Booking');

const seedData = async () => {
  try {
    console.log('🌱 Iniciando seed de datos...\n');

    // Conectar a las bases de datos
    await connectMySQL();
    await connectMongoDB();

    // 1. Crear usuario admin
    console.log('👤 Creando usuario admin...');
    const [admin, adminCreated] = await User.findOrCreate({
      where: { email: 'admin@spazio.com' },
      defaults: {
        name: 'Administrador',
        email: 'admin@spazio.com',
        password: 'admin123', // Se encripta automáticamente con el hook
        role: 'admin'
      }
    });
    console.log(adminCreated ? '✅ Admin creado' : 'ℹ️  Admin ya existe');

    // 2. Crear usuario normal
    console.log('👤 Creando usuario normal...');
    const [user, userCreated] = await User.findOrCreate({
      where: { email: 'user@spazio.com' },
      defaults: {
        name: 'Usuario Demo',
        email: 'user@spazio.com',
        password: 'user123',
        role: 'user'
      }
    });
    console.log(userCreated ? '✅ Usuario creado' : 'ℹ️  Usuario ya existe');

    // 3. Crear espacios
    console.log('\n🏢 Creando espacios...');
    const spacesData = [
      {
        name: 'Sala de Reuniones A',
        description: 'Sala equipada con proyector, pizarra y capacidad para 10 personas',
        capacity: 10
      },
      {
        name: 'Sala de Conferencias',
        description: 'Sala grande para eventos y presentaciones con capacidad para 50 personas',
        capacity: 50
      },
      {
        name: 'Sala de Capacitación',
        description: 'Espacio ideal para talleres y capacitaciones con 20 sillas',
        capacity: 20
      },
      {
        name: 'Espacio de Coworking',
        description: 'Área abierta para trabajo colaborativo',
        capacity: 30
      }
    ];

    const spaces = [];
    for (const spaceData of spacesData) {
      const [space, created] = await Space.findOrCreate({
        where: { name: spaceData.name },
        defaults: spaceData
      });
      spaces.push(space);
      console.log(created ? `✅ ${spaceData.name}` : `ℹ️  ${spaceData.name} ya existe`);
    }

    // 4. Crear algunas reservas de ejemplo
    console.log('\n📅 Creando reservas de ejemplo...');
    
    // Limpiar reservas anteriores del seed
    await Booking.deleteMany({ notes: { $regex: /ejemplo/i } });

    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(10, 0, 0, 0);

    const bookingsData = [
      {
        spaceId: spaces[0].id,
        userId: user.id,
        startTime: new Date(tomorrow.getTime()),
        endTime: new Date(tomorrow.getTime() + 2 * 60 * 60 * 1000), // +2 horas
        notes: 'Reserva de ejemplo - Reunión de equipo',
        status: 'confirmed'
      },
      {
        spaceId: spaces[1].id,
        userId: admin.id,
        startTime: new Date(tomorrow.getTime() + 4 * 60 * 60 * 1000), // +4 horas
        endTime: new Date(tomorrow.getTime() + 6 * 60 * 60 * 1000), // +6 horas
        notes: 'Reserva de ejemplo - Presentación trimestral',
        status: 'confirmed'
      }
    ];

    for (const bookingData of bookingsData) {
      await Booking.create(bookingData);
      console.log(`✅ Reserva creada para ${spaces.find(s => s.id === bookingData.spaceId)?.name}`);
    }

    console.log('\n✅ Seed completado exitosamente!\n');
    console.log('📝 Credenciales de acceso:');
    console.log('   Admin: admin@spazio.com / admin123');
    console.log('   Usuario: user@spazio.com / user123\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error en seed:', error);
    process.exit(1);
  }
};

seedData();
