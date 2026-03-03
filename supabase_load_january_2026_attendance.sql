-- ============================================================================
-- CARGA MASIVA DE ASISTENCIAS - ENERO 2026
-- Datos reales de asistencias para pruebas de gráficas y KPIs
-- Creado por: Gunther Hicks (13238728-1)
-- ============================================================================

-- PASO 1: Obtener IDs necesarios
DO $$
DECLARE
    v_user_id UUID;
    v_emergencia_id UUID;
    v_reunion_id UUID;
    v_event_id UUID;
    v_rut TEXT;
    v_user_record RECORD;
BEGIN
    -- Obtener ID del usuario creador
    SELECT id INTO v_user_id FROM users WHERE rut = '13238728-1';
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario con RUT 13238728-1 no encontrado';
    END IF;
    
    -- Obtener IDs de tipos de acto
    SELECT id INTO v_emergencia_id FROM act_types WHERE name = 'Emergencia';
    SELECT id INTO v_reunion_id FROM act_types WHERE name = 'Reunión de Compañía';
    
    IF v_emergencia_id IS NULL OR v_reunion_id IS NULL THEN
        RAISE EXCEPTION 'Tipos de acto no encontrados';
    END IF;
    
    RAISE NOTICE 'IDs obtenidos correctamente';
    RAISE NOTICE 'Usuario: %', v_user_id;
    RAISE NOTICE 'Emergencia: %', v_emergencia_id;
    RAISE NOTICE 'Reunión: %', v_reunion_id;
    
    -- ========================================================================
    -- CITACIONES (A, B, C)
    -- ========================================================================
    
    -- Citación A: 06-01-2026 - Reunión ordinaria de Compañía
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_reunion_id, '2026-01-06', v_user_id, 'Ordinaria', 'Cuartel 6')
    RETURNING id INTO v_event_id;
    
    -- Registros de asistencia para Citación A
    FOR v_user_record IN 
        SELECT u.id, u.rut FROM users u ORDER BY u.rut
    LOOP
        v_rut := v_user_record.rut;
        
        -- Matriz de asistencia Citación A (columna A del Excel)
        IF v_rut IN ('8720935-3', '5408735-7', '7538193-k', '9378802-8', '8472115-4', '7341156-1', 
                     '6257387-2', '13238728-1', '13368329-9', '13504531-5', '15054524-k', '14120786-5', 
                     '12014987-6', '8911339-3', '12428620-2', '10154142-8', '18893165-4', '11612980-9', 
                     '16796056-1', '16578803-6', '12173806-7', '19155567-8', '17174462-8', '17846577-1', 
                     '18002706-8', '15027199-k', '8504240-1', '22395855-1', '20883179-k', '20718120-6', 
                     '26255933-5', '18450516-9', '16665430-0', '20060224-8', '12021385-7', '18317155-4', 
                     '16495551-5', '19257767-5', '15986931-8', '18003513-3', '18914885-3', '8409263-7', 
                     '7465857-5', '21373938-7', '13367300-8', '18218726-7', '20001940-7', '19482527-4', 
                     '20883844-k', '18331635-8', '17204179-5', '20274956-1', '22337684-3', '15971013-6', 
                     '27979718-3', '28261282-4', '22026750-8', '14060916-5', '21844261-7', '26961434-k', 
                     '21562316-5', '17016808-9', '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSIF v_rut IN ('7341156-1', '6257387-2', '13504531-5', '8911339-3', '16578803-6', '19155567-8', 
                        '17174462-8', '17846577-1', '22026750-8', '21844261-7') THEN
            -- Permisos (0.5 en Excel)
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'licencia', true);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Citación A creada: %', v_event_id;
    
    -- Citación B: 17-01-2026 - Academia de compañía
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_reunion_id, '2026-01-17', v_user_id, 'Extraordinaria', 'Cuartel 6')
    RETURNING id INTO v_event_id;
    
    -- Registros de asistencia para Citación B
    FOR v_user_record IN 
        SELECT u.id, u.rut FROM users u ORDER BY u.rut
    LOOP
        v_rut := v_user_record.rut;
        
        -- Matriz de asistencia Citación B (columna B del Excel)
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', 
                     '10154142-8', '16796056-1', '16578803-6', '12173806-7', '19155567-8', '17174462-8', 
                     '17846577-1', '18002706-8', '15027199-k', '22395855-1', '20718120-6', '26255933-5', 
                     '18450516-9', '16665430-0', '20060224-8', '18317155-4', '16495551-5', '19257767-5', 
                     '15986931-8', '18914885-3', '21373938-7', '13367300-8', '18218726-7', '20001940-7', 
                     '19482527-4', '20883844-k', '18331635-8', '17204179-5', '20274956-1', '22337684-3', 
                     '15971013-6', '27979718-3', '22026750-8', '14060916-5', '21562316-5', '17016808-9', 
                     '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSIF v_rut IN ('8720935-3', '5408735-7', '8472115-4', '7341156-1', '6257387-2', '8911339-3', 
                        '12428620-2', '18893165-4', '11612980-9', '8504240-1', '20883179-k', '12021385-7', 
                        '18003513-3', '8409263-7', '7465857-5', '28261282-4', '21844261-7', '26961434-k') THEN
            -- Permisos (0.5 en Excel)
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'licencia', true);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Citación B creada: %', v_event_id;
    
    -- Citación C: 23-01-2026 - Academia de compañía
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_reunion_id, '2026-01-23', v_user_id, 'Extraordinaria', 'Cuartel 6')
    RETURNING id INTO v_event_id;
    
    -- Registros de asistencia para Citación C
    FOR v_user_record IN 
        SELECT u.id, u.rut FROM users u ORDER BY u.rut
    LOOP
        v_rut := v_user_record.rut;
        
        -- Matriz de asistencia Citación C (columna C del Excel)
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', 
                     '10154142-8', '16796056-1', '16578803-6', '12173806-7', '17174462-8', '17846577-1', 
                     '18002706-8', '15027199-k', '22395855-1', '20718120-6', '26255933-5', '18450516-9', 
                     '16665430-0', '20060224-8', '18317155-4', '16495551-5', '19257767-5', '15986931-8', 
                     '18914885-3', '21373938-7', '13367300-8', '18218726-7', '20001940-7', '19482527-4', 
                     '20883844-k', '18331635-8', '17204179-5', '20274956-1', '22337684-3', '15971013-6', 
                     '27979718-3', '22026750-8', '14060916-5', '21562316-5', '17016808-9', '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSIF v_rut IN ('8720935-3', '5408735-7', '8472115-4', '7341156-1', '6257387-2', '8911339-3', 
                        '12428620-2', '18893165-4', '11612980-9', '19155567-8', '8504240-1', '20883179-k', 
                        '12021385-7', '18003513-3', '8409263-7', '7465857-5', '28261282-4', '21844261-7', 
                        '26961434-k') THEN
            -- Permisos (0.5 en Excel)
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'licencia', true);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Citación C creada: %', v_event_id;
    
    -- ========================================================================
    -- EMERGENCIAS (1-30)
    -- ========================================================================
    
    -- Emergencia 1: 01-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-01', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 1 creada';
    
    -- Emergencia 2: 01-01-2026 - 10-9
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-01', v_user_id, '10-9', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('5408735-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 2 creada';
    
    -- Emergencia 3: 02-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-02', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', 
                     '16578803-6', '12173806-7', '17174462-8', '17846577-1') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 3 creada';
    
    -- Emergencia 4: 03-01-2026 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-03', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 4 creada';
    
    -- Emergencia 5: 04-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-04', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 5 creada';
    
    -- Emergencia 6: 06-01-2026 - 10-3
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-06', v_user_id, '10-3', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 6 creada';
    
    -- Emergencia 7: 06-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-06', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('13504531-5', '14120786-5', '16578803-6', '12173806-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 7 creada';
    
    -- Emergencia 8: 06-01-2026 - 10-6
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-06', v_user_id, '10-6', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('17174462-8', '17846577-1') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 8 creada';
    
    -- Emergencia 9: 07-01-2026 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-07', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13504531-5', '14120786-5') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 9 creada';
    
    -- Emergencia 10: 07-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-07', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('16578803-6', '12173806-7', '17174462-8', '17846577-1') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 10 creada';
    
    -- Emergencia 11: 10-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-10', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '10154142-8', '16796056-1', '16578803-6', '12173806-7', '19155567-8', 
                     '17174462-8', '17846577-1', '18002706-8', '15027199-k', '20718120-6', '18450516-9', 
                     '16665430-0', '20060224-8', '18317155-4', '16495551-5', '19257767-5', '15986931-8', 
                     '18914885-3', '21373938-7', '13367300-8', '18218726-7', '20001940-7', '19482527-4', 
                     '20883844-k', '18331635-8', '17204179-5', '20274956-1', '22337684-3', '15971013-6', 
                     '27979718-3', '22026750-8', '14060916-5', '21562316-5', '17016808-9', '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 11 creada';
    
    -- Emergencia 12: 10-01-2026 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-10', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', '22395855-1', 
                     '26255933-5') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 12 creada';
    
    -- Emergencia 13: 10-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-10', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 13 creada';
    
    -- Emergencia 14: 11-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-11', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 14 creada';
    
    -- Emergencia 15: 13-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-13', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', 
                     '10154142-8', '16796056-1', '16578803-6', '12173806-7', '19155567-8', '17174462-8', 
                     '17846577-1', '18002706-8', '15027199-k', '22395855-1', '20718120-6', '26255933-5', 
                     '18450516-9', '16665430-0', '20060224-8', '18317155-4', '16495551-5', '19257767-5', 
                     '15986931-8', '18914885-3', '21373938-7', '13367300-8', '18218726-7', '20001940-7', 
                     '19482527-4', '20883844-k', '18331635-8', '17204179-5', '20274956-1', '22337684-3', 
                     '15971013-6', '27979718-3', '22026750-8', '14060916-5', '21562316-5', '17016808-9', 
                     '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 15 creada';
    
    -- Emergencia 16: 15-01-2026 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-15', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 16 creada';
    
    -- Emergencia 17: 18-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-18', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('10154142-8', '16796056-1', '16578803-6', '12173806-7', '17174462-8', '17846577-1', 
                     '18002706-8', '15027199-k', '20718120-6', '18450516-9', '16665430-0', '20060224-8', 
                     '18317155-4', '16495551-5', '19257767-5', '15986931-8', '18914885-3', '21373938-7', 
                     '13367300-8', '18218726-7', '20001940-7', '19482527-4', '20883844-k', '18331635-8', 
                     '17204179-5', '20274956-1', '22337684-3', '15971013-6', '27979718-3', '22026750-8', 
                     '14060916-5', '21562316-5', '17016808-9', '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 17 creada';
    
    -- Emergencia 18: 18-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-18', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', 
                     '19155567-8', '22395855-1', '26255933-5') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 18 creada';
    
    -- Emergencia 19: 18-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-18', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 19 creada';
    
    -- Emergencia 20: 18-01-2026 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-18', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 20 creada';
    
    -- Emergencia 21: 21-01-2026 - 10-0
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-21', v_user_id, '10-0', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', 
                     '10154142-8', '16796056-1', '16578803-6', '12173806-7', '19155567-8', '17174462-8', 
                     '17846577-1', '18002706-8', '15027199-k', '22395855-1', '20718120-6', '26255933-5', 
                     '18450516-9', '16665430-0', '20060224-8', '18317155-4', '16495551-5', '19257767-5', 
                     '15986931-8', '18914885-3', '21373938-7', '13367300-8', '18218726-7', '20001940-7', 
                     '19482527-4', '20883844-k', '18331635-8', '17204179-5', '20274956-1', '22337684-3', 
                     '15971013-6', '27979718-3', '22026750-8', '14060916-5', '21562316-5', '17016808-9', 
                     '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 21 creada';
    
    -- Emergencia 22: 22-01-2026 - 10-0
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-22', v_user_id, '10-0', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 22 creada';
    
    -- Emergencia 23: 23-01-2026 - 10-0
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-23', v_user_id, '10-0', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 23 creada';
    
    -- Emergencia 24: 25-01-2026 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-25', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 24 creada';
    
    -- Emergencia 25: 26-01-2026 - 10-1
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-26', v_user_id, '10-1', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', 
                     '10154142-8', '16796056-1', '16578803-6', '12173806-7', '19155567-8', '17174462-8', 
                     '17846577-1', '18002706-8', '15027199-k', '22395855-1', '20718120-6', '26255933-5', 
                     '18450516-9', '16665430-0', '20060224-8', '18317155-4', '16495551-5', '19257767-5', 
                     '15986931-8', '18914885-3', '21373938-7', '13367300-8', '18218726-7', '20001940-7', 
                     '19482527-4', '20883844-k', '18331635-8', '17204179-5', '20274956-1', '22337684-3', 
                     '15971013-6', '27979718-3', '22026750-8', '14060916-5', '21562316-5', '17016808-9', 
                     '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 25 creada';
    
    -- Emergencia 26: 26-01-2026 - 10-12
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-26', v_user_id, '10-12', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 26 creada';
    
    -- Emergencia 27: 26-01-2026 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-26', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        INSERT INTO attendance_records (event_id, user_id, status, is_locked)
        VALUES (v_event_id, v_user_record.id, 'absent', false);
    END LOOP;
    RAISE NOTICE 'Emergencia 27 creada';
    
    -- Emergencia 28: 29-01-2026 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-29', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', 
                     '10154142-8', '16796056-1', '16578803-6', '12173806-7', '19155567-8', '17174462-8', 
                     '17846577-1', '18002706-8', '15027199-k', '22395855-1', '20718120-6', '26255933-5', 
                     '18450516-9', '16665430-0', '20060224-8', '18317155-4', '16495551-5', '19257767-5', 
                     '15986931-8', '18914885-3', '21373938-7', '13367300-8', '18218726-7', '20001940-7', 
                     '19482527-4', '20883844-k', '18331635-8', '17204179-5', '20274956-1', '22337684-3', 
                     '15971013-6', '27979718-3', '22026750-8', '14060916-5', '21562316-5', '17016808-9', 
                     '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 28 creada';
    
    -- Emergencia 29: 31-01-2026 - 10-0
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-31', v_user_id, '10-0', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', 
                     '10154142-8', '16796056-1', '16578803-6', '12173806-7', '19155567-8', '17174462-8', 
                     '17846577-1', '18002706-8', '15027199-k', '22395855-1', '20718120-6', '26255933-5', 
                     '18450516-9', '16665430-0', '20060224-8', '18317155-4', '16495551-5', '19257767-5', 
                     '15986931-8', '18914885-3', '21373938-7', '13367300-8', '18218726-7', '20001940-7', 
                     '19482527-4', '20883844-k', '18331635-8', '17204179-5', '20274956-1', '22337684-3', 
                     '15971013-6', '27979718-3', '22026750-8', '14060916-5', '21562316-5', '17016808-9', 
                     '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 29 creada';
    
    -- Emergencia 30: 31-01-2026 - 10-0
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-31', v_user_id, '10-0', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        IF v_rut IN ('7538193-k', '9378802-8', '13238728-1', '13368329-9', '13504531-5', '14120786-5', 
                     '10154142-8', '16796056-1', '16578803-6', '12173806-7', '19155567-8', '17174462-8', 
                     '17846577-1', '18002706-8', '15027199-k', '22395855-1', '20718120-6', '26255933-5', 
                     '18450516-9', '16665430-0', '20060224-8', '18317155-4', '16495551-5', '19257767-5', 
                     '15986931-8', '18914885-3', '21373938-7', '13367300-8', '18218726-7', '20001940-7', 
                     '19482527-4', '20883844-k', '18331635-8', '17204179-5', '20274956-1', '22337684-3', 
                     '15971013-6', '27979718-3', '22026750-8', '14060916-5', '21562316-5', '17016808-9', 
                     '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 30 creada';
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'CARGA COMPLETADA EXITOSAMENTE';
    RAISE NOTICE '3 Citaciones + 30 Emergencias = 33 eventos';
    RAISE NOTICE '============================================';
    
END $$;
