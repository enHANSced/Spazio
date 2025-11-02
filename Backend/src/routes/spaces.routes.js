const express = require('express');
const router = express.Router();
const spacesController = require('../controllers/spaces.controller');
const { authMiddleware, isAdmin } = require('../middleware/auth.middleware');

// Públicas
router.get('/', spacesController.list);
router.get('/:id', spacesController.getById);

// Admin
router.post('/', authMiddleware, isAdmin, spacesController.create);
router.put('/:id', authMiddleware, isAdmin, spacesController.update);
router.delete('/:id', authMiddleware, isAdmin, spacesController.remove);

module.exports = router;
