const usersUseCase = require('../use-cases/users.usecase');

class UsersController {
  /**
   * Listar todos los usuarios (admin)
   */
  async list(req, res) {
    try {
      const filters = {
        role: req.query.role,
        isVerified: req.query.isVerified === 'true' ? true : req.query.isVerified === 'false' ? false : undefined,
        isActive: req.query.isActive === 'true' ? true : req.query.isActive === 'false' ? false : undefined
      };
      
      const data = await usersUseCase.list(filters);
      res.status(200).json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

  /**
   * Obtener usuario por ID
   */
  async getById(req, res) {
    try {
      const data = await usersUseCase.getById(req.params.id);
      res.status(200).json({ success: true, data });
    } catch (error) {
      res.status(404).json({ success: false, message: error.message });
    }
  }

  /**
   * Obtener lista de owners pendientes (admin)
   */
  async getPendingOwners(req, res) {
    try {
      const data = await usersUseCase.getPendingOwners();
      res.status(200).json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

  /**
   * Aprobar o rechazar verificación de owner (admin)
   */
  async verifyOwner(req, res) {
    try {
      const { isVerified } = req.body;
      const data = await usersUseCase.verifyOwner(req.params.id, isVerified);
      
      const message = isVerified 
        ? 'Propietario verificado exitosamente' 
        : 'Verificación de propietario revocada';
      
      res.status(200).json({ success: true, message, data });
    } catch (error) {
      const status = error.message.includes('no encontrado') ? 404 : 400;
      res.status(status).json({ success: false, message: error.message });
    }
  }

  /**
   * Actualizar perfil de usuario autenticado
   */
  async updateMyProfile(req, res) {
    try {
      const data = await usersUseCase.updateProfile(req.user.id, req.body);
      res.status(200).json({ success: true, message: 'Perfil actualizado', data });
    } catch (error) {
      res.status(400).json({ success: false, message: error.message });
    }
  }

  /**
   * Obtener perfil del usuario autenticado
   */
  async getMyProfile(req, res) {
    try {
      // El usuario ya está en req.user desde el middleware
      res.status(200).json({ success: true, data: req.user.toJSON() });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }
}

module.exports = new UsersController();
