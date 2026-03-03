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