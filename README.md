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

---

## Optional Extensions (Depth Differentiators)

You are not expected to complete every optional extension. We are more interested in depth and clarity than breadth. Focus on demonstrating how you think about data systems.

---

### Extension A: Data Quality & Validation

Working with the property management schema provided:

- Identify at least three data quality risks in the schema (e.g. orphaned records, missing constraints, duplicate risk)
- Write example validation queries that would surface those issues
- Suggest any additional constraints, indexes, or integrity enforcement strategies you would add and explain why

---

### Extension B: Performance & PostgreSQL 14 Optimization

The `charge` and `receipt` tables are expected to grow significantly as properties and leases accumulate over time. Assume `receipt` may reach 200M+ rows:

- Propose indexing strategies for the most common query patterns (e.g. balance lookups per lease, payment history per tenant)
- Discuss whether and how you would partition `charge` or `receipt` in PostgreSQL 14
- Address the OLTP vs OLAP tradeoff — at what point would you move balance reporting off the transactional database?
- Describe any query plan implications a reviewer should be aware of in the lease balance query from Part 3

---

### Extension C: GCP Production Architecture

Describe how you would productionize this data model and the lease balance report in Google Cloud:

- Would you replicate the PostgreSQL data to BigQuery? If so, what approach would you use (CDC, ELT, scheduled export)?
- ELT vs ETL — what is your preference for this use case and why?
- What orchestration tooling would you use and how would you structure the DAGs or pipelines?
- How would you handle backfills and reprocessing if a charge or receipt was retroactively corrected?
- What CI/CD strategy would you apply to schema migrations and pipeline changes?
- What cost considerations would influence your architecture decisions?

Focus on pragmatic, cloud-native thinking rather than buzzwords.

---

### Extension D: Observability & Reliability

- How would you monitor for pipeline or ingestion failures involving the `charge` and `receipt` tables?
- How would you detect silent data corruption — for example, a receipt where the total amount applied to charges exceeds the receipt's `total_amount`?
- How would you track and alert on data freshness SLAs — for example, ensuring the lease balance report reflects charges posted within the last 24 hours?

---

### Extension E: AI / ML Enablement (Bonus)

- How would you structure the property management data to support ML feature generation (e.g. predicting late payments or lease renewal likelihood)?
- Several entities in this schema — such as `property_subtype`, lease terms, and rent amounts — may change over time. How would you handle slowly changing dimensions?
- Would you implement snapshotting for lease or balance state? Why or why not, and at what granularity?

___

## Submission

Please submit your solution as a GitHub repository or a zipped folder containing:

- SQL files
- Python files
- Documentation (README required)
- Any diagrams
- Optional extension writeups

We are excited to see how you think about data systems and look forward to discussing your approach.
