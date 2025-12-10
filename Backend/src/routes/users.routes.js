const express = require('express');
const router = express.Router();
const usersController = require('../controllers/users.controller');
const { authMiddleware, isAdmin } = require('../middleware/auth.middleware');
const { handleValidationErrors } = require('../middleware/validation.middleware');
const { body, param } = require('express-validator');

// Validaciones
const validateUserId = [
  param('id').isUUID().withMessage('ID de usuario inválido')
];

const validateVerifyOwner = [
  param('id').isUUID().withMessage('ID de usuario inválido'),
  body('isVerified').isBoolean().withMessage('isVerified debe ser un booleano')
];

// Lista de bancos de Honduras
const HONDURAS_BANKS = [
  'BAC Honduras',
  'Banco Atlántida',
  'Ficohsa',
  'Banpaís',
  'Banco de Occidente',
  'Banco Promerica',
  'Davivienda Honduras',
  'Banco de los Trabajadores',
  'Banco Lafise',
  'Banco Ficensa',
  'Otro'
];

const validateUpdateProfile = [
  body('name').optional().trim().isLength({ min: 2, max: 100 }).withMessage('El nombre debe tener entre 2 y 100 caracteres'),
  body('businessName').optional().trim().isLength({ min: 2, max: 150 }).withMessage('El nombre del negocio debe tener entre 2 y 150 caracteres'),
  body('businessDescription').optional().trim().isLength({ max: 1000 }).withMessage('La descripción no puede exceder 1000 caracteres'),
  body('phone').optional().trim().isLength({ max: 20 }).withMessage('El teléfono no puede exceder 20 caracteres'),
  body('whatsappNumber').optional().trim().isLength({ max: 20 }).withMessage('El WhatsApp no puede exceder 20 caracteres'),
  body('instagram').optional({ checkFalsy: true }).trim().isURL().withMessage('Instagram debe ser una URL válida'),
  body('facebook').optional({ checkFalsy: true }).trim().isURL().withMessage('Facebook debe ser una URL válida'),
  body('linkedin').optional({ checkFalsy: true }).trim().isURL().withMessage('LinkedIn debe ser una URL válida'),
  // Validaciones de información bancaria para owners
  body('bankName').optional({ checkFalsy: true }).trim().isIn(HONDURAS_BANKS).withMessage('Debe seleccionar un banco válido de Honduras'),
  body('bankAccountType').optional({ checkFalsy: true }).isIn(['ahorro_lempiras', 'ahorro_dolares', 'corriente_lempiras', 'corriente_dolares']).withMessage('Tipo de cuenta inválido'),
  body('bankAccountNumber').optional({ checkFalsy: true }).trim().isLength({ min: 6, max: 30 }).withMessage('El número de cuenta debe tener entre 6 y 30 caracteres'),
  body('bankAccountHolder').optional({ checkFalsy: true }).trim().isLength({ min: 2, max: 150 }).withMessage('El nombre del titular debe tener entre 2 y 150 caracteres')
];

const validateAdminUpdate = [
  param('id').isUUID().withMessage('ID de usuario inválido'),
  body('name').optional().trim().isLength({ min: 2, max: 100 }).withMessage('El nombre debe tener entre 2 y 100 caracteres'),
  body('role').optional().isIn(['user', 'owner', 'admin']).withMessage('Rol inválido'),
  body('isActive').optional().isBoolean().withMessage('isActive debe ser un booleano'),
  body('isVerified').optional().isBoolean().withMessage('isVerified debe ser un booleano'),
  body('businessName').optional().trim().isLength({ max: 150 }).withMessage('El nombre del negocio no puede exceder 150 caracteres'),
  body('businessDescription').optional().trim().isLength({ max: 1000 }).withMessage('La descripción no puede exceder 1000 caracteres'),
  body('phone').optional().trim().isLength({ max: 20 }).withMessage('El teléfono no puede exceder 20 caracteres'),
  body('whatsappNumber').optional().trim().isLength({ max: 20 }).withMessage('El WhatsApp no puede exceder 20 caracteres')
];

// Rutas de perfil del usuario autenticado
router.get('/me', authMiddleware, usersController.getMyProfile);
router.put('/me', authMiddleware, validateUpdateProfile, handleValidationErrors, usersController.updateMyProfile);

// Rutas admin - Gestión de usuarios
router.get('/', authMiddleware, isAdmin, usersController.list);
router.get('/pending-owners', authMiddleware, isAdmin, usersController.getPendingOwners);
router.get('/owner/:id/details', authMiddleware, isAdmin, validateUserId, handleValidationErrors, usersController.getOwnerDetails);
router.get('/:id', authMiddleware, isAdmin, validateUserId, handleValidationErrors, usersController.getById);
router.put('/:id', authMiddleware, isAdmin, validateAdminUpdate, handleValidationErrors, usersController.updateByAdmin);
router.patch('/:id/verify', authMiddleware, isAdmin, validateVerifyOwner, handleValidationErrors, usersController.verifyOwner);
router.patch('/:id/toggle', authMiddleware, isAdmin, validateUserId, handleValidationErrors, usersController.toggleActive);

module.exports = router;
