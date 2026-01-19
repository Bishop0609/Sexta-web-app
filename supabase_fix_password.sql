-- ============================================
-- SOLUCIÓN: ACTUALIZAR CON HASH CORRECTO
-- ============================================

-- El hash que está en la BD es INCORRECTO
-- Hash incorrecto actual: dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:7e8f3c9b2a1d0e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9

-- ✅ HASH CORRECTO para contraseña: Bombero2024!
-- dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:10f5897648e18c14c92dc8c2e0c70f4cca9e05e0235720770d0b682c665df566

-- EJECUTA ESTE SQL PARA ARREGLAR:
UPDATE auth_credentials 
SET password_hash = 'dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:10f5897648e18c14c92dc8c2e0c70f4cca9e05e0235720770d0b682c665df566' 
WHERE user_id = (SELECT id FROM users WHERE rut = '12345678-9');

-- Verificar que se actualizó correctamente
SELECT u.rut, u.full_name, ac.password_hash
FROM users u
JOIN auth_credentials ac ON u.id = ac.user_id
WHERE u.rut = '12345678-9';

-- Debe mostrar:
-- dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:10f5897648e18c14c92dc8c2e0c70f4cca9e05e0235720770d0b682c665df566
