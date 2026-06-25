"""
Customer Churn Intelligence Platform
Exploratory Data Analysis (EDA)
Dataset: IBM Telco Customer Churn — 7,043 customers
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────
DATA_PATH   = Path("data/WA_Fn-UseC_-Telco-Customer-Churn.csv")
OUTPUT_DIR  = Path("python-eda/charts")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

PALETTE     = {"No": "#2196F3", "Yes": "#F44336"}
BG          = "#F8F9FA"
plt.rcParams.update({
    "figure.facecolor": BG,
    "axes.facecolor":   BG,
    "font.family":      "DejaVu Sans",
    "axes.spines.top":  False,
    "axes.spines.right": False,
})

# ── Load & Clean ──────────────────────────────────────────────────────────────
df = pd.read_csv(DATA_PATH)
df["TotalCharges"] = pd.to_numeric(df["TotalCharges"], errors="coerce")
df["TotalCharges"].fillna(df["TotalCharges"].median(), inplace=True)
df["Churn_Flag"] = (df["Churn"] == "Yes").astype(int)

print(f"Dataset shape: {df.shape}")
print(f"Churn rate   : {df['Churn_Flag'].mean():.2%}")
print(f"Monthly Rev at Risk: ${df.loc[df['Churn']=='Yes','MonthlyCharges'].sum():,.2f}")

# ── 1. Churn Distribution Donut ───────────────────────────────────────────────
def plot_churn_donut():
    counts = df["Churn"].value_counts()
    fig, ax = plt.subplots(figsize=(6, 6))
    wedges, texts, autotexts = ax.pie(
        counts, labels=counts.index,
        autopct="%1.1f%%", startangle=90,
        colors=[PALETTE["No"], PALETTE["Yes"]],
        wedgeprops=dict(width=0.5, edgecolor="white", linewidth=3),
        textprops=dict(fontsize=13),
    )
    for at in autotexts:
        at.set_fontsize(14)
        at.set_fontweight("bold")
    ax.set_title("Customer Churn Distribution\n7,043 Customers", fontsize=15, fontweight="bold", pad=20)
    ax.text(0, 0, f"{counts['Yes']:,}\nchurned", ha="center", va="center", fontsize=13, fontweight="bold", color="#F44336")
    plt.tight_layout()
    fig.savefig(OUTPUT_DIR / "01_churn_distribution.png", dpi=150, bbox_inches="tight")
    plt.close()

plot_churn_donut()

# ── 2. Churn Rate by Contract Type ────────────────────────────────────────────
def plot_contract_churn():
    grp = df.groupby("Contract")["Churn_Flag"].agg(["sum", "mean", "count"]).reset_index()
    grp.columns = ["Contract", "Churned", "Rate", "Total"]
    grp = grp.sort_values("Rate", ascending=True)

    fig, ax = plt.subplots(figsize=(8, 4))
    colors = ["#4CAF50", "#FF9800", "#F44336"]
    bars = ax.barh(grp["Contract"], grp["Rate"] * 100, color=colors, height=0.5, edgecolor="white")
    for bar, (_, row) in zip(bars, grp.iterrows()):
        ax.text(bar.get_width() + 0.5, bar.get_y() + bar.get_height() / 2,
                f"{row['Rate']:.1%}  ({int(row['Churned']):,} / {int(row['Total']):,})",
                va="center", fontsize=11)
    ax.set_xlabel("Churn Rate (%)", fontsize=11)
    ax.set_title("Churn Rate by Contract Type", fontsize=14, fontweight="bold")
    ax.set_xlim(0, 55)
    ax.xaxis.set_major_formatter(mticker.FormatStrFormatter("%.0f%%"))
    plt.tight_layout()
    fig.savefig(OUTPUT_DIR / "02_churn_by_contract.png", dpi=150, bbox_inches="tight")
    plt.close()

plot_contract_churn()

# ── 3. Revenue at Risk by Segment ─────────────────────────────────────────────
def plot_revenue_at_risk():
    segments = ["Contract", "InternetService", "PaymentMethod"]
    fig, axes = plt.subplots(1, 3, figsize=(16, 5))
    fig.suptitle("Monthly Revenue at Risk ($) by Segment", fontsize=14, fontweight="bold")

    for ax, seg in zip(axes, segments):
        grp = df[df["Churn"] == "Yes"].groupby(seg)["MonthlyCharges"].sum().sort_values(ascending=True)
        grp.plot(kind="barh", ax=ax, color="#F44336", alpha=0.8, edgecolor="white")
        ax.set_title(seg.replace("PaymentMethod", "Payment Method"), fontsize=12, fontweight="bold")
        ax.set_xlabel("Monthly Revenue Lost ($)")
        ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"${x:,.0f}"))
        for p in ax.patches:
            ax.text(p.get_width() + 200, p.get_y() + p.get_height() / 2,
                    f"${p.get_width():,.0f}", va="center", fontsize=9)

    plt.tight_layout()
    fig.savefig(OUTPUT_DIR / "03_revenue_at_risk.png", dpi=150, bbox_inches="tight")
    plt.close()

plot_revenue_at_risk()

# ── 4. Churn Rate by Tenure Band ──────────────────────────────────────────────
def plot_tenure_churn():
    bins  = [0, 12, 24, 48, 72]
    labels = ["0-12 Mo", "13-24 Mo", "25-48 Mo", "49-72 Mo"]
    df["TenureBand"] = pd.cut(df["tenure"], bins=bins, labels=labels, right=True, include_lowest=True)
    grp = df.groupby("TenureBand", observed=True)["Churn_Flag"].agg(["mean", "count"]).reset_index()

    fig, ax = plt.subplots(figsize=(8, 4))
    colors = ["#F44336", "#FF9800", "#FFC107", "#4CAF50"]
    bars = ax.bar(grp["TenureBand"], grp["mean"] * 100, color=colors, width=0.5, edgecolor="white")
    for bar, (_, row) in zip(bars, grp.iterrows()):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.5,
                f"{row['mean']:.1%}\n(n={int(row['count']):,})",
                ha="center", va="bottom", fontsize=10, fontweight="bold")
    ax.set_ylabel("Churn Rate (%)")
    ax.set_title("Churn Rate by Customer Tenure Band", fontsize=14, fontweight="bold")
    ax.yaxis.set_major_formatter(mticker.FormatStrFormatter("%.0f%%"))
    ax.set_ylim(0, 55)
    plt.tight_layout()
    fig.savefig(OUTPUT_DIR / "04_churn_by_tenure.png", dpi=150, bbox_inches="tight")
    plt.close()

plot_tenure_churn()

# ── 5. Monthly Charges Distribution: Churned vs Retained ─────────────────────
def plot_charges_dist():
    fig, ax = plt.subplots(figsize=(9, 5))
    for label, color in PALETTE.items():
        subset = df[df["Churn"] == label]["MonthlyCharges"]
        ax.hist(subset, bins=30, alpha=0.6, color=color, label=f"Churn={label}", edgecolor="white")
        ax.axvline(subset.mean(), color=color, lw=2, linestyle="--",
                   label=f"Mean ({label}): ${subset.mean():.0f}")
    ax.set_xlabel("Monthly Charges ($)")
    ax.set_ylabel("Customer Count")
    ax.set_title("Monthly Charges Distribution: Churned vs Retained", fontsize=14, fontweight="bold")
    ax.legend()
    plt.tight_layout()
    fig.savefig(OUTPUT_DIR / "05_charges_distribution.png", dpi=150, bbox_inches="tight")
    plt.close()

plot_charges_dist()

# ── 6. Correlation Heatmap ────────────────────────────────────────────────────
def plot_correlation():
    num_cols = ["tenure", "MonthlyCharges", "TotalCharges", "Churn_Flag", "SeniorCitizen"]
    corr = df[num_cols].corr()
    fig, ax = plt.subplots(figsize=(7, 6))
    mask = np.triu(np.ones_like(corr, dtype=bool))
    sns.heatmap(corr, mask=mask, annot=True, fmt=".2f", cmap="RdYlGn_r",
                center=0, vmin=-1, vmax=1, ax=ax, linewidths=0.5,
                cbar_kws={"shrink": 0.8})
    ax.set_title("Feature Correlation Matrix", fontsize=14, fontweight="bold")
    plt.tight_layout()
    fig.savefig(OUTPUT_DIR / "06_correlation_heatmap.png", dpi=150, bbox_inches="tight")
    plt.close()

plot_correlation()

# ── 7. Payment Method × Churn ─────────────────────────────────────────────────
def plot_payment_churn():
    grp = df.groupby(["PaymentMethod", "Churn"]).size().unstack(fill_value=0)
    grp["Rate"] = grp["Yes"] / (grp["Yes"] + grp["No"])
    grp = grp.sort_values("Rate", ascending=False)

    fig, ax = plt.subplots(figsize=(9, 5))
    x = np.arange(len(grp))
    width = 0.35
    ax.bar(x - width/2, grp["No"],  width, label="Retained", color="#2196F3", alpha=0.85)
    ax.bar(x + width/2, grp["Yes"], width, label="Churned",  color="#F44336", alpha=0.85)
    for i, (_, row) in enumerate(grp.iterrows()):
        ax.text(i + width/2, row["Yes"] + 10, f"{row['Rate']:.0%}", ha="center", fontsize=10, fontweight="bold", color="#F44336")
    ax.set_xticks(x)
    ax.set_xticklabels(grp.index, rotation=15, ha="right")
    ax.set_ylabel("Customer Count")
    ax.set_title("Churn by Payment Method", fontsize=14, fontweight="bold")
    ax.legend()
    plt.tight_layout()
    fig.savefig(OUTPUT_DIR / "07_churn_by_payment.png", dpi=150, bbox_inches="tight")
    plt.close()

plot_payment_churn()

# ── 8. Churn Rate — Internet Service × Security Add-on ───────────────────────
def plot_internet_security():
    sub = df[df["InternetService"] != "No"].copy()
    grp = sub.groupby(["InternetService", "OnlineSecurity"])["Churn_Flag"].mean().reset_index()
    grp.columns = ["InternetService", "OnlineSecurity", "ChurnRate"]
    pivot = grp.pivot(index="InternetService", columns="OnlineSecurity", values="ChurnRate")

    fig, ax = plt.subplots(figsize=(8, 4))
    pivot.plot(kind="bar", ax=ax, color=["#F44336", "#FF9800", "#4CAF50"], edgecolor="white", alpha=0.85)
    ax.set_ylabel("Churn Rate")
    ax.set_xticklabels(pivot.index, rotation=0)
    ax.set_title("Churn Rate: Internet Service × Online Security", fontsize=13, fontweight="bold")
    ax.yaxis.set_major_formatter(mticker.PercentFormatter(xmax=1))
    ax.legend(title="Online Security", bbox_to_anchor=(1, 1))
    plt.tight_layout()
    fig.savefig(OUTPUT_DIR / "08_internet_security_churn.png", dpi=150, bbox_inches="tight")
    plt.close()

plot_internet_security()

# ── Summary Stats Export ──────────────────────────────────────────────────────
summary = {
    "Total Customers"               : len(df),
    "Churned Customers"             : int(df["Churn_Flag"].sum()),
    "Churn Rate"                    : f"{df['Churn_Flag'].mean():.2%}",
    "Monthly Revenue at Risk"       : f"${df.loc[df['Churn']=='Yes','MonthlyCharges'].sum():,.2f}",
    "Annual Revenue at Risk"        : f"${df.loc[df['Churn']=='Yes','MonthlyCharges'].sum()*12:,.2f}",
    "Avg ARPU Churned"              : f"${df.loc[df['Churn']=='Yes','MonthlyCharges'].mean():.2f}",
    "Avg ARPU Retained"             : f"${df.loc[df['Churn']=='No','MonthlyCharges'].mean():.2f}",
    "Month-to-Month Churn Rate"     : f"{df[df['Contract']=='Month-to-month']['Churn_Flag'].mean():.2%}",
    "Two Year Churn Rate"           : f"{df[df['Contract']=='Two year']['Churn_Flag'].mean():.2%}",
    "Fiber Optic Churn Rate"        : f"{df[df['InternetService']=='Fiber optic']['Churn_Flag'].mean():.2%}",
    "Electronic Check Churn Rate"   : f"{df[df['PaymentMethod']=='Electronic check']['Churn_Flag'].mean():.2%}",
    "Senior Citizen Churn Rate"     : f"{df[df['SeniorCitizen']==1]['Churn_Flag'].mean():.2%}",
}
pd.DataFrame.from_dict(summary, orient="index", columns=["Value"]).to_csv(
    "python-eda/eda_summary_stats.csv"
)

print("\n✅ EDA complete. Charts saved to python-eda/charts/")
print("\n── Key Findings ──────────────────────────────────────")
for k, v in summary.items():
    print(f"  {k:<38}: {v}")
