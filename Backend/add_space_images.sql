-- =====================================================
-- AGREGAR IMÁGENES REALISTAS A ESPACIOS - SPAZIO
-- Ejecutar: mysql -u root -p spazio_db < add_space_images.sql
-- =====================================================

-- Imágenes de Unsplash optimizadas para cada tipo de espacio
-- Formato: JSON array de strings (URLs)

-- =====================================================
-- INNOVAHUB - TEGUCIGALPA (Coworking & Salas modernas)
-- =====================================================

-- Sala de Innovación Principal
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&q=80',
    'https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=1200&q=80',
    'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=1200&q=80'
)
WHERE name = 'Sala de Innovación Principal' AND city = 'Tegucigalpa';

-- Coworking Open Space Tegucigalpa
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=1200&q=80',
    'https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=1200&q=80',
    'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=1200&q=80',
    'https://images.unsplash.com/photo-1531973576160-7125cd663d86?w=1200&q=80'
)
WHERE name = 'Coworking Open Space Tegucigalpa' AND city = 'Tegucigalpa';

-- Sala de Juntas Ejecutiva Premium
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1497366412874-3415097a27e7?w=1200&q=80',
    'https://images.unsplash.com/photo-1568992687947-868a62a9f521?w=1200&q=80',
    'https://images.unsplash.com/photo-1560439514-4e9645039924?w=1200&q=80'
)
WHERE name = 'Sala de Juntas Ejecutiva Premium' AND city = 'Tegucigalpa';

-- Sala de Bienestar y Mindfulness
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1545389336-cf090694435e?w=1200&q=80',
    'https://images.unsplash.com/photo-1599447292131-9c94de459705?w=1200&q=80',
    'https://images.unsplash.com/photo-1588286840104-8957b019727f?w=1200&q=80'
)
WHERE name = 'Sala de Bienestar y Mindfulness' AND city = 'Tegucigalpa';

-- =====================================================
-- CARIBBEAN SPACES - ROATÁN (Eventos & Vista al mar)
-- =====================================================

-- Terraza Vista al Mar - Eventos
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=1200&q=80',
    'https://images.unsplash.com/photo-1519167758481-83f29da8c3a7?w=1200&q=80',
    'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=1200&q=80',
    'https://images.unsplash.com/photo-1530103043960-ef38714abb15?w=1200&q=80'
)
WHERE name = 'Terraza Vista al Mar - Eventos' AND city = 'Roatán';

-- Salón de Conferencias Caribe
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1200&q=80',
    'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=1200&q=80',
    'https://images.unsplash.com/photo-1511578314322-379afb476865?w=1200&q=80'
)
WHERE name = 'Salón de Conferencias Caribe' AND city = 'Roatán';

-- Cabana de Reuniones Privada
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=1200&q=80',
    'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=1200&q=80',
    'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1200&q=80'
)
WHERE name = 'Cabana de Reuniones Privada' AND city = 'Roatán';

-- =====================================================
-- EVENTOS SPS - SAN PEDRO SULA (Grandes eventos)
-- =====================================================

-- Gran Salón de Eventos Imperial
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1519167758481-83f29da8c3a7?w=1200&q=80',
    'https://images.unsplash.com/photo-1505236858219-8359eb29e329?w=1200&q=80',
    'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=1200&q=80',
    'https://images.unsplash.com/photo-1478147427282-58a87a120781?w=1200&q=80'
)
WHERE name = 'Gran Salón de Eventos Imperial' AND city = 'San Pedro Sula';

-- Auditorio Empresarial SPS
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=1200&q=80',
    'https://images.unsplash.com/photo-1503428593586-e225b39bddfe?w=1200&q=80',
    'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=1200&q=80'
)
WHERE name = 'Auditorio Empresarial SPS' AND city = 'San Pedro Sula';

-- Sala de Capacitación Profesional
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=1200&q=80',
    'https://images.unsplash.com/photo-1588196749597-9ff075ee6b5b?w=1200&q=80',
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=1200&q=80'
)
WHERE name = 'Sala de Capacitación Profesional' AND city = 'San Pedro Sula';

-- Estudio de Podcast y Streaming
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=1200&q=80',
    'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?w=1200&q=80',
    'https://images.unsplash.com/photo-1629904869392-ae2a682d4d01?w=1200&q=80'
)
WHERE name = 'Estudio de Podcast y Streaming' AND city = 'San Pedro Sula';

-- =====================================================
-- CREATIVE SPACE - LA CEIBA (Fotografía & Creatividad)
-- =====================================================

-- Estudio de Fotografía Profesional
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1452587925148-ce544e77e70d?w=1200&q=80',
    'https://images.unsplash.com/photo-1606857521015-7f9fcf423740?w=1200&q=80',
    'https://images.unsplash.com/photo-1492760864391-abcbbf16cf9b?w=1200&q=80',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1200&q=80'
)
WHERE name = 'Estudio de Fotografía Profesional' AND city = 'La Ceiba';

-- Sala de Edición y Postproducción
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1593062096033-9a26b09da705?w=1200&q=80',
    'https://images.unsplash.com/photo-1547394765-185e1e68f34e?w=1200&q=80',
    'https://images.unsplash.com/photo-1555952494-efd681c7e3f9?w=1200&q=80'
)
WHERE name = 'Sala de Edición y Postproducción' AND city = 'La Ceiba';

-- Galería y Espacio de Exhibición
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1531243269054-5ebf6f34081e?w=1200&q=80',
    'https://images.unsplash.com/photo-1554907984-15263bfd63bd?w=1200&q=80',
    'https://images.unsplash.com/photo-1577083552431-6e5fd01988ec?w=1200&q=80',
    'https://images.unsplash.com/photo-1567696911980-2eed69a46042?w=1200&q=80'
)
WHERE name = 'Galería y Espacio de Exhibición' AND city = 'La Ceiba';

-- =====================================================
-- CENTRO EMPRESARIAL - COMAYAGUA (Oficinas & Colonial)
-- =====================================================

-- Oficina Virtual Premium Comayagua
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&q=80',
    'https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=1200&q=80'
)
WHERE name = 'Oficina Virtual Premium Comayagua' AND city = 'Comayagua';

-- Sala de Reuniones Colonial
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1572048439836-e8a4b66e5007?w=1200&q=80',
    'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=1200&q=80',
    'https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=1200&q=80'
)
WHERE name = 'Sala de Reuniones Colonial' AND city = 'Comayagua';

-- Centro de Capacitación Empresarial
UPDATE spaces 
SET images = JSON_ARRAY(
    'https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=1200&q=80',
    'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1200&q=80',
    'https://images.unsplash.com/photo-1552664730-d307ca884978?w=1200&q=80'
)
WHERE name = 'Centro de Capacitación Empresarial' AND city = 'Comayagua';

-- =====================================================
-- RESUMEN
-- =====================================================
-- Total de espacios con imágenes: 17
-- Fuente: Unsplash (imágenes libres de uso)
-- Formato: JSON array de URLs
-- Optimización: ?w=1200&q=80 para balance calidad/velocidad
-- =====================================================

SELECT 
    name, 
    city,
    CASE 
        WHEN images IS NULL THEN 'Sin imágenes'
        ELSE CONCAT(JSON_LENGTH(images), ' imágenes')
    END as estado_imagenes
FROM spaces
ORDER BY city, name;
