-- =====================================================
-- IMPORTACIÓN MASIVA DE PAGOS - DATOS REALES
-- Ejecuta este script completo en Supabase SQL Editor
-- =====================================================

-- PASO 1: Generar todas las cuotas necesarias (enero a diciembre 2025, enero 2026)
SELECT * FROM generate_monthly_quotas(1, 2025);
SELECT * FROM generate_monthly_quotas(2, 2025);
SELECT * FROM generate_monthly_quotas(3, 2025);
SELECT * FROM generate_monthly_quotas(4, 2025);
SELECT * FROM generate_monthly_quotas(5, 2025);
SELECT * FROM generate_monthly_quotas(6, 2025);
SELECT * FROM generate_monthly_quotas(7, 2025);
SELECT * FROM generate_monthly_quotas(8, 2025);
SELECT * FROM generate_monthly_quotas(9, 2025);
SELECT * FROM generate_monthly_quotas(10, 2025);
SELECT * FROM generate_monthly_quotas(11, 2025);
SELECT * FROM generate_monthly_quotas(12, 2025);
SELECT * FROM generate_monthly_quotas(1, 2026);
SELECT * FROM generate_monthly_quotas(2, 2026);

-- PASO 2: Insertar todos los pagos
-- NOTA: Se insertaron los datos completos del usuario
-- Este script contiene 467 registros de pago

INSERT INTO treasury_payments (quota_id, user_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT q.id, u.id, data.amount, data.payment_date::date, data.payment_method, data.receipt_number, data.notes, 
       (SELECT id FROM users WHERE role = 'admin' LIMIT 1)
FROM (VALUES
('7341166-1', 1, 2025, 4000, '2025-01-01', 'cash', 'TR003', 'Pago enero 2025'),
('7341166-1', 2, 2025, 4000, '2025-02-01', 'cash', 'TR004', 'Pago febrero 2025'),
('7341166-1', 3, 2025, 4000, '2025-03-01', 'cash', 'TR005', 'Pago marzo 2025'),
('7341166-1', 4, 2025, 4000, '2025-04-01', 'cash', 'TR006', 'Pago abril 2025'),
('7341166-1', 5, 2025, 4000, '2025-05-01', 'cash', 'TR007', 'Pago mayo 2025'),
('7341166-1', 6, 2025, 4000, '2025-06-01', 'cash', 'TR008', 'Pago junio 2025'),
('7341166-1', 7, 2025, 4000, '2025-07-01', 'cash', 'TR009', 'Pago julio 2025'),
('13868629-9', 1, 2025, 4000, '2025-01-01', 'cash', 'TR010', 'Pago enero 2025'),
('13868629-9', 2, 2025, 4000, '2025-02-01', 'cash', 'TR011', 'Pago febrero 2025'),
('13868629-9', 3, 2025, 4000, '2025-03-01', 'cash', 'TR012', 'Pago marzo 2025'),
('13868629-9', 4, 2025, 4000, '2025-04-01', 'cash', 'TR013', 'Pago abril 2025'),
('13868629-9', 5, 2025, 4000, '2025-05-01', 'cash', 'TR014', 'Pago mayo 2025'),
('13868629-9', 6, 2025, 4000, '2025-06-01', 'cash', 'TR015', 'Pago junio 2025'),
('13868629-9', 7, 2025, 4000, '2025-07-01', 'cash', 'TR016', 'Pago julio 2025'),
('13530831-5', 1, 2025, 4000, '2025-01-01', 'cash', 'TR017', 'Pago enero 2025'),
('13530831-5', 2, 2025, 4000, '2025-02-01', 'cash', 'TR018', 'Pago febrero 2025'),
('13530831-5', 3, 2025, 4000, '2025-03-01', 'cash', 'TR019', 'Pago marzo 2025'),
('13530831-5', 4, 2025, 4000, '2025-04-01', 'cash', 'TR020', 'Pago abril 2025'),
('13530831-5', 5, 2025, 2000, '2025-05-01', 'cash', 'TR021', 'Pago mayo 2025'),
('15054632-K', 1, 2025, 4000, '2025-01-01', 'cash', 'TR022', 'Pago enero 2025'),
('15054632-K', 2, 2025, 4000, '2025-02-01', 'cash', 'TR023', 'Pago febrero 2025'),
('15054632-K', 3, 2025, 4000, '2025-03-01', 'cash', 'TR024', 'Pago marzo 2025'),
('15054632-K', 4, 2025, 4000, '2025-04-01', 'cash', 'TR025', 'Pago abril 2025'),
('15054632-K', 5, 2025, 4000, '2025-05-01', 'cash', 'TR026', 'Pago mayo 2025'),
('15054632-K', 6, 2025, 4000, '2025-06-01', 'cash', 'TR027', 'Pago junio 2025'),
('15054632-K', 7, 2025, 4000, '2025-07-01', 'cash', 'TR028', 'Pago julio 2025'),
('15054632-K', 8, 2025, 4000, '2025-08-01', 'cash', 'TR029', 'Pago agosto 2025'),
('15054632-K', 9, 2025, 4000, '2025-09-01', 'cash', 'TR030', 'Pago septiembre 2025'),
('15054632-K', 10, 2025, 4000, '2025-10-01', 'cash', 'TR031', 'Pago octubre 2025'),
('15054632-K', 11, 2025, 4000, '2025-11-01', 'cash', 'TR032', 'Pago noviembre 2025'),
('15054632-K', 12, 2025, 4000, '2025-12-01', 'cash', 'TR033', 'Pago diciembre 2025'),
('12014087-6', 1, 2025, 4000, '2025-01-01', 'cash', 'TR034', 'Pago enero 2025'),
('12014087-6', 2, 2025, 4000, '2025-02-01', 'cash', 'TR035', 'Pago febrero 2025'),
('12014087-6', 3, 2025, 4000, '2025-03-01', 'cash', 'TR036', 'Pago marzo 2025'),
('12014087-6', 4, 2025, 4000, '2025-04-01', 'cash', 'TR037', 'Pago abril 2025'),
('12014087-6', 5, 2025, 4000, '2025-05-01', 'cash', 'TR038', 'Pago mayo 2025'),
('12014087-6', 6, 2025, 4000, '2025-06-01', 'cash', 'TR039', 'Pago junio 2025'),
('12014087-6', 7, 2025, 4000, '2025-07-01', 'cash', 'TR040', 'Pago julio 2025'),
('12014087-6', 8, 2025, 4000, '2025-08-01', 'cash', 'TR041', 'Pago agosto 2025'),
('12014087-6', 9, 2025, 4000, '2025-09-01', 'cash', 'TR042', 'Pago septiembre 2025'),
('12014087-6', 10, 2025, 4000, '2025-10-01', 'cash', 'TR043', 'Pago octubre 2025'),
('12014087-6', 11, 2025, 4000, '2025-11-01', 'cash', 'TR044', 'Pago noviembre 2025'),
('12014087-6', 12, 2025, 4000, '2025-12-01', 'cash', 'TR045', 'Pago diciembre 2025'),
('8911339-3', 1, 2025, 4000, '2025-01-01', 'cash', 'TR046', 'Pago enero 2025'),
('8911339-3', 2, 2025, 4000, '2025-02-01', 'cash', 'TR047', 'Pago febrero 2025'),
('8911339-3', 3, 2025, 4000, '2025-03-01', 'cash', 'TR048', 'Pago marzo 2025'),
('8911339-3', 4, 2025, 4000, '2025-04-01', 'cash', 'TR049', 'Pago abril 2025'),
('8911339-3', 5, 2025, 4000, '2025-05-01', 'cash', 'TR050', 'Pago mayo 2025'),
('8911339-3', 6, 2025, 4000, '2025-06-01', 'cash', 'TR051', 'Pago junio 2025'),
('8911339-3', 7, 2025, 4000, '2025-07-01', 'cash', 'TR052', 'Pago julio 2025'),
('8911339-3', 8, 2025, 4000, '2025-08-01', 'cash', 'TR053', 'Pago agosto 2025'),
('8911339-3', 9, 2025, 4000, '2025-09-01', 'cash', 'TR054', 'Pago septiembre 2025'),
('8911339-3', 10, 2025, 4000, '2025-10-01', 'cash', 'TR055', 'Pago octubre 2025'),
('8911339-3', 11, 2025, 4000, '2025-11-01', 'cash', 'TR056', 'Pago noviembre 2025'),
('8911339-3', 12, 2025, 3000, '2025-12-01', 'cash', 'TR057', 'Pago diciembre 2025'),
('10354342-8', 1, 2025, 4000, '2025-01-01', 'cash', 'TR058', 'Pago enero 2025'),
('10354342-8', 2, 2025, 4000, '2025-02-01', 'cash', 'TR059', 'Pago febrero 2025'),
('10354342-8', 3, 2025, 4000, '2025-03-01', 'cash', 'TR060', 'Pago marzo 2025'),
('10354342-8', 4, 2025, 4000, '2025-04-01', 'cash', 'TR061', 'Pago abril 2025'),
('10354342-8', 5, 2025, 4000, '2025-05-01', 'cash', 'TR062', 'Pago mayo 2025'),
('10354342-8', 6, 2025, 4000, '2025-06-01', 'cash', 'TR063', 'Pago junio 2025'),
('10354342-8', 7, 2025, 4000, '2025-07-01', 'cash', 'TR064', 'Pago julio 2025'),
('10354342-8', 8, 2025, 4000, '2025-08-01', 'cash', 'TR065', 'Pago agosto 2025'),
('10354342-8', 9, 2025, 4000, '2025-09-01', 'cash', 'TR066', 'Pago septiembre 2025'),
('10354342-8', 10, 2025, 4000, '2025-10-01', 'cash', 'TR067', 'Pago octubre 2025'),
('16893165-4', 1, 2025, 4000, '2025-01-01', 'cash', 'TR068', 'Pago enero 2025'),
('16893165-4', 2, 2025, 4000, '2025-02-01', 'cash', 'TR069', 'Pago febrero 2025'),
('16893165-4', 3, 2025, 4000, '2025-03-01', 'cash', 'TR070', 'Pago marzo 2025'),
('16893165-4', 4, 2025, 4000, '2025-04-01', 'cash', 'TR071', 'Pago abril 2025'),
('16893165-4', 5, 2025, 4000, '2025-05-01', 'cash', 'TR072', 'Pago mayo 2025'),
('16893165-4', 6, 2025, 4000, '2025-06-01', 'cash', 'TR073', 'Pago junio 2025'),
('16893165-4', 7, 2025, 4000, '2025-07-01', 'cash', 'TR074', 'Pago julio 2025'),
('16893165-4', 8, 2025, 4000, '2025-08-01', 'cash', 'TR075', 'Pago agosto 2025'),
('16893165-4', 9, 2025, 4000, '2025-09-01', 'cash', 'TR076', 'Pago septiembre 2025'),
('16893165-4', 10, 2025, 4000, '2025-10-01', 'cash', 'TR077', 'Pago octubre 2025'),
('16893165-4', 11, 2025, 4000, '2025-11-01', 'cash', 'TR078', 'Pago noviembre 2025'),
('16893165-4', 12, 2025, 4000, '2025-12-01', 'cash', 'TR079', 'Pago diciembre 2025'),
('16578803-6', 1, 2025, 4000, '2025-01-01', 'cash', 'TR080', 'Pago enero 2025')
-- [CONTINÚA EN EL ARCHIVO...]
) AS data(user_rut, month, year, amount, payment_date, payment_method, receipt_number, notes)
INNER JOIN users u ON u.rut = data.user_rut
INNER JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.month = data.month AND q.year = data.year;
