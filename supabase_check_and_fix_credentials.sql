-- ============================================
-- VERIFICAR ESTADO DE CREDENCIALES
-- ============================================

-- ¿Ejecutaste el SQL para crear credenciales?
-- Si NO, este query mostrará usuarios sin credenciales

SELECT 
  u.rut,
  u.full_name,
  CASE 
    WHEN ac.user_id IS NOT NULL THEN '✓ TIENE CREDENCIALES'
    ELSE '✗ SIN CREDENCIALES'
  END as estado
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
ORDER BY 
  CASE WHEN ac.user_id IS NULL THEN 0 ELSE 1 END,
  u.full_name;

-- ============================================
-- SI HAY USUARIOS SIN CREDENCIALES, EJECUTA:
-- ============================================

INSERT INTO auth_credentials (user_id, password_hash, requires_password_change)
SELECT 
  u.id,
  'dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:10f5897648e18c14c92dc8c2e0c70f4cca9e05e0235720770d0b682c665df566',
  true
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
WHERE ac.user_id IS NULL;
