const express = require('express');
const router = express.Router();
const spacesController = require('../controllers/spaces.controller');
const { authMiddleware, isAdmin } = require('../middleware/auth.middleware');
const { isOwnerOrAdmin, isVerifiedOwner, isResourceOwner } = require('../middleware/role.middleware');
const { handleValidationErrors } = require('../middleware/validation.middleware');
const { validateCreateSpace, validateUpdateSpace, validateSpaceId } = require('../validators/spaces.validators');

// Rutas admin - Deben ir antes de rutas con parámetros
router.get('/admin/all', 
  authMiddleware, 
  isAdmin, 
  spacesController.listAll
);

router.patch('/admin/:id/toggle', 
  authMiddleware, 
  isAdmin, 
  validateSpaceId, 
  handleValidationErrors, 
  spacesController.toggleActive
);

// Rutas públicas - Cualquiera puede ver espacios
router.get('/', spacesController.list);
router.get('/:id', validateSpaceId, handleValidationErrors, spacesController.getById);

// Rutas para Owners - Gestión de sus propios espacios
router.get('/owner/my-spaces', 
  authMiddleware, 
  isOwnerOrAdmin,
  isVerifiedOwner,
  spacesController.getMySpaces
);

router.post('/', 
  authMiddleware, 
  isOwnerOrAdmin,
  isVerifiedOwner,
  validateCreateSpace, 
  handleValidationErrors, 
  spacesController.create
);

router.put('/:id', 
  authMiddleware, 
  isResourceOwner('space'),
  isVerifiedOwner,
  validateUpdateSpace, 
  handleValidationErrors, 
  spacesController.update
);

router.delete('/:id', 
  authMiddleware, 
  isResourceOwner('space'),
  validateSpaceId, 
  handleValidationErrors, 
  spacesController.remove
);

module.exports = router;
