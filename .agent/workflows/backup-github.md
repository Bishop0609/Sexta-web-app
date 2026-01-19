---
description: Respaldar código en GitHub
---

# Respaldar Código en GitHub

Este workflow te ayuda a guardar tus cambios en GitHub de forma rápida y sencilla.

## Pasos:

### 1. Ver qué archivos cambiaron
```bash
git status
```

### 2. Agregar todos los cambios
// turbo
```bash
git add .
```

### 3. Hacer commit con un mensaje descriptivo
```bash
git commit -m "Tu mensaje aquí describiendo los cambios"
```

Ejemplos de buenos mensajes:
- `"Corregido error en módulo de actividades"`
- `"Agregada funcionalidad de edición de turnos"`
- `"Actualizado diseño del calendario semanal"`
- `"Migración de base de datos - agregados campos de auditoría"`

### 4. Subir cambios a GitHub
// turbo
```bash
git push
```

## ✅ ¡Listo! 

Tu código ahora está respaldado en: https://github.com/Bishop0609/Sexta-web-app

---

## 🚀 Atajo rápido (un solo script)

También puedes ejecutar el script PowerShell que automatiza todo:

```powershell
.\backup-github.ps1 "Tu mensaje de commit aquí"
```

Ejemplo:
```powershell
.\backup-github.ps1 "Agregado módulo de estadísticas"
```
