# 🚀 Guía de Deployment - Sexta Compañía ERP

## 📋 Requisitos Previos

Antes de empezar, asegúrate de tener:

- ✅ Acceso a cPanel de tu hosting
- ✅ Flutter instalado localmente
- ✅ Proyecto compilando sin errores
- ✅ Credenciales de Supabase configuradas

---

## 🎯 Opción 1: Deployment Manual a cPanel (Recomendado para empezar)

### Paso 1: Compilar el proyecto Flutter

```bash
# Navegar al directorio del proyecto
cd c:\Sexta_app

# Limpiar builds anteriores
flutter clean

# Obtener dependencias
flutter pub get

# Compilar para producción
flutter build web --release
```

**Verificar:** Debe aparecer `✓ Built build\web` sin errores.

---

### Paso 2: Preparar archivos para upload

**Opción A: Comprimir en .zip (recomendado)**

1. Navegar a `c:\Sexta_app\build\web`
2. Seleccionar **todos** los archivos dentro de `web` (NO la carpeta web misma)
3. Clic derecho → "Enviar a" → "Carpeta comprimida"
4. Nombrar: `erp-build.zip`

**Opción B: Usar PowerShell**

```powershell
cd c:\Sexta_app\build\web
Compress-Archive -Path * -DestinationPath erp-build.zip
```

---

### Paso 3: Crear subdominio en cPanel

1. **Ingresar a cPanel** de tu hosting
2. Ir a sección **"Dominios"** o **"Subdominios"**
3. Crear nuevo subdominio:
   - **Nombre:** `erp` (o el que prefieras)
   - **Dominio principal:** Tu dominio de la tienda
   - **Directorio raíz:** `/public_html/erp` (se crea automáticamente)
4. Click en **"Crear"**

**Resultado:** Tendrás `erp.tutienda.cl` apuntando a `/public_html/erp/`

---

### Paso 4: Subir archivos a cPanel

#### Método A: File Manager de cPanel (Más fácil)

1. En cPanel, abrir **"Administrador de archivos"**
2. Navegar a `/public_html/erp/`
3. Click en **"Cargar"** (Upload)
4. Seleccionar `erp-build.zip`
5. Esperar a que termine de subir (puede tardar 2-5 minutos)
6. Una vez subido, **clic derecho** en `erp-build.zip`
7. Seleccionar **"Extraer"** (Extract)
8. Confirmar que se extraiga en `/public_html/erp/`
9. **Eliminar** el archivo `erp-build.zip` (ya no necesario)

#### Método B: FTP (Alternativo)

1. Descargar FileZilla (si no lo tienes)
2. Conectar con credenciales FTP de cPanel
3. Navegar a `/public_html/erp/`
4. Arrastrar **todos** los archivos de `build\web\` (descomprimidos)
5. Esperar a que termine

---

### Paso 5: Subir archivo .htaccess

El archivo `.htaccess` ya está en tu proyecto (`c:\Sexta_app\.htaccess`)

1. En File Manager de cPanel, navegar a `/public_html/erp/`
2. Click en **"Cargar"**
3. Seleccionar `c:\Sexta_app\.htaccess`
4. Verificar que esté en `/public_html/erp/.htaccess`

**⚠️ IMPORTANTE:** En cPanel, asegúrate de que la opción **"Mostrar archivos ocultos"** esté activada para ver el `.htaccess`

---

### Paso 6: Configurar SSL (Let's Encrypt)

1. En cPanel, ir a **"SSL/TLS Status"**
2. Buscar tu subdominio `erp.tutienda.cl`
3. Si no tiene SSL, click en **"Run AutoSSL"**
4. Esperar 1-2 minutos
5. Verificar que aparezca ✅ verde

**Verificar SSL:**
- Visitar `https://erp.tutienda.cl`
- Debe aparecer 🔒 candado verde en el navegador

---

### Paso 7: Configurar Supabase

1. Ir a [Supabase Dashboard](https://supabase.com/dashboard)
2. Seleccionar tu proyecto
3. Ir a **Settings → API**
4. Scroll hasta **"URL Configuration"**
5. En **"Site URL"**, cambiar a: `https://erp.tutienda.cl`
6. En **"Redirect URLs"**, agregar: `https://erp.tutienda.cl/**`
7. Click **"Save"**

---

### Paso 8: Verificar funcionamiento

**Checklist de verificación:**

- [ ] Visitar `https://erp.tutienda.cl`
- [ ] Ver la pantalla de login (sin errores de consola)
- [ ] Navegar a `https://erp.tutienda.cl/request-permission`
- [ ] Ver el formulario de permisos
- [ ] Abrir DevTools (F12) → Consola → No debe haber errores
- [ ] Verificar conexión a Supabase (intentar login)

**Si todo funciona:** ¡Deployment exitoso! 🎉

---

## 🔄 Opción 2: Script de Deployment Automatizado (Próximamente)

Una vez que el deployment manual funcione, podemos crear un script para automatizar:

```bash
# Script futuro
./deploy.sh
```

Esto hará:
1. Build automático
2. Compresión
3. Upload via FTP
4. Notificación de éxito

---

## 🐛 Solución de Problemas Comunes

### Problema: "404 Not Found" al navegar a rutas

**Solución:** Verificar que `.htaccess` esté en la carpeta correcta y con el contenido completo.

```bash
# En cPanel File Manager, verificar:
/public_html/erp/.htaccess
```

---

### Problema: Errores de CORS en consola

**Solución:** Verificar configuración de Supabase

1. Ir a Supabase → Settings → API
2. Agregar tu dominio a "Redirect URLs"
3. Guardar cambios

---

### Problema: SSL no funciona

**Solución:**

1. Verificar que el dominio apunte correctamente a tu hosting
2. Esperar propagación DNS (puede tardar hasta 24 horas)
3. Re-ejecutar AutoSSL en cPanel

---

### Problema: Página en blanco

**Solución:**

1. Abrir DevTools (F12) → Consola
2. Revisar errores
3. Verificar que todos los archivos se hayan subido correctamente
4. Verificar que `index.html` esté en la raíz de `/public_html/erp/`

---

## 📊 Checklist Post-Deployment

- [ ] SSL activo (candado verde)
- [ ] Todas las rutas funcionando
- [ ] Login funcional
- [ ] Conexión a Supabase OK
- [ ] Sin errores en consola
- [ ] Responsive design OK
- [ ] Probar en Chrome, Firefox, Edge
- [ ] Probar en móvil
- [ ] Compartir URL con oficiales para demos

---

## 🔄 Actualizaciones Futuras

Cuando hagas cambios en el código:

1. Hacer cambios en código local
2. Compilar: `flutter build web --release`
3. Comprimir nueva build
4. Subir y reemplazar archivos en cPanel
5. Limpiar caché del navegador (Ctrl + Shift + R)

**Tip:** Mantén un backup del `.zip` anterior por si necesitas rollback.

---

## 📞 Soporte

Si tienes problemas:

1. Revisar esta guía completa
2. Verificar logs en cPanel → Metrics → Errors
3. Verificar consola del navegador (F12)
4. Consultar documentación de tu proveedor de hosting

---

## 🎯 Próximos Pasos

Una vez que el deployment temporal funcione:

1. [ ] Recopilar feedback de oficiales
2. [ ] Completar módulos pendientes
3. [ ] Registrar dominio definitivo
4. [ ] Migrar a dominio oficial
5. [ ] Configurar backups automáticos

---

**¡Buena suerte con el deployment! 🚀**
