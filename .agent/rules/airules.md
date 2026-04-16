---
trigger: always_on
---

AI Rules — Sexta App (Sexta Compañía de Coquimbo)
Idioma

Responde SIEMPRE en español chileno técnico.

Formato de respuestas

Sé conciso en explicaciones, pero incluye resúmenes estructurados al final cuando haya pasos o cambios múltiples.
Muestra SOLO las líneas de código que cambian, con máximo 3 líneas de contexto arriba/abajo.
Usa formato diff cuando sea posible (// ANTES: → // DESPUÉS:).
NO repitas código que no cambia.
NO repitas ni parafrasees el prompt del usuario.
NO agregues comentarios obvios en el código.
Omite imports a menos que sean nuevos o cambien.
Si la respuesta es un sí/no o un valor, responde en una línea.
Los resúmenes al final SÍ están permitidos: tablas, pasos numerados, checkboxes de verificación son útiles.

Contexto del proyecto (NO preguntar por esto)

Nombre: Sexta App
Tipo: Web App
Stack: Flutter + Dart, Supabase (DB, Auth, Storage, Edge Functions).
Organización: Sexta Compañía de Bomberos de Coquimbo, Chile.
Target: Web (Flutter web).
Estado: en desarrollo activo.

Comportamiento

Asume nivel intermedio-avanzado en Flutter/Dart y Supabase.
No expliques conceptos básicos de Flutter, widgets, o setState.
Si hay un error, ve directo a la causa y la solución.
Si necesitas más contexto, pide el bloque específico (función, clase), NO el archivo completo.
Cuando sugieras código, que sea copy-paste ready.
Prefiere soluciones con paquetes que ya usa el proyecto antes de sugerir dependencias nuevas.
Para SQL de Supabase, incluye siempre los pasos de despliegue (dónde ejecutar, qué esperar).

Prohibiciones (ahorro de tokens)

NO uses frases como "¡Claro!", "¡Por supuesto!", "Aquí tienes", "Espero que te sirva".
NO listes alternativas a menos que se pidan explícitamente.
NO generes tests a menos que se pidan.
NO muestres el archivo completo cuando solo cambian pocas líneas.
NO uses emojis excesivos. Máximo 1-2 por sección si es necesario.
NO preguntes "¿Todo claro?" o "¿Procedo?" al final — asume que sí.

Uso de MCP Supabase

NO explorar schemas completos. Si necesitas estructura, pide al usuario la tabla específica.
Limitar queries a máximo 10 filas con LIMIT 10 siempre.
NO hacer queries exploratorias múltiples. Preguntar primero qué tabla/dato se necesita.
Preferir que el usuario pegue el SQL cuando sea código nuevo largo.

Reglas SQL Supabase (críticas — bugs reales encontrados)
Timezone:

- Supabase corre en UTC. Chile es UTC-4 (sin DST) o UTC-3 (con DST).
- Para filtros de fecha en lógica de negocio: usar (NOW() AT TIME ZONE 'America/Santiago')::date
- NUNCA usar CURRENT_DATE solo. Devuelve UTC y causa bugs entre 20:00 y 23:59 hora Chile.
- NOW() es seguro SOLO para columnas timestamptz de auditoría (created_at, updated_at).
- Para comparar contra date o timestamp without time zone, convertir a Chile primero.

Variables en plpgsql:

- Variables locales con prefijo v_ (v_user_id, v_total_debt).
- Parámetros con prefijo p_ (p_user_id, p_amount).
- NUNCA usar el mismo nombre que una columna de tabla en variables locales.
- Ejemplo de bug real: DECLARE standard_quota INTEGER + SELECT standard_quota INTO standard_quota → siempre NULL.

Al generar funciones nuevas:

- Si la función filtra por "hoy", "mes actual", "año actual": usar la conversión a Chile.
- Si la función solo registra timestamps de cuándo pasó algo: NOW() está OK.
- En caso de duda, preguntar al usuario antes de elegir.

Patrones críticos del proyecto Sexta App:

- Tabla de usuarios se llama "users" (NO "usuarios"). Campos: full_name, rank (NO nombre/apellido/rango).
- Auth: usar AuthService().currentUser, NUNCA _supabase.auth.currentUser directamente.
- registro_compania puede ser "s/r" (no numérico) → usar int.tryParse() con default 9999.
- Edge Functions: deployar siempre con --no-verify-jwt. El toggle "Verify JWT" se resetea a ON tras cada deploy CLI.
- Emails @noemail.cl deben excluirse de envíos masivos.
- En queries Supabase: .eq() siempre antes de .order() (.order devuelve PostgrestTransformBuilder sin filtros).