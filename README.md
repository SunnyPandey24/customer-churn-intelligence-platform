# 📊 Customer Churn Intelligence Platform

> **End-to-end churn analytics pipeline** built on SQL star-schema modeling, Python EDA, advanced DAX, and interactive Power BI executive dashboards — analyzing **7,043 telecom customers** to quantify revenue loss and surface actionable retention drivers.

---

## 🔍 Project Summary

| Metric | Value |
|--------|-------|
| 📦 Dataset | IBM Telco Customer Churn (Kaggle) |
| 👥 Customers Analyzed | 7,043 |
| 📉 Overall Churn Rate | **26.54%** |
| 💸 Monthly Revenue at Risk | **$139,131** |
| 📅 Annual Revenue at Risk | **$1,669,570** |
| 🏗️ Data Model | Star Schema (1 Fact + 6 Dimensions) |
| 🛠️ Tech Stack | PostgreSQL · Python · Power BI · DAX |

---

## 🚨 Key Findings

| Driver | Churn Rate | Insight |
|--------|-----------|---------|
| **Month-to-Month Contract** | 42.7% | 15× higher than Two-Year customers |
| **Electronic Check Payment** | 45.3% | Highest churn of any payment method |
| **Fiber Optic Internet** | 41.9% | Nearly 2× DSL churn rate |
| **No Online Security** | ~41% | Strong protective effect when added |
| **Senior Citizens** | 41.7% | Significantly above 26.5% baseline |
| **Tenure < 12 months** | ~47% | Early-life churn is the #1 risk window |
| **Two-Year Contract** | 2.8% | Near-zero churn — highest loyalty signal |

---

## 📁 Repository Structure

```
customer-churn-intelligence-platform/
│
├── data/
│   └── WA_Fn-UseC_-Telco-Customer-Churn.csv   # Raw dataset (7,043 rows × 21 cols)
│
├── sql/
│   ├── 01_star_schema_ddl.sql                  # Star schema DDL (fact + 6 dims)
│   ├── 02_etl_load.sql                         # Staging → dimension → fact ETL
│   └── 03_analytics_queries.sql                # 10 advanced analytics queries
│
├── dax/
│   └── churn_measures.dax                      # 35+ DAX measures for Power BI
│
├── python-eda/
│   ├── eda_analysis.py                         # Full EDA with 8 publication charts
│   ├── eda_summary_stats.csv                   # Key stats output
│   └── charts/                                 # Generated chart PNGs
│       ├── 01_churn_distribution.png
│       ├── 02_churn_by_contract.png
│       ├── 03_revenue_at_risk.png
│       ├── 04_churn_by_tenure.png
│       ├── 05_charges_distribution.png
│       ├── 06_correlation_heatmap.png
│       ├── 07_churn_by_payment.png
│       └── 08_internet_security_churn.png
│
└── powerbi-docs/
    └── dashboard_design_guide.md               # 5-page dashboard design blueprint
```

---

## 🏗️ Data Architecture — Star Schema

```
                    ┌─────────────────────┐
                    │   dim_demographics   │
                    │  gender, senior,     │
                    │  partner, dependents │
                    └──────────┬──────────┘
                               │
  ┌──────────────┐    ┌────────▼────────────────┐    ┌──────────────────┐
  │ dim_contract │    │                          │    │   dim_payment    │
  │ type, risk,  ├───►│   fact_customer_churn    │◄───│  method,         │
  │ paperless    │    │                          │    │  is_auto_pay     │
  └──────────────┘    │  • customer_id (PK)      │    └──────────────────┘
                      │  • tenure_months         │
  ┌──────────────┐    │  • monthly_charges       │    ┌──────────────────┐
  │ dim_internet │    │  • total_charges         │    │  dim_phone       │
  │ service,     ├───►│  • churn_flag ✓          │◄───│  service,        │
  │ add-ons      │    │  • clv_score             │    │  multiple_lines  │
  └──────────────┘    │  • revenue_segment       │    └──────────────────┘
                      │  • annual_revenue        │
                      └──────────┬───────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │        dim_date           │
                    │  tenure_band, tenure_year │
                    └──────────────────────────┘
```

---

## 🛠️ Tech Stack & Skills Demonstrated

### SQL (PostgreSQL)
- ✅ Star schema design with surrogate keys and referential integrity
- ✅ Staged ETL pipeline: raw CSV → staging → dimensions → fact
- ✅ Window functions (`OVER`, `ROWS BETWEEN`) for rolling churn rate
- ✅ `GENERATED ALWAYS AS` computed columns for annual revenue
- ✅ Composite index strategy for dashboard query performance
- ✅ Revenue segmentation using data-driven quartile thresholds

### Python (Pandas + Matplotlib + Seaborn)
- ✅ Data cleaning: type coercion, missing value imputation
- ✅ Feature engineering: tenure bands, churn flags, CLV proxy
- ✅ 8 publication-quality charts for executive presentations
- ✅ Summary statistics export for reporting pipelines

### Power BI & DAX
- ✅ Star schema imported with correct one-to-many relationships
- ✅ 35+ DAX measures covering KPIs, revenue, demographics, and risk
- ✅ `CALCULATE` + `FILTER` for segment-specific churn rates
- ✅ `DIVIDE` with safe denominator handling
- ✅ `SWITCH(TRUE(), ...)` for dynamic risk score labels
- ✅ `ISFILTERED` + `SELECTEDVALUE` for dynamic report titles
- ✅ What-If parameter for retention scenario modeling
- ✅ Conditional formatting / background color rules for heatmaps

---

## 🚀 Quick Start

### Prerequisites
- PostgreSQL 14+ (or any SQL database — adjust syntax as needed)
- Python 3.9+ with `pandas`, `matplotlib`, `seaborn`
- Power BI Desktop (free)

### 1. Set Up Database

```bash
psql -U postgres -d your_database -f sql/01_star_schema_ddl.sql
psql -U postgres -d your_database -f sql/02_etl_load.sql
```

### 2. Run EDA

```bash
pip install pandas matplotlib seaborn
python python-eda/eda_analysis.py
```

Charts will be saved to `python-eda/charts/`.

### 3. Explore Analytics Queries

```bash
psql -U postgres -d your_database -f sql/03_analytics_queries.sql
```

### 4. Build Power BI Dashboard

1. Open **Power BI Desktop**
2. **Get Data → PostgreSQL** → connect to your DB
3. Import all 7 tables
4. In Model view, verify star-schema relationships
5. Create a blank table called `_Measures`
6. Copy-paste measures from `dax/churn_measures.dax`
7. Follow `powerbi-docs/dashboard_design_guide.md` to build 5 report pages

---

## 📈 Dashboard Pages

| Page | Purpose |
|------|---------|
| 1. Executive Overview | KPI cards, churn rate by contract, revenue at risk trend |
| 2. Revenue Loss Analysis | Segment matrix, top churners table, ARPU comparison |
| 3. Churn Driver Analysis | Heatmaps, payment breakdown, service add-on impact |
| 4. Customer Segmentation | Risk scoring, scatter plots, tenure funnel |
| 5. Retention Opportunity | What-if scenario modeling, intervention ROI |

---

## 📊 Sample Analytics Output

**Q: What is the churn rate by contract type?**

| Contract | Customers | Churned | Churn Rate | Monthly Rev at Risk |
|----------|-----------|---------|-----------|-------------------|
| Month-to-month | 3,875 | 1,655 | **42.7%** | $108,062 |
| One year | 1,473 | 166 | 11.3% | $22,453 |
| Two year | 1,695 | 48 | **2.8%** | $8,616 |

**Q: Which payment method has the highest churn?**

| Payment Method | Churn Rate |
|---------------|-----------|
| Electronic check | **45.3%** |
| Mailed check | 19.1% |
| Bank transfer (auto) | 16.7% |
| Credit card (auto) | 15.2% |

---

## 💡 Business Recommendations

1. **Contract Upgrade Campaign** — Incentivize month-to-month customers to upgrade to annual contracts; model shows this could reduce churn from 42.7% → ~11%, saving **$96K/month** at 100% conversion.
2. **Auto-Pay Adoption** — Customers paying manually churn at 2–3× the rate of auto-pay customers. Offer a billing credit for switching.
3. **Early Intervention (0–12 Mo)** — With ~47% churn in Year 1, onboarding is the highest-leverage intervention window. Proactive outreach at Month 3 and 6.
4. **Fiber Optic Retention** — Fiber customers are high ARPU but high churn. Bundling `OnlineSecurity` + `TechSupport` could reduce their churn significantly.
5. **Senior Citizen Segment** — With 41.7% churn vs 26.5% average, a dedicated support program (simplified billing, priority support) would have outsized impact.

---

## 📄 Dataset

- **Source:** [IBM Sample Data — Telco Customer Churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
- **License:** IBM Community License / Kaggle Open Dataset
- **Rows:** 7,043 customers × 21 features

---

## 👤 Author

**Sunny PAndey**  

<img width="2891" height="2171" alt="star_schema_diagram" src="https://github.com/user-attachments/assets/e39a0c31-bbfa-4c0d-8230-9e67fefcfa0f" />
<img width="2389" height="740" alt="03_revenue_at_risk" src="https://github.com/user-attachments/assets/4cbd2a59-1748-4b8b-9184-462957ec90ef" />
<img width="1189" height="584" alt="02_churn_by_contract" src="https://github.com/user-attachments/assets/f17968d2-bcb8-482d-a7a8-1dc8e269c561" />
<img width="784" height="882" alt="01_churn_distribution" src="https://github.com/user-attachments/assets/7d7875a5-6171-40c5-8811-2cf774d157fc" />
<img width="1184" height="582" alt="08_internet_security_churn" src="https://github.com/user-attachments/assets/6eaecc91-75b4-42df-9542-955ac92865aa" />
<img width="1334" height="733" alt="07_churn_by_payment" src="https://github.com/user-attachments/assets/25d01c25-0a16-4ec8-8e81-4cb77fdfeb7c" />
<img width="1015" height="884" alt="06_correlation_heatmap" src="https://github.com/user-attachments/assets/16b21155-bc01-4dd1-8ebe-141cb0e3b89d" />
<img width="1334" height="732" alt="05_charges_distribution" src="https://github.com/user-attachments/assets/b9ea6373-5f63-40d9-94ec-1087b14777a8" />
<img width="1184" height="583" alt="04_churn_by_tenure" src="https://github.com/user-attachments/assets/c6dbdcd2-c353-4407-afae-0661a8178888" />


---

## ⭐ If you found this useful, please give it a star!
