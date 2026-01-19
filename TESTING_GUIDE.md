# 🧪 Guía de Testing - Sistema de Autenticación

## ✅ Estado Actual

- ✅ SQL Ejecutado en Supabase
- ✅ Código compilado sin errores
- ✅ App corriendo en Chrome
- ⏳ Listo para testing

---

## 📝 Instrucciones de Testing

### Paso 1: Ir a la pantalla de Login

La app debería abrir automáticamente en Chrome en:
```
http://localhost:XXXXX/login
```

Si no abrió automáti camente,  busca el puerto en la consola donde dice:
```
Flutter run key commands...
```

---

### Paso 2: Probar Login con Password Genérica

**Credenciales de prueba:**

```
RUT: 12345678-9
Password: Bombero2024!
```

**Flujo esperado:**

1. ✅ Ingresar RUT: `12345678-9`
2. ✅ Ingresar Password: `Bombero2024!`
3. ✅ Click "INGRESAR"
4. ✅ **DEBE redirigir automáticamente a `/change-password`**
5. ✅ Pantalla "Cambiar Contraseña" aparece

**Si algo falla:**
- Abrir DevTools (F12)
- Ver consola para errores
- Reportar cualquier mensaje de error

---

### Paso 3: Cambiar Contraseña

**En la pantalla de cambio de contraseña:**

1. ✅ **Contraseña Temporal:** `Bombero2024!`
2. ✅ **Nueva Contraseña:** Ej: `MiClave2026!`
3. ✅ **Confirmar:** `MiClave2026!`
4. ✅ Click "CAMBIAR CONTRASEÑA"

**Validaciones a verificar:**
- [ ] Password temporal incorrecta muestra error
- [ ] Password muy corta muestra error (<8 chars)
- [ ] Sin mayúscula muestra error
- [ ] Sin número muestra error
- [ ] Sin carácter especial muestra error
- [ ] Passwords no coincidentes muestra error

**Resultado esperado:**
- ✅ Mensaje "Contraseña cambiada exitosamente"
- ✅ Redirige a Dashboard (`/`)

---

### Paso 4: Verificar Dashboard y Sesión

**Check Dashboard:**
- [ ] Dashboard carga correctamente
- [ ] Drawer muestra tu nombre: "Juan Pérez Admin"
- [ ] Email correcto en drawer
- [ ] Menú visible según tu rol

**Abrir Drawer (menú lateral):**
- Click en ≡ (hamburguesa) arriba a la izquierda
- Verificar nombre de usuario
- Verificar que muestra los módulos correctos

---

### Paso 5: Probar Módulos (Sin error de autenticación)

**Ir a cada módulo y verificar que funciona:**

1. ✅ **Solicitar Permiso** (`/request-permission`)
   - Crear un permiso de prueba
   - Verificar que se guarda en BD

2. ✅ **Tomar Asistencia** (`/take-attendance`)
   - Seleccionar fecha de hoy
   - Tomar asistencia
   - Verificar que se guarda

3. ✅ **Inscribir Guardia** (`/shift-registration`)
   - Inscribirse en una fecha futura
   - Verificar que aparece

4. ✅ **Gestionar Permisos** (`/manage-permissions`) - Solo si eres admin/officer
   - Ver lista de permisos

5. ✅ **Tipos de Acto** (`/act-types`) - Solo si eres admin
   - Ver tipos de acto configurados

**¿Qué verificar?**
- [ ] NO debe aparecer error: "Usuario no autenticado"
- [ ] Datos se guardan correctamente
- [ ] No hay errores en consola del navegador

---

### Paso 6: Probar Persistencia de Sesión

**Refresh del navegador:**
1. Presionar F5 (refrescar)
2. ✅ Debe mantener sesión (no redirigir a login)
3. ✅ Usuario sigue autenticado
4. ✅ Dashboard carga normal

---

### Paso 7: Probar Logout

1. Abrir Drawer
2. Scroll hasta abajo
3. Click en "Cerrar Sesión" (rojo)
4. ✅ Debe redirigir a `/login`
5. ✅ Pantalla de login aparece

---

### Paso 8: Probar Re-Login con Nueva Contraseña

**Usando la contraseña que cambiaste:**

```
RUT: 12345678-9
Password: MiClave2026!  (la que creaste)
```

**Resultado esperado:**
- ✅ Login exitoso
- ✅ **NO redirige a change-password** (ya cambió la password)
- ✅ Va directo a Dashboard `/`

---

## 🐛 Troubleshooting

### Error: "RUT no encontrado"

**Causa:** RUT no existe en BD o formato incorrecto

**Solución:**
1. Verificar en Supabase Dashboard
2. Table Editor → `users`
3. Buscar un RUT que sí exista
4. Usar ese RUT para login

---

### Error: "Contraseña incorrecta"

**Causa:** Password genérica no fue creada correctamente

**Solución:**
1. Verificar en Supabase SQL Editor:
```sql
SELECT u.rut, u.full_name, 
       SUBSTRING(ac.password_hash, 1, 40) as hash_preview
FROM users u
JOIN auth_credentials ac ON u.id = ac.user_id
WHERE u.rut = '12345678-9';
```

2. Verificar que `hash_preview` empiece con: `BomberoSalt2024...`

---

### Error: No redirige a change password

**Causa:** Campo `requires_password_change` no está en `true`

**Solución:**
```sql
UPDATE auth_credentials
SET requires_password_change = true
WHERE user_id IN (
  SELECT id FROM users WHERE rut = '12345678-9'
);
```

---

### Navegador muestra pantalla en blanco

**Solución:**
1. Abrir DevTools (F12)
2. Ver consola para errores
3. Común: Error de CORS → Verificar configuración Supabase
4. Verificar que Supabase proyecto esté activo

---

## ✓ Checklist Completo

**Funcionalidad Básica:**
- [ ] Login con password funciona
- [ ] Cambio de contraseña obligatorio funciona
- [ ] Nueva contraseña se guarda
- [ ] Re-login con nueva password funciona
- [ ] Sesión persiste después de refresh
- [ ] Logout funciona

**Módulos (Sin errores de autenticación):**
- [ ] Solicitar Permiso guarda datos
- [ ] Tomar Asistencia guarda datos
- [ ] Inscribir Guardia guarda datos
- [ ] Módulos de admin/officer visibles según rol

**UX:**
- [ ] Botón "Olvidé mi contraseña" muestra diálogo
- [ ] Mensajes de error son claros
- [ ] Validaciones de password funcionan
- [ ] Drawer muestra información correcta

---

## 📊 Siguiente Paso

Una vez confirmado que todo funciona:

1. ✅ **Detener servidor local** (Ctrl+C en terminal)
2. ✅ **Ejecutar build script:**
   ```powershell
   .\build-deploy.ps1
   ```
3. ✅ **Subir a iHost.cl** según `DEPLOYMENT_IHOST.md`
4. ✅ **Probar en:** `https://sexta.tiendanatalia.cl`

---

## 💡 Tips de Testing

**Usar diferentes usuarios:**
- Admin: RUT del admin en tu BD
- Officer: RUT de un oficial
- Firefighter: RUT de un bombero

**Probar cada rol ve lo que debe:**
- Firefighters: Solo módulos públicos
- Officers: Módulos de gestión
- Admin: Todo

**Verificar en Supabase:**
- Table Editor → `auth_credentials`
- Ver que `requires_password_change` cambia a `false` después de cambiar

---

¡Buena suerte con el testing! 🚀

Si encuentras algún error, anota:
1. Qué acción estabas haciendo
2. Qué esperabas que pasara
3. Qué pasó realmente
4. Errores en consola (F12)
