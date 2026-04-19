-- Retetnion by first week

Create Table retention as 
With weeks as (
	Select Ceil(day_num::float/7) as week_num, 
	household_key
	From transaction_data
	Group By Ceil(day_num::float/7), household_key
	Order By week_num asc
),
cohorts as ( 
	Select Min(week_num) as first_week, household_key
	From weeks
	Group by household_key
),
id_week as(
Select c.household_key, c.first_week, 
	w.week_num as active_week, 
	w.week_num - c.first_week as weeks_left
From cohorts c
Join weeks w ON c.household_key = w.household_key
),
f_week as ( 
	Select first_week,
	 Count (Distinct household_key) as coh_first_week
	From id_week
	Group By first_week
)
Select Count(ids.household_key) as cus_count, 
	ids.first_week, 
	ids.active_week, 
	Round(100.0 * COUNT(ids.household_key) / coh.coh_first_week ,2) as ret
From id_week ids
Join f_week f ON f.first_week = ids.first_week
GROUP BY ids.first_week, ids.active_week, f.coh_first_week


-- retention by department by weeks
-- canceled out the departments with less than 500 customers, bcz retention might be weird
Create Table retention_by_department
With dep as (
	Select Count ( Distinct household_key) as unique_cus,
		department
	From product prod
	Left Join transaction_data trans ON prod.product_id = trans.product_id
	Group BY department
	Having Count ( Distinct household_key) > 500
),
weeks as (
	Select Ceil(trans.day_num::Float/7) as week_num,
		trans.household_key, dep.department 
	From transaction_data trans
	Join product prod ON prod.product_id = trans.product_id
	Inner Join dep dep ON dep.department = prod.department
	Group By trans.household_key, Ceil(trans.day_num::Float/7), dep.department
),
cohorts as ( 
    Select Min(week_num) as first_week, household_key, department
    From weeks
    Group by household_key, department
),
id_week  as (
	Select w.household_key, 
		w.department,
		c.first_week,
		w.week_num as active_week, 
		w.week_num - c.first_week as week_left
	From weeks w
	Join cohorts c ON w.household_key = c.household_key
					AND w.department = c.department
),
coh_week as (
	 Select department, first_week,
	 	Count(Distinct household_key) as coh_first_week
	 From id_week
	 Group By first_week, department
)
Select ids.department, Count(ids.household_key) as cus_count,
	ids.first_week, ids.active_week,
	Round(100.0 * COUNT(ids.household_key) / coh.coh_first_week ,2) as ret
From id_week ids 
Join coh_week coh ON ids.first_week = coh.first_week
				AND ids.department = coh.department
Group By ids.department, ids.first_week, ids.active_week, coh.coh_first_week
Order By first_week

--Average retention each week. Where is the decay curve?

Select active_week - first_week as week, Round(avg(ret)::numeric, 2)
From retention
Group By active_week - first_week
Order By week asc

-- Week 1 — steep drop from 100% to 62.5%
-- Week 2 onwards — it stabilizes roughly between 55% and 62%

-- let's look at the department level retention

Select department, 
	Round(Avg(ret)::Numeric, 2) as ret, 
	sum(cus_count) as cus_count
From retention_by_department
WHERE active_week - first_week = 1
Group By department
Order By ret, cus_count

-- Grocery has the highest retention
-- Cosmetics has the highest churn









