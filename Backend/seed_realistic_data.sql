-- =====================================================
-- SCRIPT DE DATOS REALISTAS PARA SPAZIO - HONDURAS
-- Ejecutar: mysql -u usuario -p spazio_db < seed_realistic_data.sql
-- =====================================================

-- Desactivar verificación de claves foráneas temporalmente
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- 1. LIMPIAR DATOS EXISTENTES (excepto admin y user)
-- =====================================================

-- Eliminar todos los espacios
DELETE FROM spaces;

-- Eliminar owners (mantener admin y user)
DELETE FROM users WHERE role = 'owner';

-- =====================================================
-- 2. CREAR OWNERS REALISTAS (VERIFICADOS)
-- =====================================================

-- Owner 1: Empresa de coworking en Tegucigalpa
INSERT INTO users (id, name, email, password, role, isActive, isVerified, businessName, businessDescription, phone, whatsappNumber, instagram, facebook, linkedin, createdAt, updatedAt)
VALUES (
    UUID(),
    'Carlos Mendoza',
    'carlos.mendoza@innovahub.hn',
    '$2b$10$YourHashedPasswordHere123456789',
    'owner',
    1,
    1,
    'InnovaHub Honduras',
    'Somos el principal espacio de coworking e innovación en Tegucigalpa. Ofrecemos ambientes modernos y tecnológicos para emprendedores, freelancers y empresas que buscan un lugar inspirador para trabajar.',
    '+504 2235-4567',
    '+504 9876-5432',
    '@innovahub_hn',
    'InnovaHubHonduras',
    'innovahub-honduras',
    NOW(),
    NOW()
);

-- Owner 2: Hotel boutique en Roatán
INSERT INTO users (id, name, email, password, role, isActive, isVerified, businessName, businessDescription, phone, whatsappNumber, instagram, facebook, linkedin, createdAt, updatedAt)
VALUES (
    UUID(),
    'María Elena Reyes',
    'mreyes@caribbeanspaces.hn',
    '$2b$10$YourHashedPasswordHere123456789',
    'owner',
    1,
    1,
    'Caribbean Spaces',
    'Espacios de eventos y conferencias con vista al mar Caribe. Perfectos para retiros empresariales, bodas y eventos corporativos en el paraíso tropical de Roatán.',
    '+504 2445-1234',
    '+504 9988-7766',
    '@caribbeanspaces',
    'CaribbeanSpacesRoatan',
    'caribbean-spaces-roatan',
    NOW(),
    NOW()
);

-- Owner 3: Centro de eventos en San Pedro Sula
INSERT INTO users (id, name, email, password, role, isActive, isVerified, businessName, businessDescription, phone, whatsappNumber, instagram, facebook, linkedin, createdAt, updatedAt)
VALUES (
    UUID(),
    'Roberto Aguilar',
    'raguilar@eventossps.hn',
    '$2b$10$YourHashedPasswordHere123456789',
    'owner',
    1,
    1,
    'Eventos SPS Premium',
    'Centro de eventos y conferencias líder en San Pedro Sula. Contamos con salones versátiles, equipamiento audiovisual de última generación y servicio de catering gourmet.',
    '+504 2556-7890',
    '+504 9123-4567',
    '@eventossps',
    'EventosSPSPremium',
    'eventos-sps-premium',
    NOW(),
    NOW()
);

-- Owner 4: Espacios creativos en La Ceiba
INSERT INTO users (id, name, email, password, role, isActive, isVerified, businessName, businessDescription, phone, whatsappNumber, instagram, facebook, linkedin, createdAt, updatedAt)
VALUES (
    UUID(),
    'Ana Lucía Portillo',
    'ana.portillo@creativespace.hn',
    '$2b$10$YourHashedPasswordHere123456789',
    'owner',
    1,
    1,
    'Creative Space La Ceiba',
    'Espacios artísticos y creativos para fotógrafos, cineastas, artistas y creativos. Estudios de fotografía, salas de edición y espacios de exhibición.',
    '+504 2442-3456',
    '+504 9567-8901',
    '@creativespace_lc',
    'CreativeSpaceLaCeiba',
    NULL,
    NOW(),
    NOW()
);

-- Owner 5: Centro empresarial en Comayagua
INSERT INTO users (id, name, email, password, role, isActive, isVerified, businessName, businessDescription, phone, whatsappNumber, instagram, facebook, linkedin, createdAt, updatedAt)
VALUES (
    UUID(),
    'José Fernando Martínez',
    'jfmartinez@centroempresarial.hn',
    '$2b$10$YourHashedPasswordHere123456789',
    'owner',
    1,
    1,
    'Centro Empresarial Comayagua',
    'El corazón empresarial del centro de Honduras. Oficinas ejecutivas, salas de juntas y espacios de capacitación en una ubicación estratégica.',
    '+504 2772-4567',
    '+504 9234-5678',
    '@centroempresarial_cmy',
    'CentroEmpresarialComayagua',
    'centro-empresarial-comayagua',
    NOW(),
    NOW()
);

-- =====================================================
-- 3. OWNER PENDIENTE DE VERIFICACIÓN
-- =====================================================

INSERT INTO users (id, name, email, password, role, isActive, isVerified, businessName, businessDescription, phone, whatsappNumber, instagram, facebook, linkedin, createdAt, updatedAt)
VALUES (
    UUID(),
    'Patricia Zelaya',
    'pzelaya@nuevosespacios.hn',
    '$2b$10$YourHashedPasswordHere123456789',
    'owner',
    1,
    0,
    'Nuevos Espacios Honduras',
    'Próximamente, espacios innovadores para reuniones y eventos en Choluteca.',
    '+504 2782-1234',
    '+504 9345-6789',
    '@nuevosespacios_hn',
    NULL,
    NULL,
    NOW(),
    NOW()
);

-- =====================================================
-- 4. OBTENER IDs DE OWNERS PARA ASIGNAR ESPACIOS
-- =====================================================

-- Guardar IDs en variables (se asignarán en el siguiente bloque)
SET @owner_innovahub = (SELECT id FROM users WHERE email = 'carlos.mendoza@innovahub.hn');
SET @owner_caribbean = (SELECT id FROM users WHERE email = 'mreyes@caribbeanspaces.hn');
SET @owner_eventossps = (SELECT id FROM users WHERE email = 'raguilar@eventossps.hn');
SET @owner_creative = (SELECT id FROM users WHERE email = 'ana.portillo@creativespace.hn');
SET @owner_comayagua = (SELECT id FROM users WHERE email = 'jfmartinez@centroempresarial.hn');

-- =====================================================
-- 5. ESPACIOS DE INNOVAHUB (Tegucigalpa)
-- =====================================================

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Sala de Innovación Principal',
    'Nuestra sala insignia con diseño moderno, iluminación natural y tecnología de punta. Ideal para presentaciones, workshops y sesiones de design thinking. Cuenta con pizarras interactivas, sistema de videoconferencia 4K y mobiliario ergonómico.',
    25,
    @owner_innovahub,
    1,
    850.00,
    '["wifi_premium","proyector_4k","pizarra_interactiva","videoconferencia","aire_acondicionado","cafe_gratis","estacionamiento","acceso_discapacitados"]',
    'No se permite fumar. Respetar horarios de reserva. Dejar el espacio ordenado. Notificar con 24h de anticipación para cancelaciones.',
    'Boulevard Morazán, Torre Alianza, Piso 15',
    'Tegucigalpa',
    'Francisco Morazán',
    'Honduras',
    14.0818,
    -87.2068,
    '11101',
    '{"lunes":{"apertura":"07:00","cierre":"21:00"},"martes":{"apertura":"07:00","cierre":"21:00"},"miercoles":{"apertura":"07:00","cierre":"21:00"},"jueves":{"apertura":"07:00","cierre":"21:00"},"viernes":{"apertura":"07:00","cierre":"21:00"},"sabado":{"apertura":"08:00","cierre":"18:00"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'meetings',
    'moderate',
    NOW(),
    NOW()
);

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Coworking Open Space Tegucigalpa',
    'Espacio de trabajo colaborativo con escritorios hot-desk y dedicados. Ambiente inspirador con vista panorámica de la ciudad, zonas de descanso y área de networking. Perfecto para freelancers y equipos pequeños.',
    40,
    @owner_innovahub,
    1,
    150.00,
    '["wifi_premium","impresora","cafe_gratis","locker","aire_acondicionado","terraza","cocina_compartida"]',
    'Mantener silencio en áreas de concentración. Uso de audífonos para llamadas. No reservar espacios sin utilizarlos.',
    'Boulevard Morazán, Torre Alianza, Piso 14',
    'Tegucigalpa',
    'Francisco Morazán',
    'Honduras',
    14.0818,
    -87.2068,
    '11101',
    '{"lunes":{"apertura":"06:00","cierre":"22:00"},"martes":{"apertura":"06:00","cierre":"22:00"},"miercoles":{"apertura":"06:00","cierre":"22:00"},"jueves":{"apertura":"06:00","cierre":"22:00"},"viernes":{"apertura":"06:00","cierre":"22:00"},"sabado":{"apertura":"08:00","cierre":"16:00"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'coworking',
    'flexible',
    NOW(),
    NOW()
);

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Sala de Juntas Ejecutiva Premium',
    'Sala ejecutiva para reuniones de alto nivel. Mesa de conferencias para 12 personas, sistema de audio premium, pantalla LED 85 pulgadas y servicio de catering disponible. Ideal para juntas directivas y negociaciones importantes.',
    12,
    @owner_innovahub,
    1,
    1200.00,
    '["wifi_premium","pantalla_led_85","sistema_audio_premium","videoconferencia_4k","aire_acondicionado","cafe_gourmet","catering_disponible","estacionamiento_vip"]',
    'Reserva mínima de 2 horas. Código de vestimenta business casual. Confidencialidad garantizada.',
    'Boulevard Morazán, Torre Alianza, Piso 20',
    'Tegucigalpa',
    'Francisco Morazán',
    'Honduras',
    14.0818,
    -87.2068,
    '11101',
    '{"lunes":{"apertura":"08:00","cierre":"20:00"},"martes":{"apertura":"08:00","cierre":"20:00"},"miercoles":{"apertura":"08:00","cierre":"20:00"},"jueves":{"apertura":"08:00","cierre":"20:00"},"viernes":{"apertura":"08:00","cierre":"20:00"},"sabado":{"apertura":"09:00","cierre":"14:00"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'private',
    'strict',
    NOW(),
    NOW()
);

-- =====================================================
-- 6. ESPACIOS DE CARIBBEAN SPACES (Roatán)
-- =====================================================

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Terraza Vista al Mar - Eventos',
    'Espectacular terraza con vista panorámica al mar Caribe. Perfecta para cócteles, cenas de gala y eventos corporativos al atardecer. Capacidad para 150 personas con montaje tipo cóctel.',
    150,
    @owner_caribbean,
    1,
    3500.00,
    '["vista_al_mar","terraza","iluminacion_ambiental","sistema_sonido","bar","catering","estacionamiento","wifi"]',
    'Eventos hasta las 11 PM. No se permiten fuegos artificiales. Depósito de garantía requerido.',
    'West Bay Beach, Roatán',
    'Roatán',
    'Islas de la Bahía',
    'Honduras',
    16.2968,
    -86.5374,
    '34101',
    '{"lunes":{"apertura":"10:00","cierre":"23:00"},"martes":{"apertura":"10:00","cierre":"23:00"},"miercoles":{"apertura":"10:00","cierre":"23:00"},"jueves":{"apertura":"10:00","cierre":"23:00"},"viernes":{"apertura":"10:00","cierre":"24:00"},"sabado":{"apertura":"10:00","cierre":"24:00"},"domingo":{"apertura":"10:00","cierre":"22:00"}}',
    'events',
    'strict',
    NOW(),
    NOW()
);

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Salón de Conferencias Caribe',
    'Moderno salón de conferencias con vista al océano. Equipado con tecnología de videoconferencia internacional, ideal para retiros empresariales y capacitaciones. Incluye breaks de café y almuerzo con mariscos frescos.',
    50,
    @owner_caribbean,
    1,
    1800.00,
    '["wifi_premium","proyector","aire_acondicionado","vista_al_mar","catering_incluido","coffee_break","estacionamiento"]',
    'Código de vestimenta casual elegante. Respetar horarios de sesiones. Uso de protector solar antes de actividades al aire libre.',
    'West End Road, Roatán',
    'Roatán',
    'Islas de la Bahía',
    'Honduras',
    16.3021,
    -86.5842,
    '34101',
    '{"lunes":{"apertura":"08:00","cierre":"18:00"},"martes":{"apertura":"08:00","cierre":"18:00"},"miercoles":{"apertura":"08:00","cierre":"18:00"},"jueves":{"apertura":"08:00","cierre":"18:00"},"viernes":{"apertura":"08:00","cierre":"18:00"},"sabado":{"apertura":"09:00","cierre":"16:00"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'meetings',
    'moderate',
    NOW(),
    NOW()
);

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Cabana de Reuniones Privada',
    'Exclusiva cabaña sobre el agua para reuniones íntimas de alto nivel. Privacidad total con servicio personalizado, ideal para negociaciones confidenciales o sesiones de estrategia con tu equipo ejecutivo.',
    8,
    @owner_caribbean,
    1,
    2200.00,
    '["privacidad_total","wifi_premium","aire_acondicionado","minibar","servicio_personalizado","muelle_privado","snorkel_disponible"]',
    'Reserva mínima de 4 horas. Máximo 8 personas. Servicio de lancha disponible con costo adicional.',
    'Sandy Bay, Roatán',
    'Roatán',
    'Islas de la Bahía',
    'Honduras',
    16.3156,
    -86.4892,
    '34101',
    '{"lunes":{"apertura":"09:00","cierre":"18:00"},"martes":{"apertura":"09:00","cierre":"18:00"},"miercoles":{"apertura":"09:00","cierre":"18:00"},"jueves":{"apertura":"09:00","cierre":"18:00"},"viernes":{"apertura":"09:00","cierre":"18:00"},"sabado":{"apertura":"09:00","cierre":"18:00"},"domingo":{"apertura":"10:00","cierre":"16:00"}}',
    'private',
    'strict',
    NOW(),
    NOW()
);

-- =====================================================
-- 7. ESPACIOS DE EVENTOS SPS (San Pedro Sula)
-- =====================================================

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Gran Salón de Eventos Imperial',
    'El salón de eventos más grande y elegante de San Pedro Sula. Capacidad para 500 personas, sistema de iluminación inteligente, escenario modular y cocina industrial para catering. Perfecto para bodas, conciertos y eventos corporativos masivos.',
    500,
    @owner_eventossps,
    1,
    8500.00,
    '["escenario","sistema_sonido_profesional","iluminacion_led","cocina_industrial","vestidores","estacionamiento_amplio","generador_emergencia","wifi","guardarropa"]',
    'Reserva con mínimo 30 días de anticipación. Horario de montaje disponible día anterior. Seguro de evento requerido para más de 200 personas.',
    'Boulevard del Norte, Zona Viva',
    'San Pedro Sula',
    'Cortés',
    'Honduras',
    15.5049,
    -88.0251,
    '21101',
    '{"lunes":{"apertura":"08:00","cierre":"24:00"},"martes":{"apertura":"08:00","cierre":"24:00"},"miercoles":{"apertura":"08:00","cierre":"24:00"},"jueves":{"apertura":"08:00","cierre":"24:00"},"viernes":{"apertura":"08:00","cierre":"02:00"},"sabado":{"apertura":"08:00","cierre":"02:00"},"domingo":{"apertura":"10:00","cierre":"22:00"}}',
    'events',
    'strict',
    NOW(),
    NOW()
);

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Auditorio Empresarial SPS',
    'Auditorio profesional con 120 butacas, escenario con telón motorizado, cabina de traducción simultánea y sistema de audio envolvente. Ideal para conferencias, seminarios y presentaciones de productos.',
    120,
    @owner_eventossps,
    1,
    2200.00,
    '["butacas_ergonomicas","escenario","cabina_traduccion","audio_envolvente","proyector_laser","grabacion_disponible","wifi_premium","aire_acondicionado"]',
    'No ingresar alimentos al auditorio. Apagar celulares durante presentaciones. Servicio técnico incluido.',
    'Boulevard del Norte, Zona Viva',
    'San Pedro Sula',
    'Cortés',
    'Honduras',
    15.5049,
    -88.0251,
    '21101',
    '{"lunes":{"apertura":"07:00","cierre":"21:00"},"martes":{"apertura":"07:00","cierre":"21:00"},"miercoles":{"apertura":"07:00","cierre":"21:00"},"jueves":{"apertura":"07:00","cierre":"21:00"},"viernes":{"apertura":"07:00","cierre":"21:00"},"sabado":{"apertura":"08:00","cierre":"18:00"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'teams',
    'moderate',
    NOW(),
    NOW()
);

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Sala de Capacitación Profesional',
    'Sala versátil para capacitaciones empresariales con mobiliario modular. Configuración tipo aula, U o mesas de trabajo. Incluye material didáctico básico y coffee breaks.',
    30,
    @owner_eventossps,
    1,
    650.00,
    '["mobiliario_modular","proyector","pizarra","wifi","aire_acondicionado","coffee_break_incluido","material_didactico","estacionamiento"]',
    'Reserva mínima de 4 horas para capacitaciones. Especificar configuración deseada al reservar.',
    'Boulevard del Norte, Zona Viva',
    'San Pedro Sula',
    'Cortés',
    'Honduras',
    15.5049,
    -88.0251,
    '21101',
    '{"lunes":{"apertura":"07:00","cierre":"20:00"},"martes":{"apertura":"07:00","cierre":"20:00"},"miercoles":{"apertura":"07:00","cierre":"20:00"},"jueves":{"apertura":"07:00","cierre":"20:00"},"viernes":{"apertura":"07:00","cierre":"20:00"},"sabado":{"apertura":"08:00","cierre":"14:00"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'meetings',
    'flexible',
    NOW(),
    NOW()
);

-- =====================================================
-- 8. ESPACIOS DE CREATIVE SPACE (La Ceiba)
-- =====================================================

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Estudio de Fotografía Profesional',
    'Estudio fotográfico completamente equipado con cicloramas de colores, iluminación profesional Profoto, vestuario y área de maquillaje. Ideal para sesiones de moda, producto y retratos profesionales.',
    10,
    @owner_creative,
    1,
    450.00,
    '["ciclorama_blanco","ciclorama_negro","iluminacion_profoto","vestidores","area_maquillaje","softboxes","reflectores","wifi"]',
    'Traer propio equipo de cámara. Iluminación incluida en tarifa. Asistente disponible con costo adicional. Limpieza del estudio al finalizar.',
    'Barrio La Isla, 2da Avenida',
    'La Ceiba',
    'Atlántida',
    'Honduras',
    15.7631,
    -86.7822,
    '31101',
    '{"lunes":{"apertura":"08:00","cierre":"20:00"},"martes":{"apertura":"08:00","cierre":"20:00"},"miercoles":{"apertura":"08:00","cierre":"20:00"},"jueves":{"apertura":"08:00","cierre":"20:00"},"viernes":{"apertura":"08:00","cierre":"20:00"},"sabado":{"apertura":"09:00","cierre":"18:00"},"domingo":{"apertura":"10:00","cierre":"16:00"}}',
    'private',
    'moderate',
    NOW(),
    NOW()
);

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Sala de Edición y Postproducción',
    'Suite de edición con estaciones Mac Pro, monitores calibrados y software profesional (Adobe CC, DaVinci Resolve). Perfecta para editores de video, coloristas y diseñadores gráficos.',
    6,
    @owner_creative,
    1,
    280.00,
    '["mac_pro","monitores_4k_calibrados","adobe_cc","davinci_resolve","almacenamiento_ssd","auriculares_profesionales","aire_acondicionado","cafe"]',
    'No instalar software adicional. Guardar archivos en disco externo propio. Uso de auriculares obligatorio.',
    'Barrio La Isla, 2da Avenida',
    'La Ceiba',
    'Atlántida',
    'Honduras',
    15.7631,
    -86.7822,
    '31101',
    '{"lunes":{"apertura":"09:00","cierre":"22:00"},"martes":{"apertura":"09:00","cierre":"22:00"},"miercoles":{"apertura":"09:00","cierre":"22:00"},"jueves":{"apertura":"09:00","cierre":"22:00"},"viernes":{"apertura":"09:00","cierre":"22:00"},"sabado":{"apertura":"10:00","cierre":"20:00"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'private',
    'flexible',
    NOW(),
    NOW()
);

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Galería y Espacio de Exhibición',
    'Galería de arte contemporáneo disponible para exhibiciones temporales, lanzamientos de productos y eventos culturales. Paredes blancas, iluminación de galería y sistema de colgado profesional.',
    80,
    @owner_creative,
    1,
    950.00,
    '["iluminacion_galeria","sistema_colgado","paredes_blancas","audio_ambiental","wifi","climatizado","seguridad"]',
    'Montaje con supervisión del personal. No usar clavos ni adhesivos fuertes. Evento de inauguración incluido.',
    'Barrio La Isla, 2da Avenida',
    'La Ceiba',
    'Atlántida',
    'Honduras',
    15.7631,
    -86.7822,
    '31101',
    '{"lunes":{"apertura":"10:00","cierre":"19:00"},"martes":{"apertura":"10:00","cierre":"19:00"},"miercoles":{"apertura":"10:00","cierre":"19:00"},"jueves":{"apertura":"10:00","cierre":"19:00"},"viernes":{"apertura":"10:00","cierre":"21:00"},"sabado":{"apertura":"10:00","cierre":"21:00"},"domingo":{"apertura":"11:00","cierre":"17:00"}}',
    'events',
    'moderate',
    NOW(),
    NOW()
);

-- =====================================================
-- 9. ESPACIOS DE CENTRO EMPRESARIAL (Comayagua)
-- =====================================================

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Oficina Virtual Premium Comayagua',
    'Servicio de oficina virtual con dirección comercial prestigiosa, recepción de correspondencia, atención telefónica personalizada y uso de sala de juntas 4 horas al mes incluidas.',
    1,
    @owner_comayagua,
    1,
    120.00,
    '["direccion_comercial","recepcion_correspondencia","atencion_telefonica","sala_juntas_incluida","wifi","cafe","impresion"]',
    'Servicio mensual renovable. Correspondencia guardada por máximo 30 días. Uso adicional de sala con costo extra.',
    'Calle del Comercio, Centro Histórico',
    'Comayagua',
    'Comayagua',
    'Honduras',
    14.4611,
    -87.6386,
    '12101',
    '{"lunes":{"apertura":"08:00","cierre":"17:00"},"martes":{"apertura":"08:00","cierre":"17:00"},"miercoles":{"apertura":"08:00","cierre":"17:00"},"jueves":{"apertura":"08:00","cierre":"17:00"},"viernes":{"apertura":"08:00","cierre":"17:00"},"sabado":{"apertura":"cerrado","cierre":"cerrado"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'coworking',
    'flexible',
    NOW(),
    NOW()
);

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Sala de Reuniones Colonial',
    'Elegante sala de reuniones en edificio colonial restaurado. Combina la historia de Comayagua con comodidades modernas. Ideal para reuniones con clientes que aprecian la cultura hondureña.',
    14,
    @owner_comayagua,
    1,
    380.00,
    '["ambiente_colonial","aire_acondicionado","proyector","wifi","cafe_gourmet","estacionamiento","patio_interior"]',
    'Respeto por el patrimonio histórico. No modificar decoración. Fotos permitidas.',
    'Calle del Comercio, Centro Histórico',
    'Comayagua',
    'Comayagua',
    'Honduras',
    14.4611,
    -87.6386,
    '12101',
    '{"lunes":{"apertura":"08:00","cierre":"18:00"},"martes":{"apertura":"08:00","cierre":"18:00"},"miercoles":{"apertura":"08:00","cierre":"18:00"},"jueves":{"apertura":"08:00","cierre":"18:00"},"viernes":{"apertura":"08:00","cierre":"18:00"},"sabado":{"apertura":"09:00","cierre":"13:00"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'meetings',
    'moderate',
    NOW(),
    NOW()
);

INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Centro de Capacitación Empresarial',
    'Moderno centro de capacitación con laboratorio de cómputo (20 PCs), proyector interactivo y materiales didácticos. Perfecto para cursos técnicos, certificaciones y talleres empresariales.',
    25,
    @owner_comayagua,
    1,
    520.00,
    '["laboratorio_computo","pcs_20","proyector_interactivo","pizarra_digital","wifi_empresarial","aire_acondicionado","coffee_break","material_didactico"]',
    'Software preinstalado incluye Office y navegadores. Software adicional requiere autorización previa.',
    'Calle del Comercio, Centro Histórico',
    'Comayagua',
    'Comayagua',
    'Honduras',
    14.4611,
    -87.6386,
    '12101',
    '{"lunes":{"apertura":"07:00","cierre":"21:00"},"martes":{"apertura":"07:00","cierre":"21:00"},"miercoles":{"apertura":"07:00","cierre":"21:00"},"jueves":{"apertura":"07:00","cierre":"21:00"},"viernes":{"apertura":"07:00","cierre":"21:00"},"sabado":{"apertura":"08:00","cierre":"16:00"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'teams',
    'moderate',
    NOW(),
    NOW()
);

-- =====================================================
-- 10. ESPACIOS ADICIONALES VARIADOS
-- =====================================================

-- Espacio de yoga/bienestar en Tegucigalpa
INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Sala de Bienestar y Mindfulness',
    'Espacio zen para sesiones de yoga corporativo, meditación y bienestar empresarial. Piso de bambú, iluminación regulable y sistema de sonido ambiental. Transforma el bienestar de tu equipo.',
    20,
    @owner_innovahub,
    1,
    350.00,
    '["piso_bambu","iluminacion_regulable","audio_ambiental","mats_yoga","bloques_yoga","mantas","aromaterapia","vestuarios"]',
    'Llegar 10 minutos antes para preparación. Ropa cómoda requerida. Silencio en áreas de meditación.',
    'Boulevard Morazán, Torre Alianza, Piso 3',
    'Tegucigalpa',
    'Francisco Morazán',
    'Honduras',
    14.0818,
    -87.2068,
    '11101',
    '{"lunes":{"apertura":"06:00","cierre":"21:00"},"martes":{"apertura":"06:00","cierre":"21:00"},"miercoles":{"apertura":"06:00","cierre":"21:00"},"jueves":{"apertura":"06:00","cierre":"21:00"},"viernes":{"apertura":"06:00","cierre":"21:00"},"sabado":{"apertura":"07:00","cierre":"14:00"},"domingo":{"apertura":"08:00","cierre":"12:00"}}',
    'private',
    'flexible',
    NOW(),
    NOW()
);

-- Sala de podcast en San Pedro Sula
INSERT INTO spaces (id, name, description, capacity, ownerId, isActive, pricePerHour, amenities, rules, address, city, state, country, latitude, longitude, zipCode, workingHours, category, cancellationPolicy, createdAt, updatedAt)
VALUES (
    UUID(),
    'Estudio de Podcast y Streaming',
    'Estudio profesional de grabación para podcasts, entrevistas y streaming en vivo. Equipamiento Rode, tratamiento acústico profesional y conexión de fibra óptica para transmisiones sin interrupciones.',
    4,
    @owner_eventossps,
    1,
    380.00,
    '["microfonos_rode","mezcladora_profesional","tratamiento_acustico","camaras_hd","iluminacion_led","fibra_optica","software_streaming","green_screen"]',
    'Reserva mínima de 2 horas. Técnico de sonido disponible con costo adicional. Traer contenido preparado.',
    'Boulevard del Norte, Zona Viva',
    'San Pedro Sula',
    'Cortés',
    'Honduras',
    15.5049,
    -88.0251,
    '21101',
    '{"lunes":{"apertura":"09:00","cierre":"21:00"},"martes":{"apertura":"09:00","cierre":"21:00"},"miercoles":{"apertura":"09:00","cierre":"21:00"},"jueves":{"apertura":"09:00","cierre":"21:00"},"viernes":{"apertura":"09:00","cierre":"21:00"},"sabado":{"apertura":"10:00","cierre":"18:00"},"domingo":{"apertura":"cerrado","cierre":"cerrado"}}',
    'private',
    'moderate',
    NOW(),
    NOW()
);

-- Reactivar verificación de claves foráneas
SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- RESUMEN DE DATOS INSERTADOS
-- =====================================================
-- 
-- OWNERS (5 verificados + 1 pendiente):
-- 1. Carlos Mendoza - InnovaHub Honduras (Tegucigalpa)
-- 2. María Elena Reyes - Caribbean Spaces (Roatán)
-- 3. Roberto Aguilar - Eventos SPS Premium (San Pedro Sula)
-- 4. Ana Lucía Portillo - Creative Space La Ceiba (La Ceiba)
-- 5. José Fernando Martínez - Centro Empresarial Comayagua (Comayagua)
-- 6. Patricia Zelaya - Nuevos Espacios (Choluteca) - PENDIENTE
--
-- ESPACIOS (17 total):
-- - Tegucigalpa: 4 espacios (coworking, salas, bienestar)
-- - Roatán: 3 espacios (eventos, conferencias, privado)
-- - San Pedro Sula: 4 espacios (eventos, auditorio, capacitación, podcast)
-- - La Ceiba: 3 espacios (foto, edición, galería)
-- - Comayagua: 3 espacios (oficina virtual, colonial, capacitación)
--
-- =====================================================
