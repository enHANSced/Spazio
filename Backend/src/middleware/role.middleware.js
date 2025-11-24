const Space = require('../entities/Space');

/**
 * Middleware para verificar que el usuario tiene rol owner
 */
const isOwner = (req, res, next) => {
  if (req.user.role !== 'owner' && req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Acceso denegado. Se requiere rol de propietario.'
    });
  }
  next();
};

/**
 * Middleware para verificar que el usuario owner está verificado
 */
const isVerifiedOwner = (req, res, next) => {
  if (req.user.role === 'owner' && !req.user.isVerified) {
    return res.status(403).json({
      success: false,
      message: 'Tu cuenta de propietario está pendiente de aprobación por un administrador.'
    });
  }
  next();
};

/**
 * Middleware para verificar que el usuario es owner O admin
 */
const isOwnerOrAdmin = (req, res, next) => {
  const allowedRoles = ['owner', 'admin'];
  if (!allowedRoles.includes(req.user.role)) {
    return res.status(403).json({
      success: false,
      message: 'Acceso denegado. Se requieren permisos de propietario o administrador.'
    });
  }
  next();
};

/**
 * Middleware para verificar que el usuario es dueño del recurso específico
 * o es admin (admin tiene acceso total)
 */
const isResourceOwner = (resourceType) => async (req, res, next) => {
  try {
    // Admin siempre tiene acceso
    if (req.user.role === 'admin') {
      return next();
    }

    const resourceId = req.params.id;
    
    if (resourceType === 'space') {
      const space = await Space.findByPk(resourceId);
      
      if (!space) {
        return res.status(404).json({
          success: false,
          message: 'Espacio no encontrado'
        });
      }
      
      // Verificar que el usuario es el dueño del espacio
      if (space.ownerId !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: 'No tienes permiso para modificar este espacio. Solo puedes gestionar tus propios espacios.'
        });
      }
    }
    
    next();
  } catch (error) {
    console.error('Error en isResourceOwner:', error);
    res.status(500).json({
      success: false,
      message: 'Error al verificar permisos de propiedad'
    });
  }
};

module.exports = {
  isOwner,
  isVerifiedOwner,
  isOwnerOrAdmin,
  isResourceOwner
};
