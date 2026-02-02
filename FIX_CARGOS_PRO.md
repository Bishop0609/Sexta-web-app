**✅ PROBLEMA RESUELTO - Cargos Pro-Tesorero y Pro-Secretario**

## Causa del Problema
Los cargos "Pro-Tesorero(a)" y "Pro-Secretario(a)" tenían el sufijo "(a)" que estaba causando problemas al guardar en la base de datos (mismo problema que tuvimos anteriormente con otros cargos).

## Solución Aplicada
Eliminé el sufijo "(a)" de los cargos en el formulario de usuario:
- ❌ "Pro-Tesorero(a)" → ✅ "Pro-Tesorero"
- ❌ "Pro-Secretario(a)" → ✅ "Pro-Secretario"

## Cambios Realizados
**Archivo:** `lib/screens/users/user_management_screen.dart`
- Línea 658: `'Pro-Secretario(a)'` → `'Pro-Secretario'`
- Línea 660: `'Pro-Tesorero(a)'` → `'Pro-Tesorero'`

## Pruebas a Realizar
1. Editar un usuario existente
2. Cambiar su cargo a "Pro-Tesorero" o "Pro-Secretario"
3. Guardar cambios
4. Verificar que el cargo se guardó correctamente
5. Cambiar el rol a "Oficial 6: Tesorero"
6. Verificar que el rol también se guarda

## Nota Importante
Si ya tienes usuarios con los cargos antiguos "Pro-Tesorero(a)" o "Pro-Secretario(a)" en la base de datos, necesitarás actualizarlos manualmente en Supabase con este script:

```sql
-- Actualizar cargos con (a) a versión sin (a)
UPDATE users SET rank = 'Pro-Tesorero' WHERE rank = 'Pro-Tesorero(a)';
UPDATE users SET rank = 'Pro-Secretario' WHERE rank = 'Pro-Secretario(a)';

-- Verificar cambios
SELECT id, full_name, rank FROM users 
WHERE rank IN ('Pro-Tesorero', 'Pro-Secretario');
```

La app ya está actualizada con hot reload. Prueba ahora editar un usuario y cambiar su cargo.
