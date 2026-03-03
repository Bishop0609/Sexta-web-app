-- ============================================================================
-- CARGA MASIVA DE ASISTENCIAS - ENERO 2026 (GENERADO AUTOMÁTICAMENTE)
-- Datos reales de asistencias para pruebas de gráficas y KPIs
-- Creado por: Gunther Hicks (13238728-1)
-- ============================================================================

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
    
    -- ========================================================================
    -- CITACIONES (A, B, C)
    -- ========================================================================
    
    -- Citación A: 2026-01-06
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_reunion_id, '2026-01-06', v_user_id, 'Ordinaria', 'Cuartel 6')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('7538193-K', '9378802-8', '8475115-4', '13238728-1', '14120786-5', '12014087-6', '8911339-3', '12424620-2', '10354342-8', '16893165-4', '16796056-1', '17246390-8', '16578803-6', '17173806-7', '19155567-8', '17174462-8', '18002706-8', '19207195-K', '8504249-1', '20898179-K', '20718282-6', '26255933-5', '18450516-9', '19666430-0', '20006224-8', '12021385-7', '18317752-4', '16495851-5', '19257767-5', '15986931-8', '18003513-3', '18916885-3', '8409363-7', '7266367-5', '21373938-7', '13367300-8', '20001940-7', '20007469-6', '19485227-4', '20883844-K', '18317635-8', '20274556-3', '22337684-3', '20947252-K', '15571013-6', '27979718-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSIF v_rut IN ('13762331-5', '5658325-4', '17846677-1', '17204179-5', '21821282-4', '22026759-8', '15050916-5', '22691434-K', '21562316-5', '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'licencia', true);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Citación A creada';
    
    -- Citación B: 2026-01-17
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_reunion_id, '2026-01-17', v_user_id, 'Extraordinaria', 'Cuartel 6')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13238728-1', '13530831-5', '14120786-5', '12014087-6', '12424620-2', '10354342-8', '16893165-4', '16796056-1', '13762331-5', '17246390-8', '17173806-7', '19155567-8', '17174462-8', '17846677-1', '18002706-8', '19207195-K', '8504249-1', '20898179-K', '20718282-6', '26255933-5', '18450516-9', '19666430-0', '20006224-8', '12021385-7', '18317752-4', '16495851-5', '15986931-8', '18003513-3', '18916885-3', '8409363-7', '7266367-5', '21373938-7', '13367300-8', '20001940-7', '20007469-6', '19485227-4', '20883844-K', '20274556-3', '22337684-3', '20947252-K', '15571013-6', '15050916-5', '21844261-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSIF v_rut IN ('16578803-6', '5658325-4', '19257767-5', '18218726-7', '18317635-8', '17204179-5', '21821282-4', '22691434-K') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'licencia', true);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Citación B creada';
    
    -- Citación C: 2026-01-23
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_reunion_id, '2026-01-23', v_user_id, 'Extraordinaria', 'Cuartel 6')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13238728-1', '13530831-5', '14120786-5', '12014087-6', '12424620-2', '10354342-8', '16893165-4', '17246390-8', '17173806-7', '19155567-8', '17174462-8', '17846677-1', '18002706-8', '19207195-K', '20898179-K', '20718282-6', '18450516-9', '19666430-0', '18317752-4', '16495851-5', '15986931-8', '18003513-3', '18916885-3', '8409363-7', '7266367-5', '21373938-7', '13367300-8', '20001940-7', '20007469-6', '19485227-4', '20883844-K', '20274556-3', '20947252-K', '21821282-4', '22026759-8', '15050916-5', '22691434-K', '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSIF v_rut IN ('5658325-4', '20395855-2', '26255933-5', '20006224-8', '12021385-7', '19257767-5', '18317635-8', '15571013-6', '21562316-5') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'licencia', true);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Citación C creada';

    -- ========================================================================
    -- EMERGENCIAS (1-30)
    -- ========================================================================

    -- Emergencia 1: 2026-01-01 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-01', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('RUT', '17246390-8', '17174462-8', '8409363-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 1 creada';

    -- Emergencia 2: 2026-01-01 - 10-9
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-01', v_user_id, '10-9', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13530831-5', '12014087-6', '17246390-8', '19155567-8', '17846677-1', '13367300-8') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 2 creada';

    -- Emergencia 3: 2026-01-02 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-02', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('17246390-8', '19155567-8', '17174462-8', '26255933-5', '19666430-0', '21373938-7', '20001940-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 3 creada';

    -- Emergencia 4: 2026-01-03 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-03', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('26255933-5', '20006224-8', '13367300-8') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 4 creada';

    -- Emergencia 5: 2026-01-04 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-04', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('14120786-5', '19666430-0', '20006224-8', '21373938-7', '20001940-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 5 creada';

    -- Emergencia 6: 2026-01-06 - 10-3
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-06', v_user_id, '10-3', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13530831-5', '12424620-2', '17246390-8') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 6 creada';

    -- Emergencia 7: 2026-01-06 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-06', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13530831-5', '17246390-8', '16578803-6', '19666430-0', '21373938-7', '20001940-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 7 creada';

    -- Emergencia 8: 2026-01-06 - 10-6
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-06', v_user_id, '10-6', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13530831-5', '17246390-8', '20898179-K', '19666430-0') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 8 creada';

    -- Emergencia 9: 2026-01-07 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-07', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('14120786-5', '17246390-8', '16578803-6', '19207195-K', '8504249-1', '20898179-K', '18450516-9', '21373938-7', '20001940-7', '20274556-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 9 creada';

    -- Emergencia 10: 2026-01-07 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-07', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('17246390-8', '20898179-K', '21373938-7', '20001940-7', '20274556-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 10 creada';

    -- Emergencia 11: 2026-01-10 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-10', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13530831-5', '12014087-6', '12424620-2', '17173806-7', '19155567-8', '17846677-1', '18002706-8', '19666430-0', '15986931-8', '18003513-3', '20001940-7', '20883844-K', '18317635-8', '20274556-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 11 creada';

    -- Emergencia 12: 2026-01-10 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-10', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('7538193-K', '13530831-5', '12424620-2', '8504249-1', '19666430-0') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 12 creada';

    -- Emergencia 13: 2026-01-10 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-10', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('7538193-K', '13530831-5', '12424620-2', '19666430-0') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 13 creada';

    -- Emergencia 14: 2026-01-11 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-11', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13530831-5', '12424620-2', '19155567-8', '16495851-5', '19257767-5', '13367300-8', '22337684-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 14 creada';

    -- Emergencia 15: 2026-01-13 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-13', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('10354342-8', '16796056-1', '19155567-8', '19207195-K', '26255933-5', '18450516-9', '18317752-4', '18916885-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 15 creada';

    -- Emergencia 16: 2026-01-15 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-15', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('7538193-K', '13530831-5', '17174462-8', '18002706-8', '20718282-6', '26255933-5', '19666430-0', '15986931-8', '21373938-7', '13367300-8', '20001940-7', '20007469-6', '19485227-4', '20274556-3', '20947252-K') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 16 creada';

    -- Emergencia 17: 2026-01-18 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-18', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('16893165-4', '17246390-8', '17174462-8', '20718282-6', '13367300-8') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 17 creada';

    -- Emergencia 18: 2026-01-18 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-18', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('16893165-4', '17246390-8', '17174462-8', '20718282-6', '13367300-8') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 18 creada';

    -- Emergencia 19: 2026-01-18 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-18', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('16893165-4', '17246390-8', '17174462-8', '20718282-6', '13367300-8') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 19 creada';

    -- Emergencia 20: 2026-01-18 - 10-4
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-18', v_user_id, '10-4', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('12014087-6', '12424620-2', '10354342-8', '17246390-8', '19155567-8', '19666430-0', '20006224-8', '18317752-4', '8409363-7', '21373938-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 20 creada';

    -- Emergencia 21: 2026-01-21 - 10-0
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-21', v_user_id, '10-0', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('14120786-5', '12014087-6', '10354342-8', '16796056-1', '19155567-8', '19207195-K', '20898179-K', '18450516-9', '18317752-4', '18003513-3', '21373938-7', '20001940-7', '20274556-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 21 creada';

    -- Emergencia 22: 2026-01-22 - 10-0
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-22', v_user_id, '10-0', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13762331-5', '19155567-8', '26255933-5', '18317752-4', '18003513-3', '7266367-5', '20007469-6', '21821282-4', '22378557-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 22 creada';

    -- Emergencia 23: 2026-01-23 - 10-0
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-23', v_user_id, '10-0', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13530831-5', '12424620-2', '10354342-8', '19155567-8', '18317752-4', '7266367-5', '21373938-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 23 creada';

    -- Emergencia 24: 2026-01-25 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-25', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('7538193-K', '7266367-5', '20947252-K') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 24 creada';

    -- Emergencia 25: 2026-01-26 - 10-1
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-26', v_user_id, '10-1', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('14120786-5', '16796056-1', '19207195-K', '18450516-9', '18317752-4') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 25 creada';

    -- Emergencia 26: 2026-01-26 - 10-12
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-26', v_user_id, '10-12', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('13530831-5', '19155567-8', '17174462-8', '18317752-4', '20001940-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 26 creada';

    -- Emergencia 27: 2026-01-26 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-26', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('12424620-2', '19155567-8', '18317752-4', '20001940-7') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 27 creada';

    -- Emergencia 28: 2026-01-29 - 10-2
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-29', v_user_id, '10-2', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('14120786-5', '7266367-5', '19485227-4', '20274556-3') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 28 creada';

    -- Emergencia 29: 2026-01-31 - 10-0
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-31', v_user_id, '10-0', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('7538193-K', '10354342-8', '16796056-1', '21373938-7', '20001940-7', '20947252-K') THEN
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'present', false);
        ELSE
            INSERT INTO attendance_records (event_id, user_id, status, is_locked)
            VALUES (v_event_id, v_user_record.id, 'absent', false);
        END IF;
    END LOOP;
    RAISE NOTICE 'Emergencia 29 creada';

    -- Emergencia 30: 2026-01-31 - 10-0
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '2026-01-31', v_user_id, '10-0', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
        IF v_rut IN ('19155567-8', '17846677-1', '18002706-8', '20395855-2', '15986931-8', '7266367-5', '21373938-7', '20001940-7') THEN
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
