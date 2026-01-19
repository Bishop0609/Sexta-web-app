-- ============================================
-- SCRIPT DE GENERACIÓN DE DATOS DE PRUEBA
-- 20 Emergencias con Asistencias entre 01-01-25 y 11-01-25
-- ============================================

-- Primero obtenemos los IDs necesarios
DO $$
DECLARE
  -- Variables para IDs de tipos de actos
  v_incendio_id UUID;
  v_rescate_id UUID;
  v_academia_id UUID;
  v_capacitacion_id UUID;
  v_servicio_id UUID;
  v_ceremonia_id UUID;
  
  -- Variable para ID del creador (primer admin que encuentre)
  v_creator_id UUID;
  
  -- Array de IDs de usuarios
  v_user_ids UUID[];
  
  -- Variables temporales
  v_event_id UUID;
  v_event_date DATE;
  v_attendance_count INT;
  v_user_id UUID;
  v_status TEXT;
  
BEGIN
  -- Obtener IDs de tipos de actos
  SELECT id INTO v_incendio_id FROM act_types WHERE name = 'Incendio';
  SELECT id INTO v_rescate_id FROM act_types WHERE name = 'Rescate';
  SELECT id INTO v_academia_id FROM act_types WHERE name = 'Academia';
  SELECT id INTO v_capacitacion_id FROM act_types WHERE name = 'Capacitación';
  SELECT id INTO v_servicio_id FROM act_types WHERE name = 'Servicio Especial';
  SELECT id INTO v_ceremonia_id FROM act_types WHERE name = 'Ceremonia';
  
  -- Obtener un usuario admin como creador
  SELECT id INTO v_creator_id FROM users WHERE role = 'admin' LIMIT 1;
  
  -- Si no hay admin, usar el primer usuario
  IF v_creator_id IS NULL THEN
    SELECT id INTO v_creator_id FROM users LIMIT 1;
  END IF;
  
  -- Obtener todos los IDs de usuarios
  SELECT ARRAY_AGG(id) INTO v_user_ids FROM users;
  
  -- EVENTO 1: Incendio - 01-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_incendio_id, '2025-01-01', v_creator_id);
  
  -- Asistencias para evento 1 (65 presentes, 4 ausentes, 2 licencia)
  FOR i IN 1..65 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 66..69 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 70..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 2: Rescate - 02-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_rescate_id, '2025-01-02', v_creator_id);
  
  -- Asistencias para evento 2 (58 presentes, 8 ausentes, 5 licencia)
  FOR i IN 1..58 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 59..66 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 67..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 3: Academia - 03-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_academia_id, '2025-01-03', v_creator_id);
  
  -- Asistencias para evento 3 (62 presentes, 6 ausentes, 3 licencia)
  FOR i IN 1..62 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 63..68 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 69..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 4: Incendio - 04-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_incendio_id, '2025-01-04', v_creator_id);
  
  -- Asistencias para evento 4 (67 presentes, 3 ausentes, 1 licencia)
  FOR i IN 1..67 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 68..70 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  INSERT INTO attendance_records (event_id, user_id, status)
  VALUES (v_event_id, v_user_ids[71], 'licencia');
  
  -- EVENTO 5: Capacitación - 05-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_capacitacion_id, '2025-01-05', v_creator_id);
  
  -- Asistencias para evento 5 (60 presentes, 7 ausentes, 4 licencia)
  FOR i IN 1..60 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 61..67 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 68..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 6: Rescate - 05-Jan-2025 (tarde)
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_rescate_id, '2025-01-05', v_creator_id);
  
  -- Asistencias para evento 6 (55 presentes, 10 ausentes, 6 licencia)
  FOR i IN 1..55 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 56..65 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 66..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 7: Servicio Especial - 06-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_servicio_id, '2025-01-06', v_creator_id);
  
  -- Asistencias para evento 7 (68 presentes, 2 ausentes, 1 licencia)
  FOR i IN 1..68 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 69..70 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  INSERT INTO attendance_records (event_id, user_id, status)
  VALUES (v_event_id, v_user_ids[71], 'licencia');
  
  -- EVENTO 8: Incendio - 07-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_incendio_id, '2025-01-07', v_creator_id);
  
  -- Asistencias para evento 8 (63 presentes, 5 ausentes, 3 licencia)
  FOR i IN 1..63 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 64..68 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 69..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 9: Ceremonia - 08-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_ceremonia_id, '2025-01-08', v_creator_id);
  
  -- Asistencias para evento 9 (70 presentes, 1 ausente)
  FOR i IN 1..70 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  INSERT INTO attendance_records (event_id, user_id, status)
  VALUES (v_event_id, v_user_ids[71], 'absent');
  
  -- EVENTO 10: Rescate - 08-Jan-2025 (tarde)
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_rescate_id, '2025-01-08', v_creator_id);
  
  -- Asistencias para evento 10 (59 presentes, 8 ausentes, 4 licencia)
  FOR i IN 1..59 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 60..67 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 68..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 11: Academia - 09-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_academia_id, '2025-01-09', v_creator_id);
  
  -- Asistencias para evento 11 (64 presentes, 5 ausentes, 2 licencia)
  FOR i IN 1..64 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 65..69 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 70..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 12: Incendio - 09-Jan-2025 (noche)
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_incendio_id, '2025-01-09', v_creator_id);
  
  -- Asistencias para evento 12 (66 presentes, 4 ausentes, 1 licencia)
  FOR i IN 1..66 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 67..70 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  INSERT INTO attendance_records (event_id, user_id, status)
  VALUES (v_event_id, v_user_ids[71], 'licencia');
  
  -- EVENTO 13: Capacitación - 10-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_capacitacion_id, '2025-01-10', v_creator_id);
  
  -- Asistencias para evento 13 (61 presentes, 6 ausentes, 4 licencia)
  FOR i IN 1..61 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 62..67 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 68..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 14: Rescate - 10-Jan-2025 (tarde)
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_rescate_id, '2025-01-10', v_creator_id);
  
  -- Asistencias para evento 14 (57 presentes, 9 ausentes, 5 licencia)
  FOR i IN 1..57 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 58..66 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 67..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 15: Servicio Especial - 10-Jan-2025 (noche)
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_servicio_id, '2025-01-10', v_creator_id);
  
  -- Asistencias para evento 15 (69 presentes, 2 ausentes)
  FOR i IN 1..69 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 70..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  
  -- EVENTO 16: Incendio - 11-Jan-2025
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_incendio_id, '2025-01-11', v_creator_id);
  
  -- Asistencias para evento 16 (65 presentes, 4 ausentes, 2 licencia)
  FOR i IN 1..65 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 66..69 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 70..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 17: Academia - 11-Jan-2025 (tarde)
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_academia_id, '2025-01-11', v_creator_id);
  
  -- Asistencias para evento 17 (62 presentes, 6 ausentes, 3 licencia)
  FOR i IN 1..62 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 63..68 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 69..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 18: Rescate - 11-Jan-2025 (noche)
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_rescate_id, '2025-01-11', v_creator_id);
  
  -- Asistencias para evento 18 (60 presentes, 7 ausentes, 4 licencia)
  FOR i IN 1..60 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 61..67 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 68..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  -- EVENTO 19: Ceremonia - 11-Jan-2025 (tarde)
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_ceremonia_id, '2025-01-11', v_creator_id);
  
  -- Asistencias para evento 19 (71 presentes - ceremonia especial)
  FOR i IN 1..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  
  -- EVENTO 20: Incendio - 11-Jan-2025 (madrugada)
  v_event_id := uuid_generate_v4();
  INSERT INTO attendance_events (id, act_type_id, event_date, created_by)
  VALUES (v_event_id, v_incendio_id, '2025-01-11', v_creator_id);
  
  -- Asistencias para evento 20 (58 presentes, 8 ausentes, 5 licencia)
  FOR i IN 1..58 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'present');
  END LOOP;
  FOR i IN 59..66 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'absent');
  END LOOP;
  FOR i IN 67..71 LOOP
    INSERT INTO attendance_records (event_id, user_id, status)
    VALUES (v_event_id, v_user_ids[i], 'licencia');
  END LOOP;
  
  RAISE NOTICE '✅ Se insertaron exitosamente 20 emergencias con asistencias variadas';
  RAISE NOTICE '📊 Eventos entre 01-Jan-2025 y 11-Jan-2025';
  RAISE NOTICE '👥 Con participación de los 71 bomberos registrados';
  
END $$;

-- Verificación de datos insertados
SELECT 
  TO_CHAR(event_date, 'DD-Mon-YYYY') as fecha,
  at.name as tipo_acto,
  at.category as categoria,
  COUNT(ar.id) as total_registros,
  SUM(CASE WHEN ar.status = 'present' THEN 1 ELSE 0 END) as presentes,
  SUM(CASE WHEN ar.status = 'absent' THEN 1 ELSE 0 END) as ausentes,
  SUM(CASE WHEN ar.status = 'licencia' THEN 1 ELSE 0 END) as licencias
FROM attendance_events ae
JOIN act_types at ON ae.act_type_id = at.id
LEFT JOIN attendance_records ar ON ae.id = ar.event_id
WHERE ae.event_date BETWEEN '2025-01-01' AND '2025-01-11'
GROUP BY ae.event_date, at.name, at.category
ORDER BY ae.event_date, at.name;
