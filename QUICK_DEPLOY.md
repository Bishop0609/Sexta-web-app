# 🚀 Quick Start - Deployment a cPanel

## Una sola vez: Ejecutar build script

```powershell
# En PowerShell, navegar al proyecto
cd c:\Sexta_app

# Ejecutar script de build
.\build-deploy.ps1
```

**Resultado:** Se creará archivo `erp-build-YYYY-MM-DD-HHmm.zip`

---

## Subir a cPanel

1. **Login a cPanel** → File Manager
2. **Navegar** a `/public_html/erp/`
3. **Upload** el archivo `.zip` generado
4. **Extract** el archivo ZIP
5. **Delete** el archivo ZIP

---

## Verificar

✅ Visitar: `https://erp.tudominio.cl`
✅ Verificar SSL (candado verde)
✅ Probar rutas: `/request-permission`, `/act-types`, etc.

---

## Archivos Importantes

| Archivo | Propósito |
|---------|-----------|
| `DEPLOYMENT_GUIDE.md` | Guía completa paso a paso |
| `MCP_CONFIGURATION.md` | Configuración de MCPs recomendados |
| `build-deploy.ps1` | Script automatizado de build |
| `.htaccess` | Configuración Apache para SPA |

---

## Próximo Deploy (actualizaciones)

1. Hacer cambios en código
2. Ejecutar: `.\build-deploy.ps1`
3. Subir nuevo `.zip` a cPanel
4. Reemplazar archivos
5. Limpiar caché: Ctrl + Shift + R

---

## Ayuda

📖 Ver documentación completa en: `DEPLOYMENT_GUIDE.md`
🔧 Configurar MCPs: `MCP_CONFIGURATION.md`
📊 Estado del proyecto: `ESTADO_PROYECTO.md`
