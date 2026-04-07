# Customer Segmentation Analysis — Dunnhumby Retail Dataset

**Overview**
This project performs a full RFM (Recency, Frequency, Monetary) analysis on the Dunnhumby "The Complete Journey" retail dataset, segmenting 2,500+ customers into behavioral groups to support targeted marketing and retention strategies.
**Dataset**
Dunnhumby — The Complete Journey
The dataset contains two years of household-level transaction data from a retail grocery chain, including purchases, promotions, coupon usage, and demographic information across 2,500 households and 8 tables.
Methodology

**1. Data Loading & Cleaning (PostgreSQL)**

Loaded 8 CSV files into a local PostgreSQL database
Standardized all column names to lowercase
Removed transactions with zero sales value and no associated discounts (10,121 rows)

**2. EDA (PostgreSQL)**

Analyzed basket-level and customer-level distributions
Calculated mean and median basket value, spend, and active customer span
Found that the median customer was active for 626 out of 711 days — indicating a highly loyal customer base

**3. RFM Scoring (PostgreSQL)**

Calculated Recency, Frequency, and Monetary values per customer
Scored each dimension 1–5 using NTILE(5) window function
Segmented customers into 8 behavioral groups using score-based rules

**4. Visualization (Power BI)**

Connected Power BI directly to PostgreSQL
Built an interactive dashboard sliceable by customer segment

**Key Findings**

Potential Loyalists is the largest segment with 680 customers — a major opportunity for conversion to Champions
Champions generate the highest sales despite being only 358 customers — high value, high engagement
97.49% of Champions have used coupons, suggesting promotions play a key role in retaining top customers
New Customers have the lowest coupon usage at 41.18% — onboarding campaigns could improve early engagement
Cant Lose Them segment shows 93.90% coupon usage but low recency — win-back campaigns are critical for this group

**Dashboard**
The Power BI dashboard includes:

KPI cards — total baskets, total sales, customer count, average spend per customer, average basket value, all dynamically filtered by segment
Treemap — visual distribution of customers across RFM segments
Top 5 customers by sales — updates dynamically based on selected segment
Stacked column chart — coupon usage (active vs non-active) per segment

**Tools**

PostgreSQL — data loading, cleaning, EDA, RFM calculation
Power BI — interactive dashboard and visualization

**Files**

rfm_analysis.sql — all SQL queries including EDA, RFM scoring, and table creation

dunnhumby_dashboard.pbix — Power BI dashboard file

Author
Darin 
[LinkedIn](https://www.linkedin.com/in/dareen-abd-alkhak-4ab204197)
