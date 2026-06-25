-- ============================================================
-- Customer Churn Intelligence Platform
-- Advanced Analytics Queries — Revenue Loss & Churn Drivers
-- ============================================================

-- ─────────────────────────────────────────────
-- Q1: Executive KPI Summary
-- ─────────────────────────────────────────────
SELECT
    COUNT(*)                                                         AS total_customers,
    SUM(churn_flag)                                                  AS total_churned,
    ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)                    AS churn_rate_pct,
    ROUND(SUM(CASE WHEN churn_flag = 1 THEN monthly_charges END), 2) AS monthly_revenue_at_risk,
    ROUND(SUM(CASE WHEN churn_flag = 1 THEN monthly_charges * 12 END), 2) AS annual_revenue_at_risk,
    ROUND(AVG(CASE WHEN churn_flag = 1 THEN monthly_charges END), 2) AS avg_churned_arpu,
    ROUND(AVG(CASE WHEN churn_flag = 0 THEN monthly_charges END), 2) AS avg_retained_arpu,
    ROUND(AVG(CASE WHEN churn_flag = 1 THEN clv_score END), 2)      AS avg_churned_clv
FROM fact_customer_churn;


-- ─────────────────────────────────────────────
-- Q2: Churn Rate by Contract Type (primary revenue-loss driver)
-- ─────────────────────────────────────────────
SELECT
    c.contract_type,
    c.contract_risk,
    COUNT(*)                                                AS customer_count,
    SUM(f.churn_flag)                                       AS churned,
    ROUND(100.0 * SUM(f.churn_flag) / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(SUM(CASE WHEN f.churn_flag=1 THEN f.monthly_charges END), 2) AS monthly_rev_at_risk
FROM  fact_customer_churn f
JOIN  dim_contract c USING (contract_key)
GROUP BY c.contract_type, c.contract_risk
ORDER BY churn_rate_pct DESC;


-- ─────────────────────────────────────────────
-- Q3: Churn Rate by Internet Service & Add-ons
-- ─────────────────────────────────────────────
SELECT
    i.internet_service,
    i.online_security,
    i.tech_support,
    COUNT(*)                                                AS customers,
    SUM(f.churn_flag)                                       AS churned,
    ROUND(100.0 * SUM(f.churn_flag) / COUNT(*), 2)        AS churn_rate_pct
FROM  fact_customer_churn f
JOIN  dim_internet_service i USING (internet_key)
GROUP BY i.internet_service, i.online_security, i.tech_support
ORDER BY churn_rate_pct DESC
LIMIT 20;


-- ─────────────────────────────────────────────
-- Q4: Payment Method Churn Analysis
-- ─────────────────────────────────────────────
SELECT
    p.payment_method,
    p.is_auto_pay,
    COUNT(*)                                                AS customers,
    SUM(f.churn_flag)                                       AS churned,
    ROUND(100.0 * SUM(f.churn_flag) / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(f.monthly_charges), 2)                        AS avg_monthly_charges
FROM  fact_customer_churn f
JOIN  dim_payment p USING (payment_key)
GROUP BY p.payment_method, p.is_auto_pay
ORDER BY churn_rate_pct DESC;


-- ─────────────────────────────────────────────
-- Q5: Churn by Tenure Band (early-life vs loyal)
-- ─────────────────────────────────────────────
SELECT
    d.tenure_band,
    COUNT(*)                                                AS customers,
    SUM(f.churn_flag)                                       AS churned,
    ROUND(100.0 * SUM(f.churn_flag) / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(f.monthly_charges), 2)                        AS avg_arpu,
    ROUND(SUM(CASE WHEN f.churn_flag=1 THEN f.monthly_charges END), 2) AS monthly_rev_at_risk
FROM  fact_customer_churn f
JOIN  dim_date d USING (date_key)
GROUP BY d.tenure_band
ORDER BY MIN(d.tenure_months);


-- ─────────────────────────────────────────────
-- Q6: Revenue Segment × Contract Risk Matrix
-- ─────────────────────────────────────────────
SELECT
    f.revenue_segment,
    c.contract_risk,
    COUNT(*)                                                AS customers,
    SUM(f.churn_flag)                                       AS churned,
    ROUND(100.0 * SUM(f.churn_flag) / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(SUM(f.monthly_charges), 2)                        AS total_monthly_revenue,
    ROUND(SUM(CASE WHEN f.churn_flag=1 THEN f.monthly_charges END), 2) AS revenue_at_risk
FROM  fact_customer_churn f
JOIN  dim_contract c USING (contract_key)
GROUP BY f.revenue_segment, c.contract_risk
ORDER BY f.revenue_segment, c.contract_risk;


-- ─────────────────────────────────────────────
-- Q7: Demographics Impact (Senior / Partner / Dependents)
-- ─────────────────────────────────────────────
SELECT
    d.gender,
    d.senior_citizen,
    d.has_partner,
    d.has_dependents,
    COUNT(*)                                                AS customers,
    SUM(f.churn_flag)                                       AS churned,
    ROUND(100.0 * SUM(f.churn_flag) / COUNT(*), 2)        AS churn_rate_pct
FROM  fact_customer_churn f
JOIN  dim_demographics d USING (demographics_key)
GROUP BY d.gender, d.senior_citizen, d.has_partner, d.has_dependents
ORDER BY churn_rate_pct DESC
LIMIT 20;


-- ─────────────────────────────────────────────
-- Q8: High-Value Churners (Top Revenue Loss)
-- ─────────────────────────────────────────────
SELECT
    f.customer_id,
    f.monthly_charges,
    f.total_charges,
    f.tenure_months,
    f.clv_score,
    f.revenue_segment,
    c.contract_type,
    p.payment_method,
    i.internet_service
FROM  fact_customer_churn f
JOIN  dim_contract c         USING (contract_key)
JOIN  dim_payment p          USING (payment_key)
JOIN  dim_internet_service i USING (internet_key)
WHERE f.churn_flag = 1
ORDER BY f.monthly_charges DESC
LIMIT 50;


-- ─────────────────────────────────────────────
-- Q9: Churn Rate Rolling Trend by Tenure Month
-- ─────────────────────────────────────────────
SELECT
    f.tenure_months,
    COUNT(*)                                               AS customers,
    SUM(f.churn_flag)                                      AS churned,
    ROUND(100.0 * SUM(f.churn_flag) / COUNT(*), 2)       AS churn_rate_pct,
    ROUND(AVG(SUM(f.churn_flag)) OVER (
        ORDER BY f.tenure_months
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                                  AS churn_rate_3mo_avg
FROM  fact_customer_churn f
GROUP BY f.tenure_months
ORDER BY f.tenure_months;


-- ─────────────────────────────────────────────
-- Q10: Service Bundle Analysis
--      Customers with NO add-on services vs protected customers
-- ─────────────────────────────────────────────
SELECT
    CASE
        WHEN i.online_security = 'No'
         AND i.tech_support    = 'No'
         AND i.online_backup   = 'No'
         AND i.device_protection = 'No' THEN 'No Protection Services'
        WHEN i.online_security = 'Yes'
         AND i.tech_support    = 'Yes'   THEN 'Fully Protected'
        ELSE                                  'Partially Protected'
    END                                                    AS protection_tier,
    COUNT(*)                                               AS customers,
    SUM(f.churn_flag)                                      AS churned,
    ROUND(100.0 * SUM(f.churn_flag) / COUNT(*), 2)       AS churn_rate_pct,
    ROUND(AVG(f.monthly_charges), 2)                       AS avg_monthly_charges
FROM  fact_customer_churn f
JOIN  dim_internet_service i USING (internet_key)
WHERE i.internet_service != 'No'
GROUP BY protection_tier
ORDER BY churn_rate_pct DESC;
