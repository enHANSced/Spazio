const { body } = require('express-validator');

/**
 * Validaciones para registro de usuario
 */
const validateRegister = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('El nombre es requerido')
    .isLength({ min: 2, max: 100 })
    .withMessage('El nombre debe tener entre 2 y 100 caracteres')
    .matches(/^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$/)
    .withMessage('El nombre solo puede contener letras y espacios'),

  body('email')
    .trim()
    .notEmpty()
    .withMessage('El email es requerido')
    .isEmail()
    .withMessage('Debe ser un email válido')
    .normalizeEmail()
    .isLength({ max: 100 })
    .withMessage('El email no puede exceder 100 caracteres'),

  body('password')
    .notEmpty()
    .withMessage('La contraseña es requerida')
    .isLength({ min: 6, max: 50 })
    .withMessage('La contraseña debe tener entre 6 y 50 caracteres')
    .matches(/^(?=.*[a-z])(?=.*[A-Z0-9])/)
    .withMessage('La contraseña debe contener al menos una letra minúscula y una mayúscula o número'),

  body('role')
    .optional()
    .isIn(['user', 'owner'])
    .withMessage('El rol debe ser "user" o "owner"'),

  body('businessName')
    .if(body('role').equals('owner'))
    .trim()
    .notEmpty()
    .withMessage('El nombre del negocio es requerido para propietarios')
    .isLength({ min: 2, max: 150 })
    .withMessage('El nombre del negocio debe tener entre 2 y 150 caracteres'),

  body('businessDescription')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('La descripción del negocio no puede exceder 1000 caracteres'),

  body('phone')
    .if(body('role').equals('owner'))
    .trim()
    .notEmpty()
    .withMessage('El teléfono de contacto es requerido para propietarios')
    .isLength({ min: 8, max: 20 })
    .withMessage('El teléfono debe tener entre 8 y 20 caracteres')
    .matches(/^[+]?[0-9\s-]+$/)
    .withMessage('El teléfono solo puede contener números, espacios, guiones y opcionalmente + al inicio')
];

/**
 * Validaciones para login
 */
const validateLogin = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('El email es requerido')
    .isEmail()
    .withMessage('Debe ser un email válido')
    .normalizeEmail(),

  body('password')
    .notEmpty()
    .withMessage('La contraseña es requerida')
];

module.exports = {
  validateRegister,
  validateLogin
};
