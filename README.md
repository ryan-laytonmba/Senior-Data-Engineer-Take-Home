# Senior Data Engineer — Take-Home Assessment

## Overview
This assessment is designed to evaluate your ability to work with a realistic property management data model. You have been provided with a PostgreSQL-compatible schema and seed data. Please read the data model notes carefully before writing any queries.

**Time Estimate:** ~30–45 minutes per part  
**Submission:** Return your `.sql` file(s) with clearly labeled sections for each part.

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
- All properties must appear in the results, even if they have no units.
- Results should be ordered alphabetically by `property_name`.
- Do not use subqueries in the `FROM` clause — keep the query flat using `JOIN` and aggregation.

---

*Additional parts to follow.*
