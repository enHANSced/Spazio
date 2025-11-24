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
  deleteImage,
  cloudinaryEnabled
};
