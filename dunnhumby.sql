CREATE TABLE transaction_data (
    household_key INTEGER,
    basket_id BIGINT,
    day INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    sales_value NUMERIC,
    store_id INTEGER,
    retail_disc NUMERIC,
    trans_time INTEGER,
    week_no SMALLINT,
    coupon_disc NUMERIC,
    coupon_match_disc NUMERIC
);

COPY transaction_data
FROM 'C:/Users/Acer/Downloads/dunnhumby/transaction_data.csv'
DELIMITER ','
CSV HEADER;


Create Table causal_data (
	product_id BIGINT,
	STORE_ID INTEGER,
	WEEK_NO INTEGER,
	display INTEGER,
	mailer varchar(20)
);

ALter table causal_data
alter column display type varchar(10);

COPY causal_data
FROM 'C:/Users/Acer/Downloads/dunnhumby/causal_data.csv'
DELIMITER ','
CSV HEADER;

--renaming columns to lowercase 

ALTER TABLE transaction_data 
RENAME COLUMN "BASKET_ID" TO basket_id;
ALTER TABLE transaction_data 
RENAME COLUMN "DAY" TO day_num;
ALTER TABLE transaction_data 
RENAME COLUMN "PRODUCT_ID" TO product_id;
ALTER TABLE transaction_data 
RENAME COLUMN "QUANTITY" TO quantity;
ALTER TABLE transaction_data 
RENAME COLUMN "SALES_VALUE" TO sales_value;
ALTER TABLE transaction_data 
RENAME COLUMN "STORE_ID" TO store_id;
ALTER TABLE transaction_data 
RENAME COLUMN "RETAIL_DISC" TO retail_disc;
ALTER TABLE transaction_data 
RENAME COLUMN "TRANS_TIME" TO trans_time;
ALTER TABLE transaction_data 
RENAME COLUMN "WEEK_NO" TO week_no;
ALTER TABLE transaction_data 
RENAME COLUMN "COUPON_DISC" TO coupon_disc;
ALTER TABLE transaction_data 
RENAME COLUMN "COUPON_MATCH_DISC" TO coupon_match_disc;

ALTER TABLE coupon RENAME COLUMN "COUPON_UPC" TO coupon_upc;
ALTER TABLE coupon RENAME COLUMN "PRODUCT_ID" TO product_id;
ALTER TABLE coupon RENAME COLUMN "CAMPAIGN" TO campaign;

ALTER TABLE coupon_redempt RENAME COLUMN "DAY" TO day_num;
ALTER TABLE coupon_redempt RENAME COLUMN "COUPON_UPC" TO coupon_upc;
ALTER TABLE coupon_redempt RENAME COLUMN "CAMPAIGN" TO campaign;

ALTER TABLE hh_demographic RENAME COLUMN "AGE_DESC" TO age_desc;
ALTER TABLE hh_demographic RENAME COLUMN "MARITAL_STATUS_CODE" TO marital_status_code;
ALTER TABLE hh_demographic RENAME COLUMN "INCOME_DESC" TO income_desc;
ALTER TABLE hh_demographic RENAME COLUMN "HOMEOWNER_DESC" TO homeowner_desc;
ALTER TABLE hh_demographic RENAME COLUMN "HH_COMP_DESC" TO hh_comp_desc;
ALTER TABLE hh_demographic RENAME COLUMN "HOUSEHOLD_SIZE_DESC" TO household_size_desc;
ALTER TABLE hh_demographic RENAME COLUMN "KID_CATEGORY_DESC" TO kid_category_desc;

ALTER TABLE product RENAME COLUMN "PRODUCT_ID" TO product_id;
ALTER TABLE product RENAME COLUMN "MANUFACTURER" TO manufacturer;
ALTER TABLE product RENAME COLUMN "DEPARTMENT" TO department;
ALTER TABLE product RENAME COLUMN "BRAND" TO brand;
ALTER TABLE product RENAME COLUMN "COMMODITY_DESC" TO commodity_desc;
ALTER TABLE product RENAME COLUMN "SUB_COMMODITY_DESC" TO sub_commodity_desc;
ALTER TABLE product RENAME COLUMN "CURR_SIZE_OF_PRODUCT" TO curr_size_of_product;


ALTER TABLE campaign_desc RENAME COLUMN "DESCRIPTION" TO description;
ALTER TABLE campaign_desc RENAME COLUMN "CAMPAIGN" TO campaign;
ALTER TABLE campaign_desc RENAME COLUMN "START_DAY" TO start_day;
ALTER TABLE campaign_desc RENAME COLUMN "END_DAY" TO end_day;

ALTER TABLE campaign_table RENAME COLUMN "DESCRIPTION" TO description;
ALTER TABLE campaign_table RENAME COLUMN "CAMPAIGN" TO campaign;

---------------


--Getting to know the data (transacation data)
Select count(distinct day_num) as day_num, 
	count(distinct household_key) as unique_customers,
	count(distinct product_id) as unique_products
From transaction_data;

-- Are there 0 sale baskets?
Select household_key, basket_id, Round(sum(sales_value)::Numeric ,2) as basket_value
From transaction_data
group by household_key, basket_id
order by basket_value asc
Limit 10

-- Why are the baskets empty?
Select sum(sales_value), coupon_disc, coupon_match_disc, retail_disc, 
	count(*) as row_count
From transaction_data 
Where sales_value = 0 
Group by coupon_disc, retail_disc, coupon_match_disc;

-- Deleting the Baskets with no value but keeping those that are 0 because of discounts
DELETE From transaction_data
Where  sales_value = 0 
	And coupon_disc = 0
	And retail_disc = 0
	And coupon_match_disc = 0

-- How many zero value baskets with discounts left?
SELECT COUNT(*) 
FROM (
    SELECT basket_id, ROUND(SUM(sales_value)::NUMERIC, 2) AS basket_value
    FROM transaction_data
    GROUP BY basket_id
) basket_summary
WHERE basket_value = 0;

-- Sum of each customer's revenue
Select household_key, Round(sum(sales_value)::Numeric ,2) as customer_value
From transaction_data
group by household_key
order by customer_value desc
Limit 10

-- Basket Sales 4Ms
Select Round(percentile_cont(0.5) 
	Within Group(Order By basket_value):: Numeric , 2) as median_basket_value,
	Round(AVG(basket_value),2)::Numeric as avg_basket_value, 
	Round(Min (basket_value), 2) as min_basket,
	Round (Max (basket_value), 2) as max_basket 
From (
	Select household_key, basket_id, Round(sum(sales_value)::Numeric ,2) as basket_value
	From transaction_data 
	Group by household_key, basket_id) basket_summary

-- Customer metrics

Select Distinct(household_key) as customer, Count(Distinct(basket_id)) as num_of_orders, 
		Round(Sum(sales_value):: Numeric ,2) as sales,
		Min(day_num) as first_day,
		Max(day_num) as last_day,
		Round(AVG(sales_value)::Numeric, 2) as average_sale
From transaction_data
Group by household_key
Order By sales desc, customer

-- Are customers spread across the whole time period or concentrated

With customer_span AS (
	Select household_key,
		Min(day_num) as first_day,
		Max(day_num) As last_day,
		(Max(day_num) - Min(day_num)) as span 
	From transaction_data
	Group by household_key
) 
Select 
	Round(percentile_cont(0.5) Within Group(Order By span):: Numeric , 2) as median_span, 
	Round(Avg(span):: Numeric,2) as avg_span
From customer_span

-- Building RFM
CREATE TABLE rfm_segments AS 
With
all_day AS (
	Select Max(day_num) as max_day
	From transaction_data
),
cus_lvl AS (
	Select household_key,
		Max(day_num) as re,
		Count(Distinct(basket_id)) as fr,
		Sum(sales_value) as mo
	From transaction_data
	Group by household_key
),
rfm_tab AS (
 Select household_key,
 		(all_day.max_day - re) AS r,
 		fr as f, mo as m
	From cus_lvl, all_day
),

rfm_score AS ( Select household_key, 
	6 - NTILE(5) Over (Order by r ASC) as r_score,
	6 - NTILE(5) Over (Order by f Desc) as f_score,
	6 - NTILE(5) Over (Order by m Desc) as m_score
From rfm_tab
)

Select household_key,
	Case 
		When r_score Between 4 AND 5 AND f_score = 5 AND m_score Between 4 AND 5 Then 'Champions'
		When r_score = 5 AND f_score Between 3 AND 4 AND m_score  Between 3 AND 5 Then 'Loyal Customers'
		When r_score Between 3 AND 4 AND f_score Between 2 AND 4 AND m_score Between 2 AND 5 Then 'Potential Loyalists'
		When r_score = 1 AND f_score Between 1 AND 3 AND m_score Between 1 AND 5 Then 'Hibernating'
		When r_score Between 2 AND 3 AND f_score Between 3 AND 4 AND m_score Between 1 AND 4 Then 'Risk'
		When r_score = 5 AND f_score = 1 AND m_score Between 1 AND 5 Then 'New Customers'
		When r_score Between 1 AND 3 AND f_score Between 4 AND 5 AND m_score Between 3 AND 5 Then 'Cant Lose Them'
		When r_score Between 2 AND 4 AND f_score Between 1 AND 2 ANd m_score Between 1 AND 3 Then 'About to Sleep'
		Else 'Other'
	End AS segments
From rfm_score


-- How many customers are there in each segement?

SELECT segments, COUNT(Distinct household_key) as customer_count
FROM rfm_segments
GROUP BY segments
ORDER BY customer_count DESC

-- I need to find the percentage of people that have used coupons in each segment

With coupon_data AS (
	Select s.segments,
		Count (Distinct s.household_key) Filter
				(Where t.coupon_disc <> 0  OR t.coupon_match_disc <> 0) as coupon_customers,
		Count (Distinct s.household_key) as customers
	From rfm_segments s
	Left Join transaction_data t On s.household_key = t.household_key
	Group By s.segments
	)

Select segments, customers, coupon_customers,
	Round (100.0 * coupon_customers/customers, 2) as coupon_per
From coupon_data
Order By customers desc

