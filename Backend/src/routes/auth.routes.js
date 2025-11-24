const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authMiddleware } = require('../middleware/auth.middleware');
const { handleValidationErrors } = require('../middleware/validation.middleware');
const { validateRegister, validateLogin } = require('../validators/auth.validators');

// Rutas públicas
router.post('/register', validateRegister, handleValidationErrors, authController.register);
router.post('/login', validateLogin, handleValidationErrors, authController.login);

// Rutas protegidas
router.get('/profile', authMiddleware, authController.getProfile);

module.exports = router;
