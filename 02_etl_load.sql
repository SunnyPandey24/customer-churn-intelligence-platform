-- ============================================================
-- Customer Churn Intelligence Platform
-- ETL: Load Raw CSV → Star Schema
-- Run AFTER 01_star_schema_ddl.sql
-- ============================================================

-- ─────────────────────────────────────────────
-- STEP 1: Staging table (raw CSV import)
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS stg_customer_churn;

CREATE TABLE stg_customer_churn (
    customerID         VARCHAR(20),
    gender             VARCHAR(10),
    SeniorCitizen      SMALLINT,
    Partner            VARCHAR(3),
    Dependents         VARCHAR(3),
    tenure             INT,
    PhoneService       VARCHAR(3),
    MultipleLines      VARCHAR(30),
    InternetService    VARCHAR(20),
    OnlineSecurity     VARCHAR(30),
    OnlineBackup       VARCHAR(30),
    DeviceProtection   VARCHAR(30),
    TechSupport        VARCHAR(30),
    StreamingTV        VARCHAR(30),
    StreamingMovies    VARCHAR(30),
    Contract           VARCHAR(30),
    PaperlessBilling   VARCHAR(3),
    PaymentMethod      VARCHAR(50),
    MonthlyCharges     NUMERIC(8,2),
    TotalCharges       VARCHAR(20),   -- raw; may contain spaces
    Churn              VARCHAR(3)
);

-- Load CSV (adjust path for your environment)
-- PostgreSQL COPY syntax:
\COPY stg_customer_churn FROM 'data/WA_Fn-UseC_-Telco-Customer-Churn.csv'
    DELIMITER ',' CSV HEADER;

-- Fix TotalCharges: blank → NULL, then cast
ALTER TABLE stg_customer_churn
    ADD COLUMN total_charges_clean NUMERIC(10,2);

UPDATE stg_customer_churn
SET    total_charges_clean = NULLIF(TRIM(TotalCharges), '')::NUMERIC(10,2);

-- ─────────────────────────────────────────────
-- STEP 2: Populate Dimension Tables
-- ─────────────────────────────────────────────

-- dim_demographics
INSERT INTO dim_demographics (gender, senior_citizen, has_partner, has_dependents)
SELECT DISTINCT gender, SeniorCitizen, Partner, Dependents
FROM   stg_customer_churn;

-- dim_contract
INSERT INTO dim_contract (contract_type, paperless_billing, contract_risk)
SELECT DISTINCT
    Contract,
    PaperlessBilling,
    CASE Contract
        WHEN 'Month-to-month' THEN 'High'
        WHEN 'One year'       THEN 'Medium'
        WHEN 'Two year'       THEN 'Low'
    END
FROM stg_customer_churn;

-- dim_payment
INSERT INTO dim_payment (payment_method, is_auto_pay)
SELECT DISTINCT
    PaymentMethod,
    PaymentMethod ILIKE '%automatic%'
FROM stg_customer_churn;

-- dim_internet_service
INSERT INTO dim_internet_service (
    internet_service, online_security, online_backup,
    device_protection, tech_support, streaming_tv, streaming_movies
)
SELECT DISTINCT
    InternetService, OnlineSecurity, OnlineBackup,
    DeviceProtection, TechSupport, StreamingTV, StreamingMovies
FROM stg_customer_churn;

-- dim_phone_service
INSERT INTO dim_phone_service (phone_service, multiple_lines)
SELECT DISTINCT PhoneService, MultipleLines
FROM stg_customer_churn;

-- dim_date  (one row per distinct tenure value 0-72)
INSERT INTO dim_date (date_key, tenure_months, tenure_band, tenure_year)
SELECT DISTINCT
    tenure                                           AS date_key,
    tenure                                           AS tenure_months,
    CASE
        WHEN tenure BETWEEN 0  AND 12 THEN '0-12 Mo'
        WHEN tenure BETWEEN 13 AND 24 THEN '13-24 Mo'
        WHEN tenure BETWEEN 25 AND 48 THEN '25-48 Mo'
        ELSE                               '49-72 Mo'
    END                                              AS tenure_band,
    FLOOR(tenure / 12) + 1                           AS tenure_year
FROM stg_customer_churn;

-- ─────────────────────────────────────────────
-- STEP 3: Populate Fact Table
-- ─────────────────────────────────────────────
INSERT INTO fact_customer_churn (
    customer_id, demographics_key, contract_key, payment_key,
    internet_key, phone_key, date_key,
    tenure_months, monthly_charges, total_charges, churn_flag,
    revenue_segment, clv_score
)
SELECT
    s.customerID,

    -- FK lookups
    d.demographics_key,
    c.contract_key,
    p.payment_key,
    i.internet_key,
    ph.phone_key,
    s.tenure         AS date_key,

    -- Measures
    s.tenure,
    s.MonthlyCharges,
    s.total_charges_clean,
    CASE s.Churn WHEN 'Yes' THEN 1 ELSE 0 END,

    -- Revenue segment (MonthlyCharges quartiles from EDA)
    CASE
        WHEN s.MonthlyCharges < 35.50 THEN 'Low'
        WHEN s.MonthlyCharges < 70.35 THEN 'Medium'
        WHEN s.MonthlyCharges < 89.85 THEN 'High'
        ELSE                               'Premium'
    END,

    -- CLV proxy: tenure × monthly_charges (simple but directionally correct)
    s.tenure * s.MonthlyCharges

FROM stg_customer_churn s
JOIN dim_demographics d
    ON d.gender = s.gender
   AND d.senior_citizen = s.SeniorCitizen
   AND d.has_partner = s.Partner
   AND d.has_dependents = s.Dependents
JOIN dim_contract c
    ON c.contract_type = s.Contract
   AND c.paperless_billing = s.PaperlessBilling
JOIN dim_payment p
    ON p.payment_method = s.PaymentMethod
JOIN dim_internet_service i
    ON i.internet_service = s.InternetService
   AND COALESCE(i.online_security,'')    = COALESCE(s.OnlineSecurity,'')
   AND COALESCE(i.online_backup,'')      = COALESCE(s.OnlineBackup,'')
   AND COALESCE(i.device_protection,'')  = COALESCE(s.DeviceProtection,'')
   AND COALESCE(i.tech_support,'')       = COALESCE(s.TechSupport,'')
   AND COALESCE(i.streaming_tv,'')       = COALESCE(s.StreamingTV,'')
   AND COALESCE(i.streaming_movies,'')   = COALESCE(s.StreamingMovies,'')
JOIN dim_phone_service ph
    ON ph.phone_service = s.PhoneService
   AND COALESCE(ph.multiple_lines,'') = COALESCE(s.MultipleLines,'');

-- ─────────────────────────────────────────────
-- STEP 4: Validation Counts
-- ─────────────────────────────────────────────
SELECT 'fact_customer_churn'   AS tbl, COUNT(*) FROM fact_customer_churn
UNION ALL
SELECT 'dim_demographics',       COUNT(*) FROM dim_demographics
UNION ALL
SELECT 'dim_contract',           COUNT(*) FROM dim_contract
UNION ALL
SELECT 'dim_payment',            COUNT(*) FROM dim_payment
UNION ALL
SELECT 'dim_internet_service',   COUNT(*) FROM dim_internet_service
UNION ALL
SELECT 'dim_phone_service',      COUNT(*) FROM dim_phone_service
UNION ALL
SELECT 'dim_date',               COUNT(*) FROM dim_date;
