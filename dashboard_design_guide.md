# Power BI Dashboard Design Guide
## Customer Churn Intelligence Platform

---

## Report Pages Overview

The `.pbix` file contains **5 report pages** organized for executive and analytical use.

---

## Page 1 — Executive Overview

**Purpose:** High-level KPIs for C-suite and leadership.

### Visuals

| Visual | Type | Fields |
|--------|------|--------|
| Total Customers | Card | `[Total Customers]` |
| Churn Rate % | Card (with conditional formatting) | `[Churn Rate % Fmt]` |
| Monthly Revenue at Risk | Card | `[Monthly Revenue At Risk]` |
| Annual Revenue at Risk | Card | `[Annual Revenue At Risk]` |
| Churn by Contract Type | Clustered Bar | Axis: `dim_contract[contract_type]`, Value: `[Churn Rate %]` |
| Revenue at Risk Share | Donut Chart | Legend: `dim_contract[contract_type]`, Value: `[Monthly Revenue At Risk]` |
| Retained vs Churned | Stacked Column | Axis: `dim_date[tenure_band]`, Values: `[Total Retained]`, `[Total Churned]` |
| KPI Trend by Tenure | Line Chart | Axis: `fact_customer_churn[tenure_months]`, Value: `[Churn Rate %]` |

### Slicers
- `dim_contract[contract_type]`
- `dim_demographics[gender]`
- `dim_internet_service[internet_service]`

---

## Page 2 — Revenue Loss Analysis

**Purpose:** Identify which customer segments drive the highest dollar revenue loss.

### Visuals

| Visual | Type | Fields |
|--------|------|--------|
| Revenue Segment Matrix | Matrix | Rows: `fact_customer_churn[revenue_segment]`, Cols: `dim_contract[contract_risk]`, Values: `[Monthly Revenue At Risk]`, `[Churn Rate %]` |
| Top 20 High-Value Churners | Table | `customer_id`, `monthly_charges`, `tenure_months`, `dim_contract[contract_type]`, `dim_internet_service[internet_service]` |
| Monthly Revenue at Risk by Payment | Treemap | Group: `dim_payment[payment_method]`, Value: `[Monthly Revenue At Risk]` |
| ARPU Comparison | Clustered Bar | Category: Churned/Retained, Value: `[Avg ARPU Churned]` / `[Avg ARPU Retained]` |
| CLV Distribution | Histogram (custom) | Axis: `fact_customer_churn[clv_score]` bins | Value: `[Total Customers]` |

---

## Page 3 — Churn Driver Analysis

**Purpose:** Deep-dive into the root causes of churn.

### Visuals

| Visual | Type | Fields |
|--------|------|--------|
| Churn Rate Heatmap | Matrix | Rows: `dim_internet_service[internet_service]`, Cols: `dim_contract[contract_type]`, Value: `[Churn Rate %]` (background color rule: Red scale) |
| Payment Method Breakdown | Stacked Bar | Axis: `dim_payment[payment_method]`, Values: `[Total Retained]`, `[Total Churned]` |
| Service Add-on Impact | Clustered Bar | Axis: `dim_internet_service[online_security]`, Value: `[Churn Rate %]` — filtered to internet customers |
| Senior vs Non-Senior | Clustered Column | Category: `dim_demographics[senior_citizen]`, Values: `[Churn Rate %]`, `[Monthly Revenue At Risk]` |
| Paperless Billing Impact | Card + Bar | Filtered by `dim_contract[paperless_billing]` |

### Key Insight Callouts (Text Boxes)
- "⚠ Month-to-month customers churn at **42.7%** — 15× higher than two-year contracts"
- "🔴 Electronic check users churn at **45.3%** — the highest of any payment method"
- "📡 Fiber Optic customers churn at **41.9%** — nearly double DSL rate"

---

## Page 4 — Customer Segmentation

**Purpose:** Segment customers by risk profile for targeted retention campaigns.

### Visuals

| Visual | Type | Fields |
|--------|------|--------|
| Risk Score Matrix | Table | All dimension attributes + `[Churn Risk Score]`, `[Revenue At Risk Share %]` |
| Contract × Payment Scatter | Scatter | X: `[Avg Tenure Months]`, Y: `[Churn Rate %]`, Size: `[Monthly Revenue At Risk]`, Legend: `dim_contract[contract_type]` |
| Tenure Band Funnel | Funnel | Category: `dim_date[tenure_band]`, Values: `[Total Churned]` |
| Auto-Pay vs Manual-Pay | KPI Card pair | `[Auto-Pay Churn Rate]` vs `[Manual-Pay Churn Rate]` |

---

## Page 5 — Retention Opportunity

**Purpose:** Quantify the ROI of targeted retention interventions.

### Visuals

| Visual | Type | Fields |
|--------|------|--------|
| Retention Opportunity ($) | Gauge | Value: `[Annual Revenue At Risk]`, Target: 0 |
| If 10% Churn Reduced | Card (calculated) | `= [Monthly Revenue At Risk] * 0.10` |
| Priority Segment Table | Table | Segments ranked by `[Revenue At Risk Share %]` descending |
| Month-to-Month → 1yr Conversion Impact | What-if Scenario | Power BI What-If Parameter: `% of M-t-M converted` |

### What-If Parameter Setup
1. **New Parameter:** "Conversion Rate" — Min: 0%, Max: 50%, Default: 10%, Increment: 1%
2. **Measure:**
   ```
   Conversion Revenue Saved =
   [Month-to-Month Revenue At Risk]
       * 'Conversion Rate'[Conversion Rate Value]
       * (1 - [Churn Rate One Year])
   ```

---

## Color Scheme & Formatting

| Element | Color | Hex |
|---------|-------|-----|
| Churned / High Risk | Red | `#F44336` |
| Warning / Medium Risk | Orange | `#FF9800` |
| Retained / Low Risk | Green | `#4CAF50` |
| Primary Blue | Blue | `#1565C0` |
| Background | Light Gray | `#F8F9FA` |
| Card Background | White | `#FFFFFF` |
| Accent | Dark Blue | `#0D47A1` |

### Fonts
- **Titles:** Segoe UI Semibold, 16pt
- **Card labels:** Segoe UI, 11pt, Bold value
- **Axis labels:** Segoe UI, 10pt

---

## Data Model Relationships

```
dim_demographics  ─────┐
dim_contract      ─────┤
dim_payment       ─────┼──► fact_customer_churn (star center)
dim_internet_service ──┤
dim_phone_service ─────┤
dim_date          ─────┘
```

All relationships: **One-to-Many** (Dimension PK → Fact FK), **Single direction filter** (dimension → fact).

---

## Step-by-Step: Importing Into Power BI

1. Open Power BI Desktop → **Get Data → PostgreSQL** (or **Text/CSV** for direct import)
2. Connect to your database using credentials from `sql/01_star_schema_ddl.sql`
3. Import all 7 tables (`fact_customer_churn` + 6 dimensions)
4. In **Model view**, verify all relationships are correctly set (auto-detect usually works)
5. Create a **New Table** named `_Measures` (blank table for organization)
6. Paste each measure from `dax/churn_measures.dax` into the measures table
7. Build pages following this guide
8. Apply the color theme via **View → Themes → Customize**

---

## Publish & Share

- **Power BI Service:** Publish → select workspace → share dashboard link
- **Scheduled Refresh:** Configure via Power BI Service gateway if connecting live to PostgreSQL
- **Row-Level Security (RLS):** Optional — apply on `dim_demographics[gender]` or `dim_contract[contract_type]` for role-based views
