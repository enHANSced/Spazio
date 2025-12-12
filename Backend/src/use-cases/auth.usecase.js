const jwt = require('jsonwebtoken');
const User = require('../entities/User');

class AuthUseCase {
  // Registrar nuevo usuario
  async register(userData) {
    const { name, email, password, role, businessName, businessDescription, phone } = userData;

    // Validar datos
    if (!name || !email || !password) {
      throw new Error('Todos los campos son requeridos');
    }

    // Validar rol
    const allowedRoles = ['user', 'owner'];
    const userRole = role || 'user';
    
    if (!allowedRoles.includes(userRole)) {
      throw new Error('Rol inválido. Solo se permiten roles: user, owner');
    }

    // Si es owner, validar campos de negocio
    if (userRole === 'owner') {
      if (!businessName) {
        throw new Error('El nombre del negocio es requerido para propietarios');
      }
      if (!phone) {
        throw new Error('El teléfono de contacto es requerido para propietarios');
      }
    }

    // Verificar si el usuario ya existe
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      throw new Error('El email ya está registrado');
    }

    // Crear usuario
    const user = await User.create({
      name,
      email,
      password,
      role: userRole,
      businessName: userRole === 'owner' ? businessName : null,
      businessDescription: userRole === 'owner' ? businessDescription : null,
      phone: userRole === 'owner' ? phone : null,
      isVerified: userRole === 'owner' ? false : true // Owners requieren aprobación
    });

    // Generar token
    const token = this.generateToken(user.id);

    return {
      user: user.toJSON(),
      token,
      message: userRole === 'owner' 
        ? 'Cuenta de propietario creada. Pendiente de aprobación por un administrador.' 
        : 'Cuenta creada exitosamente'
    };
  }

  // Login de usuario
  async login(credentials) {
    const { email, password } = credentials;

    // Validar datos
    if (!email || !password) {
      throw new Error('Email y contraseña son requeridos');
    }

    // Buscar usuario
    const user = await User.findOne({ where: { email } });
    if (!user) {
      throw new Error('Credenciales inválidas');
    }

    // Verificar contraseña
    const isValidPassword = await user.comparePassword(password);
    if (!isValidPassword) {
      throw new Error('Credenciales inválidas');
    }

    // Verificar si está activo
    if (!user.isActive) {
      throw new Error('Usuario inactivo');
    }

    // Generar token
    const token = this.generateToken(user.id);

    return {
      user: user.toJSON(),
      token
    };
  }

  // Obtener perfil de usuario
  async getProfile(userId) {
    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('Usuario no encontrado');
    }
    return user.toJSON();
  }

  // Generar JWT
  generateToken(userId) {
    return jwt.sign(
      { userId },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );
  }
}

module.exports = new AuthUseCase();
