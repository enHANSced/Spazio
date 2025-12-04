const { cloudinary, cloudinaryEnabled } = require('../config/cloudinary');

/**
 * Normaliza una entrada de imagen.
 * - Si empieza con 'data:' se sube a Cloudinary (si habilitado).
 * - Si es una URL http(s) se usa directamente.
 * - Si Cloudinary está deshabilitado, cualquier base64 se rechaza salvo que SKIP_CLOUDINARY=true (entonces se ignora y no se guarda).
 */
async function uploadImage(input) {
  if (!input) return null;
  const isBase64 = typeof input === 'string' && input.startsWith('data:');
  const isURL = typeof input === 'string' && /^https?:\/\//.test(input);

  if (isBase64) {
    if (!cloudinaryEnabled) {
      // Cloudinary deshabilitado: ignoramos imagen base64
      return null;
    }
    try {
      const res = await cloudinary.uploader.upload(input, {
        folder: 'spazio/spaces',
        resource_type: 'image'
      });
      return { url: res.secure_url, publicId: res.public_id };
    } catch (err) {
      console.error('Error subiendo imagen a Cloudinary:', err.message);
      throw new Error('No se pudo subir una de las imágenes');
    }
  }

  if (isURL) {
    // No subimos, solo registramos la URL sin publicId
    return { url: input, publicId: null };
  }

  return null;
}

/**
 * Subir un buffer (desde multer) a Cloudinary
 */
async function uploadBuffer(buffer, folder = 'spazio/general', options = {}) {
  if (!buffer) {
    throw new Error('No se proporcionó un buffer para subir');
  }

  if (!cloudinaryEnabled) {
    // En desarrollo sin Cloudinary, retornar una URL placeholder
    console.warn('Cloudinary deshabilitado: usando placeholder para upload de buffer');
    return {
      secure_url: `https://via.placeholder.com/800x600?text=Transfer+Proof`,
      public_id: `placeholder_${Date.now()}`
    };
  }

  return new Promise((resolve, reject) => {
    const uploadOptions = {
      folder: `spazio/${folder}`,
      resource_type: 'image',
      ...options
    };

    cloudinary.uploader.upload_stream(uploadOptions, (error, result) => {
      if (error) {
        console.error('Error subiendo buffer a Cloudinary:', error.message);
        reject(new Error('No se pudo subir la imagen'));
      } else {
        resolve(result);
      }
    }).end(buffer);
  });
}

async function uploadImages(inputs) {
  if (!Array.isArray(inputs)) return [];
  const results = [];
  for (const item of inputs) {
    const uploaded = await uploadImage(item);
    if (uploaded) results.push(uploaded);
  }
  return results;
}

async function deleteImage(publicId) {
  if (!publicId || !cloudinaryEnabled) return false;
  try {
    await cloudinary.uploader.destroy(publicId);
    return true;
  } catch (err) {
    console.error('Error eliminando imagen Cloudinary:', err.message);
    return false;
  }
}

module.exports = {
  uploadImage,
  uploadImages,
  uploadBuffer,
  deleteImage,
  cloudinaryEnabled
};
