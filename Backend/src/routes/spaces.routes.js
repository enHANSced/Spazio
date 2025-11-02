const express = require('express');
const router = express.Router();
const spacesController = require('../controllers/spaces.controller');
const { authMiddleware, isAdmin } = require('../middleware/auth.middleware');
const { handleValidationErrors } = require('../middleware/validation.middleware');
const { validateCreateSpace, validateUpdateSpace, validateSpaceId } = require('../validators/spaces.validators');

// Públicas
router.get('/', spacesController.list);
router.get('/:id', validateSpaceId, handleValidationErrors, spacesController.getById);

// Admin
router.post('/', authMiddleware, isAdmin, validateCreateSpace, handleValidationErrors, spacesController.create);
router.put('/:id', authMiddleware, isAdmin, validateUpdateSpace, handleValidationErrors, spacesController.update);
router.delete('/:id', authMiddleware, isAdmin, validateSpaceId, handleValidationErrors, spacesController.remove);

module.exports = router;
