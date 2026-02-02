## 📧 Script para Identificar Email Genérico

He creado el archivo [`supabase_list_emails.sql`](file:///c:/Sexta_app/supabase_list_emails.sql) con dos consultas:

### Consulta 1: Emails Agrupados (Recomendada)
```sql
SELECT 
  email,
  COUNT(*) as cantidad_usuarios,
  STRING_AGG(full_name, ', ' ORDER BY full_name) as usuarios
FROM users
WHERE email IS NOT NULL
GROUP BY email
ORDER BY cantidad_usuarios DESC, email;
```

**Esto te mostrará:**
- Cada email único
- Cuántos usuarios lo usan
- Nombres de los usuarios

**El email genérico será el que tenga `cantidad_usuarios > 1`**

### Consulta 2: Lista Completa
```sql
SELECT 
  full_name,
  email,
  rank,
  role
FROM users
ORDER BY email, full_name;
```

---

## ✅ Cambios Realizados

### 1. Texto del Email Actualizado

**ANTES:**
```
📅 Nueva Actividad Programada
Se ha programado una nueva actividad:
```

**AHORA:**
```
📅 Citación Programada
Este es un correo automático para recordarte la siguiente citación:
```

### 2. Lista de Exclusión Agregada

En [`email_service.dart`](file:///c:/Sexta_app/lib/services/email_service.dart#L262-L271):

```dart
// Lista de emails genéricos a excluir
const excludedEmails = [
  // TODO: Agregar el email genérico que identifiques
  // Ejemplo: 'generico@sextacoquimbo.cl',
];

// No enviar a emails excluidos
if (excludedEmails.contains(userEmail.toLowerCase())) {
  return false;
}
```

---

## 📋 Próximos Pasos

1. **Ejecuta el script SQL** en Supabase SQL Editor
2. **Identifica el email genérico** (el que tiene múltiples usuarios)
3. **Dime cuál es** y lo agregaré a la lista de exclusión
4. **Listo para probar** la creación de la academia

¿Qué email genérico encontraste?
