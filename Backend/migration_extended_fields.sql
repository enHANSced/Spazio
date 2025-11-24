-- Migración: Agregar campos extendidos a tablas spaces y users
-- Fecha: 23 de noviembre de 2025
-- Descripción: Agrega campos de ubicación, multimedia, contacto y configuración

USE spazio_db;

-- ============================================
-- TABLA: spaces
-- ============================================

-- Campos de ubicación (si no existen)
ALTER TABLE spaces 
ADD COLUMN IF NOT EXISTS address VARCHAR(255) NULL COMMENT 'Dirección completa del espacio',
ADD COLUMN IF NOT EXISTS city VARCHAR(100) NULL COMMENT 'Ciudad',
ADD COLUMN IF NOT EXISTS state VARCHAR(100) NULL COMMENT 'Departamento/Estado',
ADD COLUMN IF NOT EXISTS country VARCHAR(100) NULL DEFAULT 'Honduras' COMMENT 'País',
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8) NULL COMMENT 'Latitud GPS',
ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8) NULL COMMENT 'Longitud GPS',
ADD COLUMN IF NOT EXISTS zipCode VARCHAR(10) NULL COMMENT 'Código postal';

-- Campos de configuración y multimedia (si no existen)
ALTER TABLE spaces 
ADD COLUMN IF NOT EXISTS workingHours JSON NULL COMMENT 'Horario de operación: { start: "08:00", end: "22:00" }',
ADD COLUMN IF NOT EXISTS videos JSON NULL COMMENT 'Array de videos: [{ url, publicId, thumbnail }]',
ADD COLUMN IF NOT EXISTS images360 JSON NULL COMMENT 'Array de imágenes 360°: [{ url, publicId }]';

-- Actualizar valores por defecto para campos JSON que ya existen
UPDATE spaces SET amenities = '[]' WHERE amenities IS NULL OR amenities = '';
UPDATE spaces SET images = '[]' WHERE images IS NULL OR images = '';
UPDATE spaces SET workingHours = '{"start":"08:00","end":"22:00"}' WHERE workingHours IS NULL;
UPDATE spaces SET videos = '[]' WHERE videos IS NULL;
UPDATE spaces SET images360 = '[]' WHERE images360 IS NULL;

-- ============================================
-- TABLA: users
-- ============================================

-- Campos de contacto (si no existen)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS phone VARCHAR(20) NULL COMMENT 'Número de teléfono',
ADD COLUMN IF NOT EXISTS whatsappNumber VARCHAR(20) NULL COMMENT 'Número de WhatsApp (formato internacional: +504XXXXXXXX)';

-- ============================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================

-- Índice para búsquedas por ciudad
CREATE INDEX IF NOT EXISTS idx_spaces_city ON spaces(city);

-- Índice para búsquedas por país
CREATE INDEX IF NOT EXISTS idx_spaces_country ON spaces(country);

-- Índice compuesto para búsquedas geográficas (latitud + longitud)
CREATE INDEX IF NOT EXISTS idx_spaces_location ON spaces(latitude, longitude);

-- Índice para búsquedas por precio
CREATE INDEX IF NOT EXISTS idx_spaces_price ON spaces(pricePerHour);

-- ============================================
-- VALIDACIONES Y CONSTRAINTS
-- ============================================

-- Verificar que latitude esté en rango válido (-90, 90)
ALTER TABLE spaces 
ADD CONSTRAINT chk_latitude CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90));

-- Verificar que longitude esté en rango válido (-180, 180)
ALTER TABLE spaces 
ADD CONSTRAINT chk_longitude CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180));

-- Verificar que pricePerHour sea no negativo
ALTER TABLE spaces 
ADD CONSTRAINT chk_price_positive CHECK (pricePerHour IS NULL OR pricePerHour >= 0);

-- ============================================
-- RESUMEN
-- ============================================

SELECT 'Migración completada exitosamente' AS status;

-- Verificar estructura de spaces
SELECT 
    COLUMN_NAME, 
    COLUMN_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'spazio_db' 
  AND TABLE_NAME = 'spaces'
ORDER BY ORDINAL_POSITION;

-- Verificar estructura de users
SELECT 
    COLUMN_NAME, 
    COLUMN_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'spazio_db' 
  AND TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;
