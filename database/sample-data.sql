-- =====================================================================
-- SmartStay sample data. Run AFTER schema.sql:
--   mysql -u root -p smartstay < database/sample-data.sql
-- Reservation dates are relative to CURDATE() so the demo data never
-- goes stale. Invoice amounts depend only on nights/guests/room type,
-- so they are fixed values (hand-checked against the 5-step bill).
-- Admin login: admin / Admin@123
-- =====================================================================
USE smartstay;

-- Table 1 of the brief + capacity assumptions (A1).
INSERT INTO room_types VALUES
('STANDARD',     'Standard',      6000.00, FALSE, 1000.00, 0.1000, 2, 4),
('DELUXE',       'Deluxe',        9000.00, TRUE,  1500.00, 0.1200, 2, 4),
('SUITE',        'Suite',        14000.00, TRUE,  2000.00, 0.1500, 3, 5),
('FAMILY_SUITE', 'Family Suite', 18000.00, TRUE,  2500.00, 0.1500, 4, 6);

INSERT INTO rooms (room_id, type_code, bed_type, status) VALUES
('101', 'STANDARD',     'SINGLE', 'AVAILABLE'),
('102', 'STANDARD',     'DOUBLE', 'AVAILABLE'),
('103', 'STANDARD',     'DOUBLE', 'AVAILABLE'),
('104', 'STANDARD',     'SINGLE', 'UNDER_MAINTENANCE'),
('201', 'DELUXE',       'QUEEN',  'AVAILABLE'),
('202', 'DELUXE',       'DOUBLE', 'AVAILABLE'),
('203', 'DELUXE',       'QUEEN',  'AVAILABLE'),
('204', 'DELUXE',       'KING',   'RESERVED'),
('301', 'SUITE',        'KING',   'AVAILABLE'),
('302', 'SUITE',        'QUEEN',  'AVAILABLE'),
('303', 'SUITE',        'KING',   'AVAILABLE'),
('401', 'FAMILY_SUITE', 'KING',   'AVAILABLE'),
('402', 'FAMILY_SUITE', 'KING',   'AVAILABLE'),
('403', 'FAMILY_SUITE', 'QUEEN',  'AVAILABLE');

INSERT INTO guests (nic_passport, full_name, contact_number, email) VALUES
('199012345678', 'Nimal Perera',    '0771234567',     'nimal.perera@example.com'),
('958765432V',   'Kavindi Silva',   '0712345678',     'kavindi.silva@example.com'),
('N1234567',     'James Wilson',    '+447700900123',  'james.wilson@example.co.uk'),
('200156789012', 'Fathima Rizwan',  '0759876543',     'fathima.rizwan@example.com'),
('E12345678',    'Chen Wei',        '+8613800138000', 'chen.wei@example.cn'),
('198834567890', 'Sajith Fernando', '0763456789',     'sajith.fernando@example.com'),
('Z9876543',     'Anjali Kumar',    '+919876543210',  'anjali.kumar@example.in');

INSERT INTO administrators (username, password_hash, salt, full_name, email) VALUES
('admin',
 '8519d141f4efdd801bb024c91b5d0001d8a5bd06841b2f2b8bfd40489456f7d2',
 '5c63d7cdee8224e2cd96e6d80a03c380',
 'System Administrator', 'admin@smartstay.lk');

-- Each row exercises a specific rule (see comment).
INSERT INTO reservations (guest_id, room_id, check_in, check_out, number_of_guests, advance_paid, status) VALUES
-- 1001 normal 2-night Standard stay
(1, '101', CURDATE() + INTERVAL 10 DAY, CURDATE() + INTERVAL 12 DAY, 2, 10000.00, 'CONFIRMED'),
-- 1002 worked example: Deluxe, 6 nights, 4 guests (2 extra) + long-stay discount
(2, '201', CURDATE() + INTERVAL 5 DAY,  CURDATE() + INTERVAL 11 DAY, 4, 10000.00, 'CONFIRMED'),
-- 1003 checks in today -> cancel/modify must be BLOCKED (24h rule) at any time of day
(3, '301', CURDATE(),                   CURDATE() + INTERVAL 2 DAY,  3, 10000.00, 'CONFIRMED'),
-- 1004 discount boundary: exactly 5 nights, Family Suite, 6 guests (2 extra)
(4, '401', CURDATE() + INTERVAL 14 DAY, CURDATE() + INTERVAL 19 DAY, 6, 10000.00, 'CONFIRMED'),
-- 1005 stay in progress (started 3 days ago), 4 nights -> no discount
(5, '102', CURDATE() - INTERVAL 3 DAY,  CURDATE() + INTERVAL 1 DAY,  1, 10000.00, 'CONFIRMED'),
-- 1006 cancelled reservation
(1, '202', CURDATE() + INTERVAL 20 DAY, CURDATE() + INTERVAL 24 DAY, 2, 10000.00, 'CANCELLED'),
-- 1007 back-to-back with 1001 (check-in = 1001's check-out) -> NOT an overlap
(6, '101', CURDATE() + INTERVAL 12 DAY, CURDATE() + INTERVAL 15 DAY, 2, 10000.00, 'CONFIRMED'),
-- 1008 advance exceeds bill -> refund due (assumption A4)
(7, '103', CURDATE() + INTERVAL 7 DAY,  CURDATE() + INTERVAL 8 DAY,  1, 10000.00, 'CONFIRMED');

-- booking, nights, rate, extraGuests, base, extra, discount, taxRate, tax, advance, final
INSERT INTO invoices (booking_id, nights, daily_rate, extra_guests, base_charge, extra_guest_charge,
                      discount, tax_rate, tax, advance, final_amount) VALUES
(1001, 2,  6000.00, 0, 12000.00,     0.00,     0.00, 0.1000,  1200.00, 10000.00,   3200.00),
(1002, 6,  9000.00, 2, 54000.00, 18000.00,  6480.00, 0.1200,  7862.40, 10000.00,  63382.40),
(1003, 2, 14000.00, 0, 28000.00,     0.00,     0.00, 0.1500,  4200.00, 10000.00,  22200.00),
(1004, 5, 18000.00, 2, 90000.00, 25000.00, 10800.00, 0.1500, 15630.00, 10000.00, 109830.00),
(1005, 4,  6000.00, 0, 24000.00,     0.00,     0.00, 0.1000,  2400.00, 10000.00,  16400.00),
(1006, 4,  9000.00, 0, 36000.00,     0.00,     0.00, 0.1200,  4320.00, 10000.00,  30320.00),
(1007, 3,  6000.00, 0, 18000.00,     0.00,     0.00, 0.1000,  1800.00, 10000.00,   9800.00),
(1008, 1,  6000.00, 0,  6000.00,     0.00,     0.00, 0.1000,   600.00, 10000.00,  -3400.00);
