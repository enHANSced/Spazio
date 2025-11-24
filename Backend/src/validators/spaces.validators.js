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
    .toInt(),

  body('pricePerHour')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('El precio por hora debe ser un número positivo')
    .toFloat(),

  body('amenities')
    .optional()
    .isArray()
    .withMessage('Las amenidades deben ser un array'),

  body('rules')
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage('Las reglas no pueden exceder 2000 caracteres'),

  body('virtualTourUrl')
    .optional()
    .trim()
    .isURL()
    .withMessage('La URL del tour virtual debe ser válida'),

  body('cancellationPolicy')
    .optional()
    .isIn(['flexible', 'moderate', 'strict'])
    .withMessage('La política de cancelación debe ser: flexible, moderate o strict'),

  body('address')
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage('La dirección no puede exceder 255 caracteres'),

  body('city')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('La ciudad no puede exceder 100 caracteres'),

  body('state')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('El departamento no puede exceder 100 caracteres'),

  body('country')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('El país no puede exceder 100 caracteres'),

  body('latitude')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage('La latitud debe estar entre -90 y 90')
    .toFloat(),

  body('longitude')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage('La longitud debe estar entre -180 y 180')
    .toFloat(),

  body('zipCode')
    .optional()
    .trim()
    .isLength({ max: 10 })
    .withMessage('El código postal no puede exceder 10 caracteres'),

  body('workingHours')
    .optional()
    .isObject()
    .withMessage('Los horarios deben ser un objeto con start y end'),

  body('workingHours.start')
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('La hora de inicio debe tener formato HH:MM (24h)'),

  body('workingHours.end')
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('La hora de fin debe tener formato HH:MM (24h)')
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
    .toBoolean(),

  body('pricePerHour')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('El precio por hora debe ser un número positivo')
    .toFloat(),

  body('amenities')
    .optional()
    .isArray()
    .withMessage('Las amenidades deben ser un array'),

  body('rules')
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage('Las reglas no pueden exceder 2000 caracteres'),

  body('virtualTourUrl')
    .optional()
    .trim()
    .isURL()
    .withMessage('La URL del tour virtual debe ser válida'),

  body('cancellationPolicy')
    .optional()
    .isIn(['flexible', 'moderate', 'strict'])
    .withMessage('La política de cancelación debe ser: flexible, moderate o strict'),

  body('address')
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage('La dirección no puede exceder 255 caracteres'),

  body('city')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('La ciudad no puede exceder 100 caracteres'),

  body('state')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('El departamento no puede exceder 100 caracteres'),

  body('country')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('El país no puede exceder 100 caracteres'),

  body('latitude')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage('La latitud debe estar entre -90 y 90')
    .toFloat(),

  body('longitude')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage('La longitud debe estar entre -180 y 180')
    .toFloat(),

  body('zipCode')
    .optional()
    .trim()
    .isLength({ max: 10 })
    .withMessage('El código postal no puede exceder 10 caracteres'),

  body('workingHours')
    .optional()
    .isObject()
    .withMessage('Los horarios deben ser un objeto con start y end'),

  body('workingHours.start')
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('La hora de inicio debe tener formato HH:MM (24h)'),

  body('workingHours.end')
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('La hora de fin debe tener formato HH:MM (24h)')
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
