-- ============================================================
--  SCHEMA
-- ============================================================

CREATE TABLE address (
    address_id      SERIAL PRIMARY KEY,
    street_line_1   VARCHAR(100) NOT NULL,
    street_line_2   VARCHAR(50),
    city            VARCHAR(50)  NOT NULL,
    state           CHAR(2)      NOT NULL,
    zip_code        VARCHAR(10)  NOT NULL,

    -- Polymorphic FK: exactly one of these should be non-null
    property_id     INT REFERENCES property(property_id),
    unit_id         INT REFERENCES unit(unit_id),
    owner_id        INT REFERENCES owner(owner_id),
    tenant_id       INT REFERENCES tenant(tenant_id),

    address_type    VARCHAR(30) NOT NULL,  -- e.g. 'Physical', 'Mailing', 'Billing'
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE owner (
    owner_id    SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20)
);

CREATE TABLE property (
    property_id     SERIAL PRIMARY KEY,
    property_name   VARCHAR(100) NOT NULL,
    property_type   VARCHAR(50)  -- e.g. 'Residential', 'Commercial', 'Mixed-Use'
);

-- Many-to-many: an owner can own many properties, a property can have many owners
CREATE TABLE property_owner (
    property_id     INT REFERENCES property(property_id),
    owner_id        INT REFERENCES owner(owner_id),
    ownership_pct   NUMERIC(5,2),   -- e.g. 50.00 = 50%
    PRIMARY KEY (property_id, owner_id)
);

CREATE TABLE unit (
    unit_id         SERIAL PRIMARY KEY,
    property_id     INT NOT NULL REFERENCES property(property_id),
    unit_number     VARCHAR(20)  NOT NULL,
    bedrooms        SMALLINT,
    bathrooms       NUMERIC(3,1),
    sq_ft           INT
);

CREATE TABLE tenant (
    tenant_id   SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20)
);

CREATE TABLE lease (
    lease_id        SERIAL PRIMARY KEY,
    unit_id         INT NOT NULL REFERENCES unit(unit_id),
    start_date      DATE NOT NULL,
    end_date        DATE,
    monthly_rent    NUMERIC(10,2),
    status          VARCHAR(20) NOT NULL  -- 'Active', 'Expired', 'Terminated'
);

-- A tenant can appear on multiple leases (past + present); one active lease at a time
CREATE TABLE lease_tenant (
    lease_id    INT REFERENCES lease(lease_id),
    tenant_id   INT REFERENCES tenant(tenant_id),
    is_primary  BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (lease_id, tenant_id)
);


-- ============================================================
--  SEED DATA
-- ============================================================

-- Owners (no address_id column anymore)
INSERT INTO owner (owner_id, first_name, last_name, email, phone) VALUES
(1, 'Robert',  'Harmon',   'robert.harmon@email.com',  '512-555-0101'),
(2, 'Sandra',  'Patel',    'sandra.patel@email.com',   '214-555-0202'),
(3, 'Marcus',  'Liu',      'marcus.liu@email.com',     '210-555-0303');


-- Properties (no address_id column anymore)
INSERT INTO property (property_id, property_name, property_type) VALUES
(1, 'Maple Street Residences',  'Residential'),
(2, 'Oak Avenue Flats',         'Residential'),
(3, 'Pine Business Center',     'Commercial');


-- Property <-> Owner relationships
INSERT INTO property_owner (property_id, owner_id, ownership_pct) VALUES
(1, 1, 60.00),   -- Robert owns 60% of Maple
(1, 2, 40.00),   -- Sandra owns 40% of Maple
(2, 2, 100.00),  -- Sandra solely owns Oak
(3, 1, 50.00),   -- Robert owns 50% of Pine
(3, 3, 50.00);   -- Marcus owns 50% of Pine


-- Units (no address_id column anymore)
INSERT INTO unit (unit_id, property_id, unit_number, bedrooms, bathrooms, sq_ft) VALUES
-- Maple Street (3 units)
(1, 1, '101', 1, 1.0,  650),
(2, 1, '102', 2, 1.0,  850),
(3, 1, '201', 3, 2.0, 1100),
-- Oak Avenue (2 units)
(4, 2, 'A',   1, 1.0,  700),
(5, 2, 'B',   2, 2.0,  950),
-- Pine Business Center (3 suites)
(6, 3, 'Suite 1', NULL, NULL, 1200),
(7, 3, 'Suite 2', NULL, NULL,  800),
(8, 3, 'Suite 3', NULL, NULL,  600);


-- Tenants (no address_id column anymore)
INSERT INTO tenant (tenant_id, first_name, last_name, email, phone) VALUES
(1, 'Alice',   'Monroe',   'alice.monroe@email.com',   '512-555-1001'),
(2, 'Brian',   'Cho',      'brian.cho@email.com',      '512-555-1002'),
(3, 'Carmen',  'Reyes',    'carmen.reyes@email.com',   '512-555-1003'),
(4, 'David',   'Kim',      'david.kim@email.com',      '512-555-1004'),
(5, 'Elena',   'Vasquez',  'elena.vasquez@email.com',  '512-555-1005'),
(6, 'Frank',   'Nguyen',   'frank.nguyen@email.com',   '512-555-1006'),
(7, 'Grace',   'Okafor',   'grace.okafor@email.com',   '512-555-1007'),
(8, 'Hector',  'Burns',    'hector.burns@email.com',   '512-555-1008');


-- ============================================================
--  ADDRESSES  (FK lives here; one row per address per entity)
-- ============================================================
--  address_type values used:
--    'Physical'  – where the property/unit actually is
--    'Mailing'   – owner/tenant preferred mailing address
--    'Billing'   – alternate billing address
-- ============================================================

INSERT INTO address (address_id, street_line_1, street_line_2, city, state, zip_code,
                     property_id, unit_id, owner_id, tenant_id, address_type, is_primary)
VALUES
-- ── Property physical addresses ──────────────────────────────
(1,  '100 Maple Street',    NULL,        'Austin',      'TX', '78701',  1, NULL, NULL, NULL, 'Physical', TRUE),
(2,  '250 Oak Avenue',      NULL,        'Austin',      'TX', '78702',  2, NULL, NULL, NULL, 'Physical', TRUE),
(3,  '789 Pine Boulevard',  NULL,        'Austin',      'TX', '78703',  3, NULL, NULL, NULL, 'Physical', TRUE),

-- ── Unit physical addresses ───────────────────────────────────
(4,  '100 Maple Street',    'Apt 101',   'Austin',      'TX', '78701',  NULL, 1, NULL, NULL, 'Physical', TRUE),
(5,  '100 Maple Street',    'Apt 102',   'Austin',      'TX', '78701',  NULL, 2, NULL, NULL, 'Physical', TRUE),
(6,  '100 Maple Street',    'Apt 201',   'Austin',      'TX', '78701',  NULL, 3, NULL, NULL, 'Physical', TRUE),
(7,  '250 Oak Avenue',      'Unit A',    'Austin',      'TX', '78702',  NULL, 4, NULL, NULL, 'Physical', TRUE),
(8,  '250 Oak Avenue',      'Unit B',    'Austin',      'TX', '78702',  NULL, 5, NULL, NULL, 'Physical', TRUE),
(9,  '789 Pine Boulevard',  'Suite 1',   'Austin',      'TX', '78703',  NULL, 6, NULL, NULL, 'Physical', TRUE),
(10, '789 Pine Boulevard',  'Suite 2',   'Austin',      'TX', '78703',  NULL, 7, NULL, NULL, 'Physical', TRUE),
(11, '789 Pine Boulevard',  'Suite 3',   'Austin',      'TX', '78703',  NULL, 8, NULL, NULL, 'Physical', TRUE),

-- ── Owner mailing addresses (primary) ────────────────────────
(12, '400 Investor Lane',   NULL,        'Dallas',      'TX', '75201',  NULL, NULL, 1, NULL, 'Mailing', TRUE),
(13, '55 Capital Drive',    NULL,        'Houston',     'TX', '77001',  NULL, NULL, 2, NULL, 'Mailing', TRUE),
(14, '900 Equity Road',     NULL,        'San Antonio', 'TX', '78201',  NULL, NULL, 3, NULL, 'Mailing', TRUE),

-- ── Owner billing addresses (secondary — demonstrates multi-address) ──
(15, '1 Finance Plaza',     'Ste 300',   'Dallas',      'TX', '75202',  NULL, NULL, 1, NULL, 'Billing', FALSE),
(16, '200 Commerce Street', NULL,        'Houston',     'TX', '77002',  NULL, NULL, 2, NULL, 'Billing', FALSE),

-- ── Tenant mailing addresses ──────────────────────────────────
-- Carmen: primary mailing (forwarding from old place)
(17, '12 Old Apartment Ct', NULL,        'Austin',      'TX', '78704',  NULL, NULL, NULL, 3, 'Mailing', TRUE),
-- Frank: primary mailing
(18, '88 College Blvd',     NULL,        'Austin',      'TX', '78705',  NULL, NULL, NULL, 6, 'Mailing', TRUE),
-- David: two mailing addresses (moved; kept both) — demonstrates multi-address for tenants
(19, '300 First Street',    'Apt 4B',    'Austin',      'TX', '78701',  NULL, NULL, NULL, 4, 'Mailing', FALSE),
(20, '77 New Start Ave',    NULL,        'Austin',      'TX', '78703',  NULL, NULL, NULL, 4, 'Mailing', TRUE);



-- Leases
INSERT INTO lease (lease_id, unit_id, start_date, end_date, monthly_rent, status) VALUES
-- Active leases (occupied units: 1, 2, 4, 6, 7)
(1,  1, '2024-03-01', '2025-02-28', 1200.00, 'Expired'),   -- Alice's old lease on unit 1
(2,  1, '2025-03-01', '2026-02-28', 1300.00, 'Active'),    -- Alice's current lease on unit 1
(3,  2, '2024-06-01', '2025-05-31', 1500.00, 'Active'),    -- Brian & Carmen on unit 2
(4,  3, '2023-01-01', '2023-12-31',  950.00, 'Expired'),   -- David's old lease on unit 3 (now vacant)
(5,  4, '2025-01-01', '2026-01-01', 1250.00, 'Active'),    -- Elena on unit 4
(6,  5, '2024-09-01', '2025-08-31', 1600.00, 'Expired'),   -- Frank's old lease on unit 5 (now vacant)
(7,  6, '2025-02-01', '2026-01-31', 2200.00, 'Active'),    -- Grace on suite 6
(8,  7, '2025-04-01', '2026-03-31', 1800.00, 'Active'),    -- Hector on suite 7
(9,  8, '2024-01-01', '2024-12-31', 1400.00, 'Expired');   -- Suite 8 was occupied, now vacant


-- Lease <-> Tenant
INSERT INTO lease_tenant (lease_id, tenant_id, is_primary) VALUES
(1, 1, TRUE),   -- Alice on expired unit-1 lease
(2, 1, TRUE),   -- Alice on active unit-1 lease
(3, 2, TRUE),   -- Brian (primary) on unit-2 lease
(3, 3, FALSE),  -- Carmen (co-tenant) on unit-2 lease
(4, 4, TRUE),   -- David on expired unit-3 lease
(5, 5, TRUE),   -- Elena on unit-4 lease
(6, 6, TRUE),   -- Frank on expired unit-5 lease
(7, 7, TRUE),   -- Grace on suite-6 lease
(8, 8, TRUE),   -- Hector on suite-7 lease
(9, 4, TRUE);   -- David also appeared on suite-8 expired lease
