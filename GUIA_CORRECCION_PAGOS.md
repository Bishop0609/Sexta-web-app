# Guía de Corrección - Pagos de Javiera y Nicole

## 🔍 Situación Actual

Según los resultados que obtuviste, Javiera tiene una situación extraña:

- **Enero 2025**: $24.000 pagados (¡todo el año en un solo mes!)
- **Feb-Jul 2025**: $4.000 pagados en cada mes
- **Ago-Dic 2025**: $0 pagados (pendiente)

**Esto no es correcto**. Debería ser $2.000 por mes durante 12 meses.

## 📋 Plan de Corrección

He creado un nuevo script con pasos seguros y controlados:

### Archivo: `supabase_fix_existing_payments.sql`

Este script tiene 5 pasos que debes ejecutar **uno por uno**:

---

## Paso a Paso

### 1️⃣ DIAGNÓSTICO (Solo Lectura)

**Ejecuta primero**: `supabase_diagnose_javiera_nicole.sql`

Esto te mostrará:
- Todos los pagos actuales de Javiera
- Todos los pagos actuales de Nicole
- Cuánto se pagó en total

**Copia y pega los resultados aquí para que los revise.**

---

### 2️⃣ VER ESTADO ACTUAL

Abre `supabase_fix_existing_payments.sql` y ejecuta **SOLO** el PASO 1 y PASO 2 (las primeras consultas SELECT).

Esto te mostrará:
- Estado de cada mes de Javiera
- Monto total pagado

**No hagas nada más todavía.**

---

### 3️⃣ LIMPIAR PAGOS INCORRECTOS

Una vez que confirmes que quieres proceder:

1. En `supabase_fix_existing_payments.sql`, busca el **PASO 3**
2. Encontrarás código comentado con `/* ... */`
3. **Descomenta** ese bloque (quita `/*` al inicio y `*/` al final)
4. Ejecuta **solo** ese bloque

Esto eliminará todos los pagos incorrectos de Javiera 2025 y Nicole 2026.

---

### 4️⃣ REDISTRIBUIR CORRECTAMENTE

1. Busca el **PASO 4** en el mismo archivo
2. **Descomenta** los dos bloques DO $$ (uno para Javiera, otro para Nicole)
3. Ejecuta ambos bloques

Esto redistribuirá:
- **Javiera**: $24.000 en 12 meses (Feb 2025 - Ene 2026)
- **Nicole**: $10.000 en 2 meses (Feb-Mar 2026)

---

### 5️⃣ VERIFICAR RESULTADOS

1. Busca el **PASO 5**
2. **Descomenta** las consultas de verificación
3. Ejecuta

**Resultado esperado para Javiera**:
```
month | year | expected_amount | paid_amount | status | num_payments
  2   | 2025 |      2000      |    2000     |  paid  |      1
  3   | 2025 |      2000      |    2000     |  paid  |      1
  4   | 2025 |      2000      |    2000     |  paid  |      1
  ...
  1   | 2026 |      2000      |    2000     |  paid  |      1
```

**Resultado esperado para Nicole**:
```
month | year | expected_amount | paid_amount | status | num_payments
  2   | 2026 |      5000      |    5000     |  paid  |      1
  3   | 2026 |      5000      |    5000     |  paid  |      1
```

---

## ⚠️ Importante

- **No ejecutes todo el script de una vez**
- Ejecuta paso por paso
- Revisa los resultados de cada paso antes de continuar
- Si algo no se ve bien, **detente** y avísame

---

## 🆘 Si Necesitas Ayuda

Ejecuta primero el diagnóstico (`supabase_diagnose_javiera_nicole.sql`) y envíame los resultados completos. Con eso podré ver exactamente qué está pasando y ajustar el script si es necesario.
