# 📥 Importación de Usuarios a Supabase

Este documento explica cómo importar los 69 usuarios desde el CSV a Supabase.

## 🎯 ¿Qué hace el script?

1. ✅ Lee el archivo `listado de usuarios para ingreso a BD 080126.csv`
2. ✅ Infiere automáticamente el género basado en los nombres
3. ✅ Crea cada usuario en **Supabase Auth** (sistema de autenticación)
4. ✅ Inserta los datos en la tabla **public.users**
5. ✅ Asigna contraseñas temporales basadas en el RUT

## 🔐 Contraseñas Temporales

Cada usuario tendrá una contraseña temporal con el formato:
```
RUT sin guión + "2026"
```

**Ejemplos:**
- RUT: `8726935-3` → Contraseña: `87269352026`
- RUT: `7538193-K` → Contraseña: `7538193K2026`

⚠️ **IMPORTANTE:** Los usuarios deben cambiar su contraseña en el primer login.

## 📋 Pre-requisitos

1. **Python 3.8 o superior** instalado
2. **Credenciales de Supabase:**
   - URL del proyecto (ej: `https://xxxxx.supabase.co`)
   - **Service Role Key** (NO la anon key)

### Dónde obtener las credenciales:

1. Ve a tu proyecto en Supabase: https://supabase.com/dashboard
2. Ve a **Settings** → **API**
3. Copia:
   - **Project URL**
   - **service_role** key (en la sección "Project API keys")

⚠️ **NUNCA uses la `anon` key** - necesitas la `service_role` key para crear usuarios.

## 🚀 Instalación y Uso

### Paso 1: Instalar dependencias

Abre PowerShell en la carpeta `c:\Sexta_app` y ejecuta:

```powershell
pip install -r requirements.txt
```

### Paso 2: Configurar credenciales

Edita el archivo `import_users_to_supabase.py` y completa las líneas 15-16:

```python
SUPABASE_URL = "https://tu-proyecto.supabase.co"
SUPABASE_SERVICE_KEY = "tu-service-role-key-aqui"
```

### Paso 3: Ejecutar el script

```powershell
python import_users_to_supabase.py
```

El script te pedirá confirmación antes de importar los usuarios.

## 📊 Mapeo de Campos

### Del CSV a la Base de Datos:

| Campo CSV         | Campo BD            | Ejemplo                          |
|-------------------|---------------------|----------------------------------|
| `rut`             | `rut`               | `8726935-3`                      |
| `full_name`       | `full_name`         | `Juan Antonio Henríquez Morales` |
| `victor_number`   | `victor_number`     | `1266`                           |
| `registro_compania` | `registro_compania` | `613`                          |
| `rank`            | `rank`              | `Inspector M. Mayor`             |
| `marital_status`  | `marital_status`    | `Casado/a` → `married`           |
| `email`           | `email`             | `ejemplo@gmail.com`              |
| `role`            | `role`              | `firefighter`, `admin`, `officer`|
| *(inferido)*      | `gender`            | `M` o `F` (inferido del nombre)  |

### Inferencia de Género:

El script analiza el primer nombre y lo compara con listas de nombres comunes:

- **Masculinos:** Juan, Mario, Eduardo, Carlos, etc. → `M`
- **Femeninos:** Sonia, Jennifer, Nicole, Paula, etc. → `F`

Si el nombre no está en las listas, usa heurísticas (nombres terminados en 'a' suelen ser femeninos).

### Estado Civil:

- `Casado/a` → `married`
- `Soltero/a` → `single`

### Emails faltantes:

Si un usuario no tiene email en el CSV, se genera uno automático:
```
RUT@sexta.cl
```
Ejemplo: `8726935-3@sexta.cl`

## 📝 Verificación Post-Importación

Después de ejecutar el script, verifica en Supabase:

1. **Tabla `users`:**
   ```sql
   SELECT COUNT(*) FROM users;
   -- Debería retornar 69
   ```

2. **Verificar usuarios por género:**
   ```sql
   SELECT gender, COUNT(*) 
   FROM users 
   GROUP BY gender;
   ```

3. **Verificar usuarios por rol:**
   ```sql
   SELECT role, COUNT(*) 
   FROM users 
   GROUP BY role;
   ```

## 🔧 Solución de Problemas

### Error: "Invalid API key"
- Verifica que estés usando la **service_role** key, no la `anon` key

### Error: "duplicate key value violates unique constraint"
- Ya existe un usuario con ese RUT o victor_number
- Revisa qué usuarios ya están en la BD

### Error: "permission denied"
- La `service_role` key tiene permisos completos
- Verifica que hayas copiado la key completa

### Error al importar archivo CSV
- Verifica que el archivo esté en la carpeta `c:\Sexta_app`
- Verifica que el nombre sea exactamente: `listado de usuarios para ingreso a BD 080126.csv`

## 🎓 Próximos Pasos

Después de importar los usuarios:

1. ✅ Notificar a cada usuario su contraseña temporal
2. ✅ Configurar política de cambio obligatorio de contraseña
3. ✅ Probar login con algunos usuarios de prueba
4. ✅ Verificar que los roles (admin, officer, firefighter) funcionen correctamente

## 📞 Soporte

Si encuentras algún problema durante la importación:
- Revisa los logs del script (muestra errores detallados)
- Verifica las credenciales de Supabase
- Asegúrate de que la tabla `users` exista con todos los campos necesarios
