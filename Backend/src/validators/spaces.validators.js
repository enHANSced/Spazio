const { body, param } = require('express-validator');

/**
 * Validaciones para crear espacio
 */
const validateCreateSpace = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('El nombre del espacio es requerido')
    .isLength({ min: 3, max: 120 })
    .withMessage('El nombre debe tener entre 3 y 120 caracteres'),

  body('description')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('La descripción no puede exceder 1000 caracteres'),

  body('capacity')
    .notEmpty()
    .withMessage('La capacidad es requerida')
    .isInt({ min: 1, max: 10000 })
    .withMessage('La capacidad debe ser un número entero entre 1 y 10000')
    .toInt()
];

/**
 * Validaciones para actualizar espacio
 */
const validateUpdateSpace = [
  param('id')
    .isUUID()
    .withMessage('ID de espacio inválido'),

  body('name')
    .optional()
    .trim()
    .isLength({ min: 3, max: 120 })
    .withMessage('El nombre debe tener entre 3 y 120 caracteres'),

  body('description')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('La descripción no puede exceder 1000 caracteres'),

  body('capacity')
    .optional()
    .isInt({ min: 1, max: 10000 })
    .withMessage('La capacidad debe ser un número entero entre 1 y 10000')
    .toInt(),

  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive debe ser un valor booleano')
    .toBoolean()
];

/**
 * Validación de ID de espacio
 */
const validateSpaceId = [
  param('id')
    .isUUID()
    .withMessage('ID de espacio inválido')
];

module.exports = {
  validateCreateSpace,
  validateUpdateSpace,
  validateSpaceId
};
