-- ============================================================
--  SCHEMA — PostgreSQL 14
-- ============================================================

CREATE TABLE owner (
    owner_id    integer      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  varchar(50)  NOT NULL,
    last_name   varchar(50)  NOT NULL,
    email       varchar(100),
    phone       varchar(20)
);

CREATE TABLE property (
    property_id     integer      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    property_name   varchar(100) NOT NULL,
    property_type   varchar(50)                -- e.g. 'Residential', 'Commercial', 'Mixed-Use'
);

CREATE TABLE property_owner (
    property_id     integer        NOT NULL REFERENCES property(property_id),
    owner_id        integer        NOT NULL REFERENCES owner(owner_id),
    ownership_pct   numeric(5,2),
    PRIMARY KEY (property_id, owner_id)
);

CREATE TABLE unit (
    unit_id         integer      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    property_id     integer      NOT NULL REFERENCES property(property_id),
    unit_number     varchar(20)  NOT NULL,
    bedrooms        smallint,
    bathrooms       numeric(3,1),
    sq_ft           integer
);

CREATE TABLE tenant (
    tenant_id   integer      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  varchar(50)  NOT NULL,
    last_name   varchar(50)  NOT NULL,
    email       varchar(100),
    phone       varchar(20)
);

CREATE TABLE lease (
    lease_id        integer        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    unit_id         integer        NOT NULL REFERENCES unit(unit_id),
    start_date      date           NOT NULL,
    end_date        date,
    monthly_rent    numeric(10,2),
    status          varchar(20)    NOT NULL,   -- 'Active', 'Expired', 'Terminated'
    CONSTRAINT chk_lease_status CHECK (status IN ('Active', 'Expired', 'Terminated'))
);

CREATE TABLE lease_tenant (
    lease_id    integer  NOT NULL REFERENCES lease(lease_id),
    tenant_id   integer  NOT NULL REFERENCES tenant(tenant_id),
    is_primary  boolean  NOT NULL DEFAULT FALSE,
    PRIMARY KEY (lease_id, tenant_id)
);

-- address references the owning entity via FK on this table.
-- Exactly one of the four FK columns should be non-null.
CREATE TABLE address (
    address_id      integer      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    street_line_1   varchar(100) NOT NULL,
    street_line_2   varchar(50),
    city            varchar(50)  NOT NULL,
    state           char(2)      NOT NULL,
    zip_code        varchar(10)  NOT NULL,

    -- Polymorphic FK: exactly one should be non-null
    property_id     integer  REFERENCES property(property_id),
    unit_id         integer  REFERENCES unit(unit_id),
    owner_id        integer  REFERENCES owner(owner_id),
    tenant_id       integer  REFERENCES tenant(tenant_id),

    address_type    varchar(30)  NOT NULL,     -- 'Physical', 'Mailing', 'Billing'
    is_primary      boolean      NOT NULL DEFAULT FALSE,

    CONSTRAINT chk_address_single_owner CHECK (
        (
            (property_id IS NOT NULL)::integer +
            (unit_id     IS NOT NULL)::integer +
            (owner_id    IS NOT NULL)::integer +
            (tenant_id   IS NOT NULL)::integer
        ) = 1
    )
);


-- ============================================================
--  SEED DATA
-- ============================================================

-- Owners
INSERT INTO owner (owner_id, first_name, last_name, email, phone)
OVERRIDING SYSTEM VALUE VALUES
(1, 'Robert', 'Harmon',  'robert.harmon@email.com', '512-555-0101'),
(2, 'Sandra', 'Patel',   'sandra.patel@email.com',  '214-555-0202'),
(3, 'Marcus', 'Liu',     'marcus.liu@email.com',    '210-555-0303');

SELECT setval(pg_get_serial_sequence('owner', 'owner_id'), 3);


-- Properties
INSERT INTO property (property_id, property_name, property_type)
OVERRIDING SYSTEM VALUE VALUES
(1, 'Maple Street Residences', 'Residential'),
(2, 'Oak Avenue Flats',        'Residential'),
(3, 'Pine Business Center',    'Commercial');

SELECT setval(pg_get_serial_sequence('property', 'property_id'), 3);


-- Property <-> Owner
INSERT INTO property_owner (property_id, owner_id, ownership_pct) VALUES
(1, 1, 60.00),
(1, 2, 40.00),
(2, 2, 100.00),
(3, 1, 50.00),
(3, 3, 50.00);


-- Units
INSERT INTO unit (unit_id, property_id, unit_number, bedrooms, bathrooms, sq_ft)
OVERRIDING SYSTEM VALUE VALUES
(1, 1, '101',     1, 1.0,  650),
(2, 1, '102',     2, 1.0,  850),
(3, 1, '201',     3, 2.0, 1100),
(4, 2, 'A',       1, 1.0,  700),
(5, 2, 'B',       2, 2.0,  950),
(6, 3, 'Suite 1', NULL, NULL, 1200),
(7, 3, 'Suite 2', NULL, NULL,  800),
(8, 3, 'Suite 3', NULL, NULL,  600);

SELECT setval(pg_get_serial_sequence('unit', 'unit_id'), 8);


-- Tenants
INSERT INTO tenant (tenant_id, first_name, last_name, email, phone)
OVERRIDING SYSTEM VALUE VALUES
(1, 'Alice',  'Monroe',  'alice.monroe@email.com',  '512-555-1001'),
(2, 'Brian',  'Cho',     'brian.cho@email.com',     '512-555-1002'),
(3, 'Carmen', 'Reyes',   'carmen.reyes@email.com',  '512-555-1003'),
(4, 'David',  'Kim',     'david.kim@email.com',     '512-555-1004'),
(5, 'Elena',  'Vasquez', 'elena.vasquez@email.com', '512-555-1005'),
(6, 'Frank',  'Nguyen',  'frank.nguyen@email.com',  '512-555-1006'),
(7, 'Grace',  'Okafor',  'grace.okafor@email.com',  '512-555-1007'),
(8, 'Hector', 'Burns',   'hector.burns@email.com',  '512-555-1008');

SELECT setval(pg_get_serial_sequence('tenant', 'tenant_id'), 8);


-- Leases
INSERT INTO lease (lease_id, unit_id, start_date, end_date, monthly_rent, status)
OVERRIDING SYSTEM VALUE VALUES
(1, 1, '2024-03-01', '2025-02-28', 1200.00, 'Expired'),
(2, 1, '2025-03-01', '2026-02-28', 1300.00, 'Active'),
(3, 2, '2024-06-01', '2025-05-31', 1500.00, 'Active'),
(4, 3, '2023-01-01', '2023-12-31',  950.00, 'Expired'),
(5, 4, '2025-01-01', '2026-01-01', 1250.00, 'Active'),
(6, 5, '2024-09-01', '2025-08-31', 1600.00, 'Expired'),
(7, 6, '2025-02-01', '2026-01-31', 2200.00, 'Active'),
(8, 7, '2025-04-01', '2026-03-31', 1800.00, 'Active'),
(9, 8, '2024-01-01', '2024-12-31', 1400.00, 'Expired');

SELECT setval(pg_get_serial_sequence('lease', 'lease_id'), 9);


-- Lease <-> Tenant
INSERT INTO lease_tenant (lease_id, tenant_id, is_primary) VALUES
(1, 1, TRUE),
(2, 1, TRUE),
(3, 2, TRUE),
(3, 3, FALSE),
(4, 4, TRUE),
(5, 5, TRUE),
(6, 6, TRUE),
(7, 7, TRUE),
(8, 8, TRUE),
(9, 4, TRUE);


-- Addresses
INSERT INTO address (address_id, street_line_1, street_line_2, city, state, zip_code,
                     property_id, unit_id, owner_id, tenant_id, address_type, is_primary)
OVERRIDING SYSTEM VALUE VALUES
-- Property physical addresses
(1,  '100 Maple Street',    NULL,       'Austin',      'TX', '78701', 1, NULL, NULL, NULL, 'Physical', TRUE),
(2,  '250 Oak Avenue',      NULL,       'Austin',      'TX', '78702', 2, NULL, NULL, NULL, 'Physical', TRUE),
(3,  '789 Pine Boulevard',  NULL,       'Austin',      'TX', '78703', 3, NULL, NULL, NULL, 'Physical', TRUE),
-- Unit physical addresses
(4,  '100 Maple Street',    'Apt 101',  'Austin',      'TX', '78701', NULL, 1, NULL, NULL, 'Physical', TRUE),
(5,  '100 Maple Street',    'Apt 102',  'Austin',      'TX', '78701', NULL, 2, NULL, NULL, 'Physical', TRUE),
(6,  '100 Maple Street',    'Apt 201',  'Austin',      'TX', '78701', NULL, 3, NULL, NULL, 'Physical', TRUE),
(7,  '250 Oak Avenue',      'Unit A',   'Austin',      'TX', '78702', NULL, 4, NULL, NULL, 'Physical', TRUE),
(8,  '250 Oak Avenue',      'Unit B',   'Austin',      'TX', '78702', NULL, 5, NULL, NULL, 'Physical', TRUE),
(9,  '789 Pine Boulevard',  'Suite 1',  'Austin',      'TX', '78703', NULL, 6, NULL, NULL, 'Physical', TRUE),
(10, '789 Pine Boulevard',  'Suite 2',  'Austin',      'TX', '78703', NULL, 7, NULL, NULL, 'Physical', TRUE),
(11, '789 Pine Boulevard',  'Suite 3',  'Austin',      'TX', '78703', NULL, 8, NULL, NULL, 'Physical', TRUE),
-- Owner primary mailing addresses
(12, '400 Investor Lane',   NULL,       'Dallas',      'TX', '75201', NULL, NULL, 1, NULL, 'Mailing', TRUE),
(13, '55 Capital Drive',    NULL,       'Houston',     'TX', '77001', NULL, NULL, 2, NULL, 'Mailing', TRUE),
(14, '900 Equity Road',     NULL,       'San Antonio', 'TX', '78201', NULL, NULL, 3, NULL, 'Mailing', TRUE),
-- Owner secondary billing addresses
(15, '1 Finance Plaza',     'Ste 300',  'Dallas',      'TX', '75202', NULL, NULL, 1, NULL, 'Billing', FALSE),
(16, '200 Commerce Street', NULL,       'Houston',     'TX', '77002', NULL, NULL, 2, NULL, 'Billing', FALSE),
-- Tenant mailing addresses
(17, '12 Old Apartment Ct', NULL,       'Austin',      'TX', '78704', NULL, NULL, NULL, 3, 'Mailing', TRUE),
(18, '88 College Blvd',     NULL,       'Austin',      'TX', '78705', NULL, NULL, NULL, 6, 'Mailing', TRUE),
(19, '300 First Street',    'Apt 4B',   'Austin',      'TX', '78701', NULL, NULL, NULL, 4, 'Mailing', FALSE),
(20, '77 New Start Ave',    NULL,       'Austin',      'TX', '78703', NULL, NULL, NULL, 4, 'Mailing', TRUE);

SELECT setval(pg_get_serial_sequence('address', 'address_id'), 20);
