# Blue Owls Azure Data Engineer Take-Home Assessment

## Overview

This project implements an end-to-end retail data pipeline using a medallion architecture: Bronze, Silver, and Gold. Data is ingested from the Blue Owls mock API, cleaned and standardized, and transformed into a star schema for analytics.

## Technical Decisions

### Ingestion and Resilience

I built the ingestion layer in Python notebooks with:

* Bearer token authentication
* Automatic token refresh on 401 responses
* Retry logic with backoff for 500 and 429 responses
* Pagination support across all required endpoints
* Metadata columns `_ingested_at` and `_source_endpoint`

The API is intentionally unstable, so resilience was prioritized.

### Bronze Layer

Bronze stores raw API responses as CSV files, one file per endpoint. This layer keeps the source data close to original form, with only ingestion metadata added.

### Silver Layer

Silver focuses on cleaning and standardization:

* Converted date fields to proper datetime types
* Checked and handled duplicates
* Applied date filter from 2018-07-01
* Derived delivery KPIs (`days_to_deliver`, `days_delivery_vs_estimate`, `is_late_delivery`)
* Filtered invalid rows

### Gold Layer

Gold implements the star schema:

* `fact_order_items`
* `dim_customers`
* `dim_products`
* `dim_sellers`

Deterministic surrogate keys are used to ensure reproducibility. Foreign key validation was performed to ensure data consistency.

### Payment Distribution Logic

Payments exist at order level but fact table is item level. Payment was distributed proportionally across items using item price.

## Assumptions

* Missing delivery dates → treated as not delivered
* CSV used instead of parquet for simplicity
* Focus on correctness over performance

## Production Improvements

* Azure Data Factory / Fabric pipelines
* Monitoring & alerting
* CI/CD
* Key Vault for secrets
* Incremental ingestion
* Partitioned storage

## SQL Queries

* Query 1: Monthly revenue trends, ranking, MoM growth, rolling average
* Query 2: Seller performance scoring

## Summary

This solution demonstrates a complete medallion architecture pipeline with resilient ingestion, clean transformations, and analytical modeling.
