-- ==============================================
-- RESET FINAL - SOLO TABLAS QUE EXISTEN
-- ==============================================

-- PASO 1: Hacer admin
UPDATE users SET role = 'admin' WHERE rut = '12345678-9';

-- PASO 2: Eliminar de tablas que SÍ existen
DELETE FROM attendance_events;
DELETE FROM permissions;
DELETE FROM shift_registrations;
DELETE FROM attendance_records;

-- PASO 3: Eliminar usuarios
DELETE FROM users WHERE rut != '12345678-9';

-- PASO 4: Verificar
SELECT u.rut, u.full_name, u.role
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id;

-- Debe mostrar solo: 12345678-9 como admin con credenciales
