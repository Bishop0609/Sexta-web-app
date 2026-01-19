# Guía: Compilar y Subir a Firebase Hosting

## 🚀 **Deployment de Sexta App a Firebase Hosting**

### Prerequisitos

✅ Flutter SDK instalado  
✅ Firebase CLI instalado (`npm install -g firebase-tools`)  
✅ Proyecto Firebase configurado  
✅ Acceso al proyecto Firebase

---

## 📋 **Pasos Completos**

### 1. **Build de la Aplicación Web**

```bash
cd c:\Sexta_app

# Compilar para producción
flutter build web --release
```

**Esto generará:**
- Carpeta `build\web` con todos los archivos compilados
- Archivos optimizados y minificados
- Index.html, main.dart.js, etc.

---

### 2. **Inicializar Firebase (Primera Vez)**

Si NO has inicializado Firebase antes:

```bash
# Login a Firebase
firebase login

# Inicializar proyecto (solo primera vez)
firebase init hosting
```

**Configuración:**
- **Public directory:** `build/web`
- **Configure as single-page app:** `y` (yes)
- **Overwrite index.html:** `n` (no)

---

### 3. **Deploy a Firebase Hosting**

```bash
# Deploy directo
firebase deploy --only hosting
```

**Salida esperada:**
```
=== Deploying to 'sexta-app'...

✔  hosting: Your site has been deployed!
Project Console: https://console.firebase.google.com/...
Hosting URL: https://sexta-app.web.app
```

---

## 🔄 **Flujo Completo (Updates)**

Cada vez que hagas cambios:

```bash
# 1. Compilar nueva versión
flutter build web --release

# 2. Deploy
firebase deploy --only hosting

# ✅ Listo!
```

---

## ⚙️ **Configuración firebase.json**

Archivo `firebase.json` (debe estar en raíz de proyecto):

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

---

## 🎯 **Comandos Útiles**

```bash
# Ver preview local antes de deploy
firebase serve --only hosting

# Deploy con custom message
firebase deploy --only hosting -m "Added new inspector ranks"

# Ver historial de deployments
firebase hosting:channel:list

# Rollback a versión anterior
firebase hosting:clone VERSION_ID:live VERSION_ID:live
```

---

## 📱 **URLs del Proyecto**

Después del deploy tendrás:

- **URL Producción:** `https://sexta-app.web.app`
- **URL Alternativa:** `https://sexta-app.firebaseapp.com`
- **Console:** `https://console.firebase.google.com`

---

## ✅ **Verificar Deploy Exitoso**

1. Abre `https://sexta-app.web.app`
2. Login con admin (12345678-9)
3. Crea nuevo usuario
4. Verifica dropdown de Rango
5. Debe mostrar:
   - Inspector M. Mayor ✓
   - Inspector M. Menor ✓

---

## 🐛 **Troubleshooting**

### Error: "Firebase command not found"
```bash
npm install -g firebase-tools
```

### Error: "No project active"
```bash
firebase use --add
# Selecciona tu proyecto
```

### Cambios no se ven
```bash
# Limpiar caché Flutter
flutter clean
flutter build web --release
firebase deploy --only hosting
```

### Build muy lento
```bash
# Build solo lo necesario
flutter build web --release --web-renderer canvaskit
```

---

## 🔒 **Configurar Custom Domain (Opcional)**

1. Firebase Console → Hosting
2. "Add custom domain"
3. Ingresar dominio (ej: `app.sextabomberos.cl`)
4. Seguir pasos de verificación DNS
5. Esperar propagación (~24hrs)

---

## 📊 **Monitoreo Post-Deploy**

```bash
# Ver analytics
firebase hosting:channel:open live

# Ver logs
firebase hosting:channel:list
```

---

## 🎉 **Deploy Exitoso!**

Tu app estará disponible en:
- ✅ `https://sexta-app.web.app`
- ✅ Accesible desde cualquier navegador
- ✅ Con nuevos rangos de Inspector

**Cualquier cambio futuro:**
```bash
flutter build web --release && firebase deploy --only hosting
```
