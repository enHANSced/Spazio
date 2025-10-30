const jwt = require('jsonwebtoken');
const User = require('../entities/User');

class AuthUseCase {
  // Registrar nuevo usuario
  async register(userData) {
    const { name, email, password } = userData;

    // Validar datos
    if (!name || !email || !password) {
      throw new Error('Todos los campos son requeridos');
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
      role: 'user'
    });

    // Generar token
    const token = this.generateToken(user.id);

    return {
      user: user.toJSON(),
      token
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
