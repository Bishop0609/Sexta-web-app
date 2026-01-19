-- ==============================================
-- RESET TOTAL: ELIMINAR TODO EXCEPTO ADMIN
-- ==============================================

-- PASO 1: Hacer admin
UPDATE users SET role = 'admin' WHERE rut = '12345678-9';

-- PASO 2: Eliminar TODO (en orden)
DELETE FROM attendance_events;
DELETE FROM permissions;
DELETE FROM shift_attendances;
DELETE FROM shift_registrations;
DELETE FROM attendance_records;

-- PASO 3: Eliminar usuarios
DELETE FROM users WHERE rut != '12345678-9';

-- PASO 4: Verificar
SELECT u.rut, u.full_name, u.role
FROM users u;

-- Debe mostrar solo 1 usuario: 12345678-9
