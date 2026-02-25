# Senior Data Engineer — Take-Home Assessment

## Overview
This assessment is designed to evaluate your ability to work with a realistic property management data model. You have been provided with a PostgreSQL 14 schema and seed data. Please read the data model notes carefully before writing any queries.

**Time Estimate:** ~30–45 minutes per part  
**Submission:** Return your `.sql` file(s) and `.py` file with clearly labeled sections for each part.

---

## Data Model Notes

The database represents a property management platform with the following entities and rules:

| Entity | Key Rules |
|---|---|
| **property** | A property can have multiple units and multiple owners |
| **unit** | A unit belongs to exactly one property |
| **owner** | An owner can own multiple properties (via `property_owner`) |
| **lease** | A unit can only have **one Active lease** at a time; past leases are retained with status `Expired` or `Terminated` |
| **tenant** | A tenant can only be on **one Active lease** at a time but may have past leases |
| **address** | A single `address` table is shared across all entities. The FK to the owning entity lives **on the address row** (one of `property_id`, `unit_id`, `owner_id`, or `tenant_id`), allowing each entity to have multiple addresses. Each address has an `address_type` (`Physical`, `Mailing`, `Billing`) and an `is_primary` flag. |

**Lease Statuses:** `Active`, `Expired`, `Terminated`  
**A unit is considered *occupied* when it has a lease with status = `Active`.**

---

## Part 1 — Property Directory Report

Write a single SQL query that produces a **property directory report**. The report must return one row per property and include the following columns:

| Column | Description |
|---|---|
| `property_id` | Unique identifier for the property |
| `property_name` | Name of the property |
| `property_type` | Type of property (e.g. Residential, Commercial) |
| `street_line_1` | Street address of the property |
| `city` | City |
| `state` | State |
| `zip_code` | ZIP code |
| `total_units` | Total number of units associated with the property |
| `occupied_units` | Number of units that currently have an Active lease |

**Requirements:**
- All properties must appear in the results, even if they have no units
- Results should be ordered alphabetically by `property_name`
- Do not use subqueries in the `FROM` clause — keep the query flat using `JOIN` and aggregation

---

## Part 2 — Data Model Expansion

Extend the existing schema to support two new requirements. Write all changes as valid SQL (`CREATE TABLE`, `ALTER TABLE`, etc.). Do **not** insert seed data — DDL only.

### 2a. Property Subtype

The `property` table currently has a `property_type` column that stores a broad class (e.g. `Residential`, `Commercial`). We now need to also track a more specific **subtype** for residential properties. Valid values are:

- `Single Family`
- `Condo`
- `Duplex`
- `Apartment`

Add this to the data model in whatever way you think is most appropriate. Be prepared to explain your approach and its tradeoffs.

> **Note:** Not every property will have a subtype (e.g. commercial properties), so the field must be nullable.

### 2b. Charges & Receipts

We need to track the financial activity on each lease. Add tables to support the following:

**Charges** — amounts billed to a lease (e.g. monthly rent, pet fee, late fee, security deposit).

**Receipts** — payments submitted by a tenant against a lease.

**Important relationship rule:** A charge can be partially or fully paid by one or more receipts, and a single receipt can be applied toward one or more charges. Your model must support this.

Things to consider and be prepared to discuss:
- How do you determine the outstanding balance on a charge?
- How do you handle a receipt that only partially covers a charge?
- How would you validate that the amounts applied across all charges for a receipt don't exceed the receipt's total?

---

## Part 3 — Python: Lease Balance Report

Write a Python function that queries the database using **pandas** and returns a JSON string containing the outstanding balance for every lease, along with the associated unit and property details.

### Function Signature

```python
def get_lease_balances(conn: psycopg2.extensions.connection) -> str:
```

You may assume a `psycopg2` connection is passed in — you do not need to handle connection setup, but your code should demonstrate awareness of proper resource cleanup.

Use `pandas` to load the query results and perform any necessary data type cleanup before building the final output.

### Output Requirements

The returned JSON should be an array of objects. Each object must include:

| Section | Fields |
|---|---|
| `lease` | `lease_id`, `status`, `start_date`, `end_date`, `monthly_rent` |
| `unit` | `unit_id`, `unit_number`, `bedrooms`, `bathrooms`, `sq_ft` |
| `property` | `property_id`, `property_name`, `property_type`, nested `address` (primary physical) |
| `balance` | `total_billed`, `total_paid`, `balance_due` |

### Requirements

- Use `pandas` (`pd.read_sql_query`) to load query results into a DataFrame
- The balance figures must be derived from the `charge` and `receipt_charge` tables you designed in Part 2
- Leases with no charges should appear in the results with all balance fields set to `0`
- Dates must be serialised as ISO 8601 strings (e.g. `"2025-03-01"`)
- Numeric/Decimal values from the database must be coerced to native Python floats
- The function should handle and log database errors gracefully without swallowing exceptions
- Results should be ordered by property name, then unit number, then lease start date

### Dependencies
- `pandas`, `psycopg2-binary`
