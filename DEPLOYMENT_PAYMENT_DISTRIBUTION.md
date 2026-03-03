# Guía de Despliegue - Corrección de Pagos de Tesorería

## ⚠️ IMPORTANTE: Orden de Ejecución

Debes ejecutar los scripts en este orden exacto:

1. ✅ **Primero**: `supabase_distribute_payment_function.sql` (función nueva)
2. ✅ **Segundo**: `supabase_fix_existing_payments.sql` (corrección de datos)

## Paso 1: Crear la Función de Distribución

### Archivo: `supabase_distribute_payment_function.sql`

1. Ir a https://supabase.com/dashboard
2. Seleccionar tu proyecto
3. Ir a **SQL Editor** en el menú lateral
4. Click en **New Query**
5. Copiar y pegar **TODO** el contenido de `supabase_distribute_payment_function.sql`
6. Click en **Run** (o Ctrl+Enter)

### ✅ Verificación

Debes ver el mensaje:
```
Función distribute_payment_to_months creada exitosamente
```

**Si hay error**, verifica que estés usando la versión más reciente del archivo (corregida para evitar ambigüedad de columnas).

---

## Paso 2: Corregir Pagos Existentes

### Archivo: `supabase_fix_existing_payments.sql`

Este script hará lo siguiente:

1. **Identificar** los pagos incorrectos de Javiera y Nicole
2. **Guardar** la información original en una tabla temporal
3. **Eliminar** los pagos incorrectos
4. **Redistribuir** correctamente usando la nueva función
5. **Verificar** que todo quedó correcto

### Ejecución

1. En el **SQL Editor** de Supabase
2. Click en **New Query**
3. Copiar y pegar **TODO** el contenido de `supabase_fix_existing_payments.sql`
4. Click en **Run**

### ✅ Verificación

Al final del script verás dos tablas de resultados:

**Para Javiera Moraga** (debe mostrar 12 filas):
```
full_name       | month | year | expected_amount | paid_amount | status | num_payments
Javiera Moraga  |   2   | 2025 |      2000      |    2000     |  paid  |      1
Javiera Moraga  |   3   | 2025 |      2000      |    2000     |  paid  |      1
Javiera Moraga  |   4   | 2025 |      2000      |    2000     |  paid  |      1
...
Javiera Moraga  |   1   | 2026 |      2000      |    2000     |  paid  |      1
```

**Para Nicole Castellon** (debe mostrar 2 filas):
```
full_name         | month | year | expected_amount | paid_amount | status | num_payments
Nicole Castellon  |   2   | 2026 |      5000      |    5000     |  paid  |      1
Nicole Castellon  |   3   | 2026 |      5000      |    5000     |  paid  |      1
```

---

## Paso 3: Verificación Manual en la Aplicación

1. Acceder a la aplicación web
2. Ir a **Tesorería** → **Registro de Pagos**
3. Seleccionar **Febrero 2025**
4. Buscar **Javiera Moraga**
   - ✅ Debe aparecer como "Pagado"
5. Cambiar a **Marzo 2025**
   - ✅ Javiera debe seguir apareciendo como "Pagado"
6. Repetir para todos los meses hasta **Enero 2026**

7. Seleccionar **Febrero 2026**
8. Buscar **Nicole Castellon**
   - ✅ Debe aparecer como "Pagado"
9. Cambiar a **Marzo 2026**
   - ✅ Nicole debe aparecer como "Pagado"

---

## ❌ Si Algo Sale Mal

### Problema: Error al ejecutar el primer script

**Error común**: `ERROR: 42P13: input parameters after one with a default value must also have defaults`

**Solución**: Asegúrate de usar la versión CORREGIDA del archivo `supabase_distribute_payment_function.sql` (los parámetros con DEFAULT están al final).

### Problema: No se encuentran los usuarios

**Síntoma**: El script dice "No se encontró el pago original de Javiera Moraga"

**Solución**: 
1. Ejecuta solo el PASO 1 del script de corrección (las consultas SELECT)
2. Verifica que los nombres coincidan exactamente
3. Si los nombres son diferentes, modifica las condiciones `WHERE` en el script

### Problema: Los montos no coinciden

Si los montos originales no son $24,000 y $10,000:

1. Ejecuta el PASO 1 del script de corrección para ver los montos reales
2. El script usará automáticamente los montos correctos (variable `v_amount`)

---

## 📊 Consultas Útiles

### Ver estado actual de Javiera:
```sql
SELECT 
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
WHERE u.full_name ILIKE '%javiera%moraga%'
  AND q.year IN (2025, 2026)
ORDER BY q.year, q.month;
```

### Ver estado actual de Nicole:
```sql
SELECT 
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
WHERE u.full_name ILIKE '%nicole%castellon%'
  AND q.year = 2026
ORDER BY q.month;
```

### Ver todos los pagos registrados:
```sql
SELECT 
    u.full_name,
    p.amount,
    p.payment_date,
    p.notes,
    q.month,
    q.year
FROM treasury_payments p
JOIN treasury_monthly_quotas q ON p.quota_id = q.id
JOIN users u ON p.user_id = u.id
WHERE u.full_name ILIKE '%javiera%moraga%' 
   OR u.full_name ILIKE '%nicole%castellon%'
ORDER BY u.full_name, q.year, q.month;
```

---

## 🎯 Resumen

Después de ejecutar ambos scripts:

✅ **Javiera Moraga**: 12 cuotas pagadas (Feb 2025 - Ene 2026)  
✅ **Nicole Castellon**: 2 cuotas pagadas (Feb-Mar 2026)  
✅ **Función nueva**: Disponible para futuros pagos  
✅ **Sistema**: Detecta automáticamente sobrantes y ofrece distribución  

---

## 📞 Soporte

Si encuentras algún problema:
1. Toma captura de pantalla del error
2. Ejecuta las "Consultas Útiles" y guarda los resultados
3. Avísame con esa información
