-- Migración para Sistema de Roles Owner
-- Fecha: 2025-11-06
-- IMPORTANTE: Esta migración es segura para bases de datos con datos existentes

-- 1. Agregar nuevos campos a la tabla users
ALTER TABLE users 
  MODIFY COLUMN role ENUM('user', 'owner', 'admin') DEFAULT 'user',
  ADD COLUMN IF NOT EXISTS isVerified BOOLEAN DEFAULT TRUE COMMENT 'Para usuarios owner, requiere aprobación de admin',
  ADD COLUMN IF NOT EXISTS businessName VARCHAR(150) NULL COMMENT 'Nombre del negocio para usuarios owner',
  ADD COLUMN IF NOT EXISTS businessDescription TEXT NULL COMMENT 'Descripción del negocio para usuarios owner';

-- 2. Verificar si la columna ownerId existe, si no, crearla
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'spazio_db' 
                   AND TABLE_NAME = 'spaces' 
                   AND COLUMN_NAME = 'ownerId');

-- 3. Agregar columna ownerId si no existe
SET @query = IF(@col_exists = 0,
    'ALTER TABLE spaces ADD COLUMN ownerId CHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL AFTER capacity',
    'SELECT "ownerId ya existe" AS info'
);
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. Asignar espacios existentes al usuario admin
UPDATE spaces s
SET s.ownerId = (SELECT id FROM users WHERE role = 'admin' LIMIT 1)
WHERE s.ownerId IS NULL;

-- 5. Hacer la columna NOT NULL si aún es NULL
ALTER TABLE spaces 
  MODIFY COLUMN ownerId CHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL;

-- 6. Eliminar constraint existente si existe
SET @fk_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
                  WHERE TABLE_SCHEMA = 'spazio_db' 
                  AND TABLE_NAME = 'spaces' 
                  AND CONSTRAINT_NAME = 'fk_spaces_owner');

SET @drop_fk = IF(@fk_exists > 0,
    'ALTER TABLE spaces DROP FOREIGN KEY fk_spaces_owner',
    'SELECT "FK no existe" AS info'
);
PREPARE stmt FROM @drop_fk;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 7. Agregar la constraint de foreign key
ALTER TABLE spaces 
  ADD CONSTRAINT fk_spaces_owner 
    FOREIGN KEY (ownerId) REFERENCES users(id) ON DELETE CASCADE;

-- 8. Crear índice para mejorar consultas de espacios por propietario
CREATE INDEX IF NOT EXISTS idx_spaces_owner ON spaces(ownerId);

-- 9. Crear índice compuesto para consultas de owners verificados
CREATE INDEX IF NOT EXISTS idx_users_role_verified ON users(role, isVerified);

-- Verificar cambios
SELECT '✅ Migración completada. Verificando cambios...' AS status;
SELECT 'Campos en users:' AS info;
SHOW COLUMNS FROM users WHERE Field IN ('role', 'isVerified', 'businessName', 'businessDescription');
SELECT 'Campos en spaces:' AS info;
SHOW COLUMNS FROM spaces WHERE Field = 'ownerId';
SELECT 'Foreign Keys en spaces:' AS info;
SELECT 
    CONSTRAINT_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'spazio_db' 
AND TABLE_NAME = 'spaces' 
AND CONSTRAINT_NAME = 'fk_spaces_owner';
SELECT 'Espacios con owners asignados:' AS info;
SELECT COUNT(*) as total_spaces, COUNT(ownerId) as spaces_with_owner FROM spaces;
