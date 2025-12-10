-- Migration: Agregar campos de información bancaria para owners
-- Fecha: 2024-12-09
-- Descripción: Permite a los owners configurar su información bancaria para recibir pagos por transferencia

-- Si la tabla ya tiene los campos con tipos anteriores, actualizar el tipo de cuenta
-- ALTER TABLE users MODIFY COLUMN bankAccountType ENUM('ahorro_lempiras', 'ahorro_dolares', 'corriente_lempiras', 'corriente_dolares') NULL COMMENT 'Tipo de cuenta bancaria';

-- Si la tabla NO tiene los campos, ejecutar:
-- ALTER TABLE users
-- ADD COLUMN bankName VARCHAR(100) NULL COMMENT 'Nombre del banco (BAC Honduras, Atlántida, Ficohsa, etc.)',
-- ADD COLUMN bankAccountType ENUM('ahorro_lempiras', 'ahorro_dolares', 'corriente_lempiras', 'corriente_dolares') NULL COMMENT 'Tipo de cuenta bancaria',
-- ADD COLUMN bankAccountNumber VARCHAR(30) NULL COMMENT 'Número de cuenta bancaria',
-- ADD COLUMN bankAccountHolder VARCHAR(150) NULL COMMENT 'Nombre del titular de la cuenta';

-- Verificar que los campos fueron agregados
DESCRIBE users;

-- Ejemplo de actualización para un owner (para pruebas)
-- UPDATE users SET 
--   bankName = 'BAC Honduras',
--   bankAccountType = 'ahorro_lempiras', 
--   bankAccountNumber = '123456789012',
--   bankAccountHolder = 'Juan Pérez'
-- WHERE id = 'uuid-del-owner' AND role = 'owner';
