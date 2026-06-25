-- ============================================================
-- Customer Churn Intelligence Platform
-- Star Schema DDL — Telco Customer Churn Data Warehouse
-- Author : Your Name
-- Dataset : IBM Telco Customer Churn (7,043 customers)
-- ============================================================

-- ─────────────────────────────────────────────
-- DROP (safe re-run order)
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS fact_customer_churn;
DROP TABLE IF EXISTS dim_contract;
DROP TABLE IF EXISTS dim_payment;
DROP TABLE IF EXISTS dim_internet_service;
DROP TABLE IF EXISTS dim_phone_service;
DROP TABLE IF EXISTS dim_demographics;
DROP TABLE IF EXISTS dim_date;

-- ─────────────────────────────────────────────
-- DIMENSION: Demographics
-- ─────────────────────────────────────────────
CREATE TABLE dim_demographics (
    demographics_key  SERIAL PRIMARY KEY,
    gender            VARCHAR(10)  NOT NULL,
    senior_citizen    SMALLINT     NOT NULL CHECK (senior_citizen IN (0, 1)),
    has_partner       VARCHAR(3)   NOT NULL,
    has_dependents    VARCHAR(3)   NOT NULL
);

-- ─────────────────────────────────────────────
-- DIMENSION: Contract
-- ─────────────────────────────────────────────
CREATE TABLE dim_contract (
    contract_key      SERIAL PRIMARY KEY,
    contract_type     VARCHAR(30)  NOT NULL,   -- Month-to-month | One year | Two year
    paperless_billing VARCHAR(3)   NOT NULL,
    contract_risk     VARCHAR(10)  NOT NULL    -- High | Medium | Low (derived)
);

-- ─────────────────────────────────────────────
-- DIMENSION: Payment Method
-- ─────────────────────────────────────────────
CREATE TABLE dim_payment (
    payment_key       SERIAL PRIMARY KEY,
    payment_method    VARCHAR(50)  NOT NULL,
    is_auto_pay       BOOLEAN      NOT NULL    -- TRUE for automatic methods
);

-- ─────────────────────────────────────────────
-- DIMENSION: Internet Service
-- ─────────────────────────────────────────────
CREATE TABLE dim_internet_service (
    internet_key          SERIAL PRIMARY KEY,
    internet_service      VARCHAR(20)  NOT NULL,  -- DSL | Fiber optic | No
    online_security       VARCHAR(20),
    online_backup         VARCHAR(20),
    device_protection     VARCHAR(20),
    tech_support          VARCHAR(20),
    streaming_tv          VARCHAR(20),
    streaming_movies      VARCHAR(20)
);

-- ─────────────────────────────────────────────
-- DIMENSION: Phone Service
-- ─────────────────────────────────────────────
CREATE TABLE dim_phone_service (
    phone_key         SERIAL PRIMARY KEY,
    phone_service     VARCHAR(3)   NOT NULL,
    multiple_lines    VARCHAR(20)
);

-- ─────────────────────────────────────────────
-- DIMENSION: Date (for tenure bucketing)
-- ─────────────────────────────────────────────
CREATE TABLE dim_date (
    date_key          INT          PRIMARY KEY,  -- YYYYMM surrogate
    tenure_months     INT          NOT NULL,
    tenure_band       VARCHAR(20)  NOT NULL,     -- 0-12 | 13-24 | 25-48 | 49-72
    tenure_year       INT          NOT NULL
);

-- ─────────────────────────────────────────────
-- FACT: Customer Churn
-- ─────────────────────────────────────────────
CREATE TABLE fact_customer_churn (
    customer_id        VARCHAR(20)   PRIMARY KEY,
    demographics_key   INT           NOT NULL REFERENCES dim_demographics(demographics_key),
    contract_key       INT           NOT NULL REFERENCES dim_contract(contract_key),
    payment_key        INT           NOT NULL REFERENCES dim_payment(payment_key),
    internet_key       INT           NOT NULL REFERENCES dim_internet_service(internet_key),
    phone_key          INT           NOT NULL REFERENCES dim_phone_service(phone_key),
    date_key           INT           NOT NULL REFERENCES dim_date(date_key),

    -- Measures
    tenure_months      INT           NOT NULL,
    monthly_charges    NUMERIC(8,2)  NOT NULL,
    total_charges      NUMERIC(10,2),
    churn_flag         SMALLINT      NOT NULL CHECK (churn_flag IN (0, 1)),

    -- Derived / enriched columns
    annual_revenue     NUMERIC(10,2) GENERATED ALWAYS AS (monthly_charges * 12) STORED,
    revenue_segment    VARCHAR(10),   -- Low | Medium | High | Premium
    clv_score          NUMERIC(10,2)  -- Customer Lifetime Value proxy
);

-- ─────────────────────────────────────────────
-- INDEXES for dashboard query performance
-- ─────────────────────────────────────────────
CREATE INDEX idx_fact_churn_flag       ON fact_customer_churn(churn_flag);
CREATE INDEX idx_fact_contract_key     ON fact_customer_churn(contract_key);
CREATE INDEX idx_fact_payment_key      ON fact_customer_churn(payment_key);
CREATE INDEX idx_fact_internet_key     ON fact_customer_churn(internet_key);
CREATE INDEX idx_fact_date_key         ON fact_customer_churn(date_key);
CREATE INDEX idx_fact_revenue_segment  ON fact_customer_churn(revenue_segment);
