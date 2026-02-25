-- ============================================================
--  SCHEMA
-- ============================================================

CREATE TABLE address (
    address_id      SERIAL PRIMARY KEY,
    street_line_1   VARCHAR(100) NOT NULL,
    street_line_2   VARCHAR(50),
    city            VARCHAR(50)  NOT NULL,
    state           CHAR(2)      NOT NULL,
    zip_code        VARCHAR(10)  NOT NULL
);

CREATE TABLE owner (
    owner_id    SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20),
    address_id  INT REFERENCES address(address_id)   -- owner's mailing address
);

CREATE TABLE property (
    property_id     SERIAL PRIMARY KEY,
    property_name   VARCHAR(100) NOT NULL,
    property_type   VARCHAR(50),   -- e.g. 'Residential', 'Commercial', 'Mixed-Use'
    address_id      INT REFERENCES address(address_id)
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
    sq_ft           INT,
    address_id      INT REFERENCES address(address_id)  -- unit-level address (e.g. apt #)
);

CREATE TABLE tenant (
    tenant_id   SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20),
    address_id  INT REFERENCES address(address_id)   -- tenant's non-unit mailing address
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

-- Addresses
INSERT INTO address (address_id, street_line_1, street_line_2, city, state, zip_code) VALUES
-- Property addresses
(1,  '100 Maple Street',       NULL,       'Austin',       'TX', '78701'),
(2,  '250 Oak Avenue',         NULL,       'Austin',       'TX', '78702'),
(3,  '789 Pine Boulevard',     NULL,       'Austin',       'TX', '78703'),
-- Unit-level addresses (same building, different apt numbers)
(4,  '100 Maple Street',       'Apt 101',  'Austin',       'TX', '78701'),
(5,  '100 Maple Street',       'Apt 102',  'Austin',       'TX', '78701'),
(6,  '100 Maple Street',       'Apt 201',  'Austin',       'TX', '78701'),
(7,  '250 Oak Avenue',         'Unit A',   'Austin',       'TX', '78702'),
(8,  '250 Oak Avenue',         'Unit B',   'Austin',       'TX', '78702'),
(9,  '789 Pine Boulevard',     'Suite 1',  'Austin',       'TX', '78703'),
(10, '789 Pine Boulevard',     'Suite 2',  'Austin',       'TX', '78703'),
(11, '789 Pine Boulevard',     'Suite 3',  'Austin',       'TX', '78703'),
-- Owner mailing addresses
(12, '400 Investor Lane',      NULL,       'Dallas',       'TX', '75201'),
(13, '55 Capital Drive',       NULL,       'Houston',      'TX', '77001'),
(14, '900 Equity Road',        NULL,       'San Antonio',  'TX', '78201'),
-- Tenant mailing addresses (prior/forwarding)
(15, '12 Old Apartment Ct',    NULL,       'Austin',       'TX', '78704'),
(16, '88 College Blvd',        NULL,       'Austin',       'TX', '78705');


-- Owners
INSERT INTO owner (owner_id, first_name, last_name, email, phone, address_id) VALUES
(1, 'Robert',  'Harmon',   'robert.harmon@email.com',  '512-555-0101', 12),
(2, 'Sandra',  'Patel',    'sandra.patel@email.com',   '214-555-0202', 13),
(3, 'Marcus',  'Liu',      'marcus.liu@email.com',     '210-555-0303', 14);


-- Properties
INSERT INTO property (property_id, property_name, property_type, address_id) VALUES
(1, 'Maple Street Residences',  'Residential',  1),
(2, 'Oak Avenue Flats',         'Residential',  2),
(3, 'Pine Business Center',     'Commercial',   3);


-- Property <-> Owner relationships
INSERT INTO property_owner (property_id, owner_id, ownership_pct) VALUES
(1, 1, 60.00),   -- Robert owns 60% of Maple
(1, 2, 40.00),   -- Sandra owns 40% of Maple
(2, 2, 100.00),  -- Sandra solely owns Oak
(3, 1, 50.00),   -- Robert owns 50% of Pine
(3, 3, 50.00);   -- Marcus owns 50% of Pine


-- Units
INSERT INTO unit (unit_id, property_id, unit_number, bedrooms, bathrooms, sq_ft, address_id) VALUES
-- Maple Street (3 units)
(1, 1, '101', 1, 1.0,  650,  4),
(2, 1, '102', 2, 1.0,  850,  5),
(3, 1, '201', 3, 2.0, 1100,  6),
-- Oak Avenue (2 units)
(4, 2, 'A',   1, 1.0,  700,  7),
(5, 2, 'B',   2, 2.0,  950,  8),
-- Pine Business Center (3 suites)
(6, 3, 'Suite 1', NULL, NULL, 1200, 9),
(7, 3, 'Suite 2', NULL, NULL,  800, 10),
(8, 3, 'Suite 3', NULL, NULL,  600, 11);


-- Tenants
INSERT INTO tenant (tenant_id, first_name, last_name, email, phone, address_id) VALUES
(1, 'Alice',   'Monroe',   'alice.monroe@email.com',   '512-555-1001', NULL),
(2, 'Brian',   'Cho',      'brian.cho@email.com',      '512-555-1002', NULL),
(3, 'Carmen',  'Reyes',    'carmen.reyes@email.com',   '512-555-1003', 15),  -- has a forwarding address
(4, 'David',   'Kim',      'david.kim@email.com',      '512-555-1004', NULL),
(5, 'Elena',   'Vasquez',  'elena.vasquez@email.com',  '512-555-1005', NULL),
(6, 'Frank',   'Nguyen',   'frank.nguyen@email.com',   '512-555-1006', 16),  -- has a forwarding address
(7, 'Grace',   'Okafor',   'grace.okafor@email.com',   '512-555-1007', NULL),
(8, 'Hector',  'Burns',    'hector.burns@email.com',   '512-555-1008', NULL);


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
