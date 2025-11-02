const spacesUseCase = require('../use-cases/spaces.usecase');

class SpacesController {
  async list(req, res) {
    try {
      const data = await spacesUseCase.list();
      res.status(200).json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

  async getById(req, res) {
    try {
      const data = await spacesUseCase.getById(req.params.id);
      res.status(200).json({ success: true, data });
    } catch (error) {
      res.status(404).json({ success: false, message: error.message });
    }
  }

  async create(req, res) {
    try {
      const data = await spacesUseCase.create(req.body);
      res.status(201).json({ success: true, message: 'Espacio creado', data });
    } catch (error) {
      res.status(400).json({ success: false, message: error.message });
    }
  }

  async update(req, res) {
    try {
      const data = await spacesUseCase.update(req.params.id, req.body);
      res.status(200).json({ success: true, message: 'Espacio actualizado', data });
    } catch (error) {
      const status = error.message.includes('no encontrado') ? 404 : 400;
      res.status(status).json({ success: false, message: error.message });
    }
  }

  async remove(req, res) {
    try {
      const data = await spacesUseCase.remove(req.params.id);
      res.status(200).json({ success: true, message: 'Espacio eliminado', data });
    } catch (error) {
      res.status(404).json({ success: false, message: error.message });
    }
  }
}

module.exports = new SpacesController();
