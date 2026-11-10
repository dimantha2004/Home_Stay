-- =====================================================================
-- SmartStay Hotel Booking System - MySQL 8 schema (3NF)
-- Student ID: 358842 | Module: CI6115
-- Run:  mysql -u root -p < database/schema.sql
-- Re-running this script DROPS and recreates the database.
-- =====================================================================

DROP DATABASE IF EXISTS smartstay;
CREATE DATABASE smartstay CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE smartstay;

-- ---------------------------------------------------------------------
-- Room packages (Table 1 of the brief). The daily rate is room-type
-- specific, so it lives here once instead of being repeated on every room.
-- base_capacity / max_occupancy are documented assumptions (configurable).
-- ---------------------------------------------------------------------
CREATE TABLE room_types (
    type_code               VARCHAR(20)   NOT NULL,
    display_name            VARCHAR(50)   NOT NULL,
    daily_rate              DECIMAL(10,2) NOT NULL,
    complimentary_breakfast BOOLEAN       NOT NULL,
    extra_guest_charge      DECIMAL(10,2) NOT NULL,   -- per extra guest, per night
    tax_rate                DECIMAL(5,4)  NOT NULL,   -- 0.1000 = 10%
    base_capacity           INT           NOT NULL,   -- guests included in the rate
    max_occupancy           INT           NOT NULL,   -- hard upper limit incl. extra guests
    CONSTRAINT pk_room_types PRIMARY KEY (type_code),
    CONSTRAINT uq_room_types_name UNIQUE (display_name),
    CONSTRAINT chk_rt_rate      CHECK (daily_rate > 0),
    CONSTRAINT chk_rt_extra     CHECK (extra_guest_charge >= 0),
    CONSTRAINT chk_rt_tax       CHECK (tax_rate >= 0 AND tax_rate < 1),
    CONSTRAINT chk_rt_capacity  CHECK (base_capacity > 0 AND max_occupancy >= base_capacity)
);

-- ---------------------------------------------------------------------
-- Physical rooms. status is the admin-managed operational state;
-- date clashes are prevented by the overlap check, not by this column.
-- is_active = FALSE means "removed" (soft delete keeps invoice history).
-- ---------------------------------------------------------------------
CREATE TABLE rooms (
    room_id    VARCHAR(10) NOT NULL,
    type_code  VARCHAR(20) NOT NULL,
    bed_type   ENUM('SINGLE','DOUBLE','QUEEN','KING')            NOT NULL,
    status     ENUM('AVAILABLE','RESERVED','UNDER_MAINTENANCE')  NOT NULL DEFAULT 'AVAILABLE',
    is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_rooms PRIMARY KEY (room_id),
    CONSTRAINT fk_rooms_type FOREIGN KEY (type_code) REFERENCES room_types (type_code)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_rooms_type_status (type_code, status)
);

-- ---------------------------------------------------------------------
-- Registered guests. NIC/Passport identifies a guest uniquely.
-- ---------------------------------------------------------------------
CREATE TABLE guests (
    guest_id       INT          NOT NULL AUTO_INCREMENT,
    nic_passport   VARCHAR(20)  NOT NULL,
    full_name      VARCHAR(100) NOT NULL,
    contact_number VARCHAR(20)  NOT NULL,
    email          VARCHAR(100) NOT NULL,
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_guests PRIMARY KEY (guest_id),
    CONSTRAINT uq_guests_nic UNIQUE (nic_passport),
    INDEX idx_guests_name (full_name)
);

-- ---------------------------------------------------------------------
-- Administrator accounts. Passwords are stored as salted PBKDF2 hashes.
-- ---------------------------------------------------------------------
CREATE TABLE administrators (
    admin_id      INT          NOT NULL AUTO_INCREMENT,
    username      VARCHAR(50)  NOT NULL,
    password_hash CHAR(64)     NOT NULL,   -- hex PBKDF2WithHmacSHA256, 256-bit
    salt          CHAR(32)     NOT NULL,   -- hex, 16 random bytes
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    CONSTRAINT pk_administrators PRIMARY KEY (admin_id),
    CONSTRAINT uq_administrators_username UNIQUE (username)
);

-- ---------------------------------------------------------------------
-- Reservations. Intervals are half-open [check_in, check_out), so a
-- check-out day may equal another booking's check-in day.
-- ---------------------------------------------------------------------
CREATE TABLE reservations (
    booking_id       INT           NOT NULL AUTO_INCREMENT,
    guest_id         INT           NOT NULL,
    room_id          VARCHAR(10)   NOT NULL,
    check_in         DATE          NOT NULL,
    check_out        DATE          NOT NULL,
    number_of_guests INT           NOT NULL,
    advance_paid     DECIMAL(10,2) NOT NULL,
    status           ENUM('CONFIRMED','CANCELLED') NOT NULL DEFAULT 'CONFIRMED',
    created_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reservations PRIMARY KEY (booking_id),
    CONSTRAINT fk_res_guest FOREIGN KEY (guest_id) REFERENCES guests (guest_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_res_room  FOREIGN KEY (room_id)  REFERENCES rooms (room_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_res_dates  CHECK (check_out > check_in),
    CONSTRAINT chk_res_guests CHECK (number_of_guests > 0),
    INDEX idx_res_room_dates (room_id, check_in, check_out),  -- overlap check
    INDEX idx_res_check_in (check_in)                          -- view by check-in date
) AUTO_INCREMENT = 1001;

-- ---------------------------------------------------------------------
-- Invoices. One per reservation (composition: deleted with it).
-- Amounts are snapshotted so later rate changes never rewrite old bills.
-- ---------------------------------------------------------------------
CREATE TABLE invoices (
    invoice_id         INT           NOT NULL AUTO_INCREMENT,
    booking_id         INT           NOT NULL,
    nights             INT           NOT NULL,
    daily_rate         DECIMAL(10,2) NOT NULL,
    extra_guests       INT           NOT NULL,
    base_charge        DECIMAL(12,2) NOT NULL,   -- step 1
    extra_guest_charge DECIMAL(12,2) NOT NULL,   -- step 2
    discount           DECIMAL(12,2) NOT NULL,   -- step 3
    tax_rate           DECIMAL(5,4)  NOT NULL,
    tax                DECIMAL(12,2) NOT NULL,   -- step 4
    advance            DECIMAL(10,2) NOT NULL,   -- step 5
    final_amount       DECIMAL(12,2) NOT NULL,   -- negative = refund due to guest
    generated_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_invoices PRIMARY KEY (invoice_id),
    CONSTRAINT uq_invoices_booking UNIQUE (booking_id),
    CONSTRAINT fk_inv_booking FOREIGN KEY (booking_id) REFERENCES reservations (booking_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);
