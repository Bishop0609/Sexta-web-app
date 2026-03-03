#!/usr/bin/env python3
"""
Generador automático de script SQL para carga de asistencias
Lee el Excel y genera el SQL sin errores de transcripción manual
"""

import pandas as pd

# Leer la hoja "Enero" con la matriz de asistencias
df = pd.read_excel('Datos para subir a SGI ene26.xlsx', sheet_name='Enero')

# Leer la hoja "Datos" con información de eventos
df_datos = pd.read_excel('Datos para subir a SGI ene26.xlsx', sheet_name='Datos', header=None)

# Extraer información de citaciones (filas 2-4, columnas 2-4)
citaciones = []
for i in range(2, 5):  # Filas 2, 3, 4 (A, B, C)
    citaciones.append({
        'letra': df_datos.iloc[i, 2],
        'fecha': df_datos.iloc[i, 3].strftime('%Y-%m-%d'),
        'tipo': df_datos.iloc[i, 4]
    })

# Extraer información de emergencias (desde fila 8 en adelante)
emergencias = []
row_idx = 8
while row_idx < len(df_datos) and pd.notna(df_datos.iloc[row_idx, 2]):
    fecha_val = df_datos.iloc[row_idx, 3]
    if isinstance(fecha_val, str):
        # Parsear formato "01-012026" a "2026-01-01"
        if '-' in fecha_val and len(fecha_val) == 9:
            dia = fecha_val[:2]
            mes = fecha_val[3:5]
            anio = fecha_val[5:]
            fecha = f"{anio}-{mes}-{dia}"
        else:
            fecha = fecha_val
    else:
        fecha = fecha_val.strftime('%Y-%m-%d')
    
    emergencias.append({
        'numero': int(df_datos.iloc[row_idx, 2]),
        'fecha': fecha,
        'subtipo': df_datos.iloc[row_idx, 4]
    })
    row_idx += 1

print(f"✅ Leídas {len(citaciones)} citaciones y {len(emergencias)} emergencias")

# Generar SQL
sql = """-- ============================================================================
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
"""

# Generar código para citaciones
for idx, cit in enumerate(citaciones):
    letra = cit['letra']
    fecha = cit['fecha']
    tipo_desc = cit['tipo']
    
    # Determinar subtipo
    if 'ordinaria' in tipo_desc.lower():
        subtipo = 'Ordinaria'
    else:
        subtipo = 'Extraordinaria'
    
    sql += f"""    
    -- Citación {letra}: {fecha}
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_reunion_id, '{fecha}', v_user_id, '{subtipo}', 'Cuartel 6')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
"""
    
    # Obtener RUTs presentes (valor = 1)
    col_idx = 2 + idx  # Columnas 2, 3, 4 para A, B, C
    presentes = df[df.iloc[:, col_idx] == 1]['Unnamed: 1'].tolist()
    presentes_str = "', '".join([str(r) for r in presentes])
    
    # Obtener RUTs con permiso (valor = 0.5)
    permisos = df[df.iloc[:, col_idx] == 0.5]['Unnamed: 1'].tolist()
    permisos_str = "', '".join([str(r) for r in permisos])
    
    if presentes:
        sql += f"        IF v_rut IN ('{presentes_str}') THEN\n"
        sql += "            INSERT INTO attendance_records (event_id, user_id, status, is_locked)\n"
        sql += "            VALUES (v_event_id, v_user_record.id, 'present', false);\n"
    
    if permisos:
        if presentes:
            sql += f"        ELSIF v_rut IN ('{permisos_str}') THEN\n"
        else:
            sql += f"        IF v_rut IN ('{permisos_str}') THEN\n"
        sql += "            INSERT INTO attendance_records (event_id, user_id, status, is_locked)\n"
        sql += "            VALUES (v_event_id, v_user_record.id, 'licencia', true);\n"
    
    sql += "        ELSE\n"
    sql += "            INSERT INTO attendance_records (event_id, user_id, status, is_locked)\n"
    sql += "            VALUES (v_event_id, v_user_record.id, 'absent', false);\n"
    sql += "        END IF;\n"
    sql += "    END LOOP;\n"
    sql += f"    RAISE NOTICE 'Citación {letra} creada';\n"

sql += """
    -- ========================================================================
    -- EMERGENCIAS (1-30)
    -- ========================================================================
"""

# Generar código para emergencias
for idx, emerg in enumerate(emergencias):
    numero = emerg['numero']
    fecha = emerg['fecha']
    subtipo = emerg['subtipo']
    
    sql += f"""
    -- Emergencia {numero}: {fecha} - {subtipo}
    INSERT INTO attendance_events (act_type_id, event_date, created_by, subtype, location)
    VALUES (v_emergencia_id, '{fecha}', v_user_id, '{subtipo}', 'Sin direccion')
    RETURNING id INTO v_event_id;
    
    FOR v_user_record IN SELECT u.id, u.rut FROM users u ORDER BY u.rut LOOP
        v_rut := v_user_record.rut;
        
"""
    
    # Obtener RUTs presentes (valor = 1)
    col_idx = 5 + idx  # Columnas 5-34 para emergencias 1-30
    presentes = df[df.iloc[:, col_idx] == 1]['Unnamed: 1'].tolist()
    
    if presentes:
        presentes_str = "', '".join([str(r) for r in presentes])
        sql += f"        IF v_rut IN ('{presentes_str}') THEN\n"
        sql += "            INSERT INTO attendance_records (event_id, user_id, status, is_locked)\n"
        sql += "            VALUES (v_event_id, v_user_record.id, 'present', false);\n"
        sql += "        ELSE\n"
        sql += "            INSERT INTO attendance_records (event_id, user_id, status, is_locked)\n"
        sql += "            VALUES (v_event_id, v_user_record.id, 'absent', false);\n"
        sql += "        END IF;\n"
    else:
        # Si nadie asistió, todos ausentes
        sql += "        INSERT INTO attendance_records (event_id, user_id, status, is_locked)\n"
        sql += "        VALUES (v_event_id, v_user_record.id, 'absent', false);\n"
    
    sql += "    END LOOP;\n"
    sql += f"    RAISE NOTICE 'Emergencia {numero} creada';\n"

sql += """
    RAISE NOTICE '============================================';
    RAISE NOTICE 'CARGA COMPLETADA EXITOSAMENTE';
    RAISE NOTICE '3 Citaciones + 30 Emergencias = 33 eventos';
    RAISE NOTICE '============================================';
    
END $$;
"""

# Guardar SQL
with open('supabase_load_january_2026_attendance_CORRECTED.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

print("✅ Script SQL generado: supabase_load_january_2026_attendance_CORRECTED.sql")
print(f"   - {len(citaciones)} citaciones")
print(f"   - {len(emergencias)} emergencias")
