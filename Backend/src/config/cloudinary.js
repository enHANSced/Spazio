const cloudinaryLib = require('cloudinary').v2;

const hasCreds = process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_SECRET;
const skip = process.env.SKIP_CLOUDINARY === 'true';

let isEnabled = false;

if (!skip && hasCreds) {
  cloudinaryLib.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true
  });
  isEnabled = true;
} else {
  if (skip) {
    console.log('⚠️  Cloudinary deshabilitado por SKIP_CLOUDINARY');
  } else {
    console.log('⚠️  Cloudinary no configurado: faltan credenciales');
  }
}

module.exports = {
  cloudinary: cloudinaryLib,
  cloudinaryEnabled: isEnabled
};
