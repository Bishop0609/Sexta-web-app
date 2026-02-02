# 🚀 Guía de Deployment - iHost.cl
## Sexta Compañía ERP → sgi.sextacoquimbo.cl

Esta guía está personalizada para tu configuración específica.

---

## 📋 Tu Configuración

- **Proveedor:** iHost.cl
- **Dominio definitivo:** `sgi.sextacoquimbo.cl`
- **Carpeta en servidor:** `/public_html/sgi/`
- **URL final:** `https://sgi.sextacoquimbo.cl`

---

## 🎯 Paso 1: Crear Subdominio en iHost

### Acceder a cPanel

1. Ir a: https://ihost.cl/clientes/clientarea.php
2. Login con tus credenciales
3. Buscar tu dominio `sextacoquimbo.cl`
4. Click en **"Iniciar sesión en cPanel"**

### Crear el Subdominio

1. En cPanel, buscar sección **"DOMINIOS"**
2. Click en **"Subdominios"**
3. Llenar el formulario:
   ```
   Subdominio: sgi
   Dominio: sextacoquimbo.cl
   Raíz del documento: public_html/sgi
   ```
4. Click **"Crear"**

**Resultado esperado:**
✅ Subdominio creado: `sgi.sextacoquimbo.cl`  
✅ Carpeta creada: `/public_html/sgi/`

---

## 🔨 Paso 2: Compilar tu Aplicación

### Ejecutar Build Script

```powershell
# Abrir PowerShell
# Navegar a tu proyecto
cd c:\Sexta_app

# Ejecutar script de build
.\build-deploy.ps1
```

**Lo que verás:**
```
🚀 Sexta Compañía ERP - Build Script
======================================

📦 Step 1: Cleaning previous builds...
✅ Clean complete

📦 Step 2: Getting dependencies...
✅ Dependencies installed

🔨 Step 3: Building Flutter Web...
✅ Build complete

📄 Step 4: Copying .htaccess...
✅ .htaccess copied

📦 Step 5: Creating deployment ZIP file...
✅ ZIP created: erp-build-2026-01-10-2158.zip

📊 Build Information:
   File: erp-build-2026-01-10-2158.zip
   Size: X.XX MB

🎉 SUCCESS! Build ready for deployment
```

**Toma nota del nombre del archivo ZIP generado.**

---

## 📤 Paso 3: Subir Archivos a iHost

### Método: File Manager de cPanel (Recomendado)

1. **En cPanel, ir a "Administrador de archivos"**

2. **Navegar a la carpeta del subdominio:**
   - Click en `public_html`
   - Click en `sgi` (la carpeta que se creó automáticamente)

3. **Subir el archivo ZIP:**
   - Click en botón **"Cargar"** (arriba)
   - Se abrirá ventana de upload
   - Arrastrar o seleccionar: `erp-build-YYYY-MM-DD-HHmm.zip`
   - Esperar a que la barra llegue a 100%
   - Click **"Volver a..."** para regresar al File Manager

4. **Extraer el archivo:**
   - Ubicar el archivo ZIP en `/public_html/sgi/`
   - Click derecho sobre el ZIP
   - Seleccionar **"Extraer"** o **"Extract"**
   - Confirmar la ruta: `/public_html/sgi/`
   - Click **"Extract File(s)"**
   - Esperar a que termine

5. **Limpiar:**
   - Seleccionar el archivo ZIP
   - Click en **"Eliminar"** o **"Delete"**

6. **Verificar archivos:**
   - Deberías ver en `/public_html/sgi/`:
     ```
     .htaccess
     index.html
     favicon.png
     flutter.js
     manifest.json
     carpeta: assets/
     carpeta: canvaskit/
     carpeta: icons/
     ```

---

## 🔒 Paso 4: Configurar SSL (Let's Encrypt)

iHost.cl incluye SSL gratuito con Let's Encrypt.

### Activar SSL

1. **En cPanel, buscar sección "SEGURIDAD"**

2. **Click en "SSL/TLS Status"**

3. **Buscar tu subdominio:**
   - Buscar `sgi.sextacoquimbo.cl` en la lista

4. **Si no tiene SSL activo:**
   - Click en checkbox junto a `sgi.sextacoquimbo.cl`
   - Click en **"Run AutoSSL"**
   - Esperar 1-3 minutos

5. **Verificar:**
   - Debe aparecer ✅ verde junto al subdominio
   - Estado: "AutoSSL certificate installed"

### Forzar HTTPS (Opcional pero recomendado)

1. Ir al File Manager
2. Abrir archivo `/public_html/sgi/.htaccess`
3. Descomentar las últimas líneas (quitar los `#`):

```apache
# Este bloque debe quedar así (SIN los #):
<IfModule mod_rewrite.c>
  RewriteCond %{HTTPS} off
  RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</IfModule>
```

4. Guardar

**Ahora siempre redirigirá a HTTPS automáticamente.**

---

## ⚙️ Paso 5: Configurar Supabase

Tu app necesita que Supabase permita conexiones desde el nuevo dominio.

### Actualizar Allowed Origins

1. Ir a: https://supabase.com/dashboard

2. Seleccionar tu proyecto

3. **Settings → API**

4. Scroll hasta **"URL Configuration"**

5. **En "Site URL"**, cambiar a:
   ```
   https://sgi.sextacoquimbo.cl
   ```

6. **En "Redirect URLs"**, agregar:
   ```
   https://sgi.sextacoquimbo.cl/**
   ```

7. **Click "Save"**

---

## ✅ Paso 6: Verificación Final

### Checklist de Pruebas

1. **Verificar SSL:**
   - [ ] Visitar: `https://sgi.sextacoquimbo.cl`
   - [ ] Debe aparecer 🔒 candado verde
   - [ ] No debe haber advertencias de seguridad

2. **Verificar carga inicial:**
   - [ ] La pantalla de login debe aparecer
   - [ ] Logo y estilos deben cargar correctamente
   - [ ] No debe haber pantalla en blanco

3. **Verificar rutas de Flutter:**
   - [ ] `https://sgi.sextacoquimbo.cl/request-permission`
   - [ ] `https://sgi.sextacoquimbo.cl/act-types`
   - [ ] `https://sgi.sextacoquimbo.cl/shift-registration`
   - [ ] Todas deben cargar sin error 404

4. **Verificar consola del navegador:**
   - [ ] Presionar F12 para abrir DevTools
   - [ ] Ir a pestaña "Console"
   - [ ] No deben haber errores rojos críticos
   - [ ] Puede haber warnings (amarillo) - OK

5. **Verificar conexión a Supabase:**
   - [ ] Intentar navegar a cualquier módulo
   - [ ] No debe aparecer error de CORS
   - [ ] Datos deben cargar correctamente

### Si todo funciona ✅

**¡Felicitaciones! Tu aplicación está en producción temporal.**

Puedes compartir la URL con los oficiales:
```
https://sgi.sextacoquimbo.cl
```

---

## 🐛 Solución de Problemas Específicos iHost

### Problema: Error 500 al visitar el sitio

**Posible causa:** Error en `.htaccess`

**Solución:**
1. En File Manager, editar `.htaccess`
2. Verificar que no haya errores de sintaxis
3. Probar comentando todo el archivo (poner `#` al inicio de cada línea)
4. Si funciona, ir descomentando de a poco para encontrar la línea problemática

---

### Problema: "La conexión no es privada" (Error SSL)

**Posible causa:** SSL aún no propagado

**Solución:**
1. Esperar 5-10 minutos más
2. Limpiar caché del navegador (Ctrl + Shift + Delete)
3. Probar en modo incógnito
4. Si persiste después de 1 hora, re-ejecutar AutoSSL

---

### Problema: Archivos no se suben (error de cuota)

**Posible causa:** Espacio en disco lleno

**Solución:**
1. En cPanel → "Uso del disco"
2. Verificar cuánto espacio queda
3. Limpiar archivos innecesarios (backups viejos, logs, etc.)
4. Si es necesario, contactar soporte de iHost para aumentar cuota

---

### Problema: Error de CORS en consola

**Posible causa:** Supabase no configurado correctamente

**Solución:**
1. Verificar que agregaste `https://sgi.sextacoquimbo.cl` en Supabase
2. Incluir el `/**` al final para todas las rutas
3. Esperar 1-2 minutos para propagación
4. Hacer hard refresh del navegador (Ctrl + Shift + R)

---

## 🔄 Actualizaciones Futuras

Cuando hagas cambios en el código y quieras actualizar:

### Proceso Rápido

1. **Build:**
   ```powershell
   cd c:\Sexta_app
   .\build-deploy.ps1
   ```

2. **Backup (opcional pero recomendado):**
   - En cPanel File Manager
   - Seleccionar toda la carpeta `/public_html/sgi/`
   - Click "Compress" → Crear ZIP
   - Descargar como backup
   - Guardar con nombre: `backup-sgi-YYYY-MM-DD.zip`

3. **Upload nuevo build:**
   - Subir nuevo ZIP
   - Extraer
   - Reemplazar archivos cuando pregunte

4. **Verificar:**
   - Limpiar caché del navegador (Ctrl + Shift + R)
   - Probar funcionalidades actualizadas

---

## 📞 Soporte iHost

Si necesitas ayuda técnica específica de iHost:

- **Soporte:** https://ihost.cl/soporte
- **Teléfono:** +56 2 2941 9090
- **Email:** soporte@ihost.cl
- **Horario:** Lunes a Viernes 9:00 - 18:00 hrs

**Tip:** iHost tiene buen soporte en español y conocen bien las configuraciones de cPanel.

---

## 🎯 Próximos Hitos

### Corto Plazo (Esta semana)
- [x] Configurar subdominio ✅
- [ ] Primer deployment
- [ ] Verificar funcionamiento
- [ ] Compartir con 1-2 oficiales para feedback inicial

### Mediano Plazo (Próximas semanas)
- [ ] Recopilar feedback
- [ ] Arreglar bugs reportados
- [ ] Completar módulos pendientes
- [ ] Mejoras de UX según feedback

### Largo Plazo (1-2 meses)
- [x] Registrar dominio definitivo (`sextacoquimbo.cl`) ✅
- [x] Migrar app a dominio oficial (`sgi.sextacoquimbo.cl`) ✅
- [ ] Desarrollar página web institucional
- [ ] Configurar backups automáticos
- [ ] Habilitar seguridad en producción (RLS)

---

## 📊 Métricas de Éxito

Para medir si el deployment fue exitoso:

- ✅ SSL activo (candado verde)
- ✅ Tiempo de carga < 3 segundos
- ✅ Todas las rutas funcionando
- ✅ Sin errores en consola del navegador
- ✅ Conexión a Supabase OK
- ✅ Responsive (funciona en móvil)
- ✅ Feedback positivo de oficiales

---

**¡Todo listo para deployment! 🚀**

**Siguiente paso:** Ejecutar `.\build-deploy.ps1` y seguir esta guía paso a paso.
