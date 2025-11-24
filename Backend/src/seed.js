require('dotenv').config();
const { connectMySQL, connectMongoDB } = require('./config/database');
const User = require('./entities/User');
const Space = require('./entities/Space');
const Booking = require('./entities/Booking');

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

    // 3. Crear usuarios owner (propietarios de espacios)
    console.log('🏢 Creando usuarios propietarios...');
    const [owner1, owner1Created] = await User.findOrCreate({
      where: { email: 'owner1@spazio.com' },
      defaults: {
        name: 'María González',
        email: 'owner1@spazio.com',
        password: 'owner123',
        role: 'owner',
        businessName: 'CoWork Central',
        businessDescription: 'Espacios de coworking y oficinas privadas en el centro de la ciudad',
        isVerified: true // Pre-aprobado para seed
      }
    });
    console.log(owner1Created ? '✅ Owner 1 creado (CoWork Central)' : 'ℹ️  Owner 1 ya existe');

    const [owner2, owner2Created] = await User.findOrCreate({
      where: { email: 'owner2@spazio.com' },
      defaults: {
        name: 'Carlos Rodríguez',
        email: 'owner2@spazio.com',
        password: 'owner123',
        role: 'owner',
        businessName: 'Salas Premium',
        businessDescription: 'Salas de conferencias y eventos corporativos de alta gama',
        isVerified: true // Pre-aprobado para seed
      }
    });
    console.log(owner2Created ? '✅ Owner 2 creado (Salas Premium)' : 'ℹ️  Owner 2 ya existe');

    // 4. Owner pendiente de aprobación
    const [ownerPending, ownerPendingCreated] = await User.findOrCreate({
      where: { email: 'pending@spazio.com' },
      defaults: {
        name: 'Ana Martínez',
        email: 'pending@spazio.com',
        password: 'pending123',
        role: 'owner',
        businessName: 'Espacios Creativos',
        businessDescription: 'Estudios para artistas y creativos',
        isVerified: false // Pendiente de aprobación
      }
    });
    console.log(ownerPendingCreated ? '⏳ Owner pendiente creado' : 'ℹ️  Owner pendiente ya existe');

    // 5. Crear espacios
    console.log('\n🏢 Creando espacios...');
    const spacesData = [
      {
        name: 'Sala de Reuniones A',
        description: 'Sala equipada con proyector, pizarra y capacidad para 10 personas',
        capacity: 10,
        ownerId: owner1.id
      },
      {
        name: 'Sala de Conferencias',
        description: 'Sala grande para eventos y presentaciones con capacidad para 50 personas',
        capacity: 50,
        ownerId: owner2.id
      },
      {
        name: 'Sala de Capacitación',
        description: 'Espacio ideal para talleres y capacitaciones con 20 sillas',
        capacity: 20,
        ownerId: owner1.id
      },
      {
        name: 'Espacio de Coworking',
        description: 'Área abierta para trabajo colaborativo',
        capacity: 30,
        ownerId: owner2.id
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
    console.log('   Usuario: user@spazio.com / user123');
    console.log('   Owner 1 (Verificado): owner1@spazio.com / owner123');
    console.log('   Owner 2 (Verificado): owner2@spazio.com / owner123');
    console.log('   Owner Pendiente: pending@spazio.com / pending123\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error en seed:', error);
    process.exit(1);
  }
};

seedData();
