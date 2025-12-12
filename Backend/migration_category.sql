-- Migración: Agregar campo category a la tabla spaces
-- Fecha: 2025-12-01
-- Descripción: Permite a los propietarios categorizar sus espacios

-- Agregar columna category
ALTER TABLE spaces 
ADD COLUMN category VARCHAR(50) DEFAULT 'meetings'
COMMENT 'Categoría del espacio: private, meetings, teams, events, coworking, studio, training';

-- Actualizar espacios existentes basándose en su capacidad (opcional)
-- Esto asigna categorías automáticas a espacios que ya existen
UPDATE spaces SET category = 'events' WHERE capacity >= 80;
UPDATE spaces SET category = 'teams' WHERE capacity >= 40 AND capacity < 80;
UPDATE spaces SET category = 'meetings' WHERE capacity >= 15 AND capacity < 40;
UPDATE spaces SET category = 'private' WHERE capacity < 15;

-- Verificar la migración
SELECT id, name, capacity, category FROM spaces;
