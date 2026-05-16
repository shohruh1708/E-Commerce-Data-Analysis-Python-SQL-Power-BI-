

-- First checking and getting to know the data, to understand the key points
-- so to be able to answer to business questions


select * from Cleaned

select count(*) from Cleaned

select count(distinct customer_id) from Cleaned

select count(distinct order_id) from Cleaned

select distinct country from Cleaned

select distinct category from Cleaned

select distinct segment from Cleaned

select distinct region from Cleaned

select distinct ship_mode from Cleaned

select count(distinct product_name) from Cleaned
select count(distinct product_id) from Cleaned
select SUM(profit) from Cleaned
select SUM(sales) from Cleaned



                      -- Sales Analysis

-- 1. What are the total sales and total profit?

select 
	ROUND(SUM(sales),0) as total_sales, 
	ROUND(SUM(profit), 0) as total_profit
from Cleaned


-- 2. Which region generates the highest sales?


;WITH BY_REGION AS
(
	SELECT 
		region, 
		SUM(sales) as Total_sales_region
	FROM Cleaned
	GROUP BY region
), Tot_sales as 
(
SELECT *,
	SUM(Total_sales_region) over () AS Total_sales
FROM BY_REGION
)
SELECT *, 
	round(Total_sales_region * 1.0 /Total_sales * 100,1) as perc_of_sales
FROM Tot_sales
order by perc_of_sales desc


-- As can be seen West and East are making the most of the sales 
--nearly 60% of total, where Central and South is followed





--3. Which top 10 products generate the most revenue?


;with revenue as
(
SELECT 
	product_name,
	SUM(sales) as revenue
FROM Cleaned
group by product_name
), ranking as
(
select *, 
	ROW_NUMBER() over (order by revenue desc) as rn 
from revenue
)
select * from ranking 
where rn <=10

--where Canon Advanced Copier lead the sales 

-- 4. Which categories are the most profitable ?

;with cat_prof as
(
SELECT 
	category,
	SUM(profit) as category_profit
FROM Cleaned
group by category
), perc as
(
select *,
	SUM(category_profit) over () as total_rev
from cat_prof
)
select *, 
	round(category_profit / total_rev * 100,1) as perc_share
from perc
order by perc_share desc

-- As can be noticed that Technology category is leading with nearly 
--half of the revenue 51 % and Office Supplies followed by 43% 
--with smallest share goes to Furnitue only around 6 %



					-- Customer Analysis

--5. Which customers spent the most money, 
--which customers were most profitable?

SELECT 	top 10
	customer_name,
	SUM(sales) as total_spent, 
	SUM(profit) as cust_profit
FROM Cleaned
group by customer_name
order by total_spent desc

-- it seems like most spenders doesnt mean they are profitable, 
--in fact it could be quite the opposite, and have negative impact.  
-- The most spenders has lost money for the company 
--instead of earning profit.


SELECT 	top 10
	customer_name,
	SUM(sales) as total_spent, 
	SUM(profit) as cust_profit
FROM Cleaned
group by customer_name
order by cust_profit desc

-- Above is the top 10 most profitable customers 


;With spent as
(
SELECT *, 
	SUM(sales) over (partition by customer_id) as total_spent,
	SUM(profit) over (partition by customer_id) as cust_profit
FROM Cleaned
), ranking as
(
select *, 
	DENSE_RANK() over 
		(order by total_spent desc) as rank_spent,
	DENSE_RANK() over 
		(order by cust_profit desc) as rank_profit
from spent
), margin as
(
select *, round(cust_profit* 1.0/ total_spent *100,0) as profit_margin
from ranking
)
select 
	distinct customer_name, total_spent, cust_profit, profit_margin
from margin
order by profit_margin desc


-- above is the top profitable customers by margin


-- 6. Which customer segment is the most profitable?


;with segment_total as
(
	SELECT 
		segment, 
		ROUND(SUM(sales),2) as Total_per_segment
	FROM Cleaned
	group by segment
), tot_rev as 
(
select *,
	SUM(Total_per_segment) over () as total_rev
from segment_total
) 
select *,	
	Total_per_segment / total_rev * 100 as perct_share
from tot_rev
order by perct_share desc



-- consumer segment is taking the half of the total revenue and becoming the 
-- most profitable segment, followed by corporate 30 % and last Home Office with 18 %



-- 7. Find repeat customers (customers with multiple orders)


;with order_num as
	(
	SELECT 	
		customer_name,
		count(distinct order_id) as total_orders
	FROM Cleaned
	group by customer_name
	), ranking as
	(
select *, 
	DENSE_RANK() over (order by total_orders desc) as rn
from order_num
	) 
	select count(*) as customers from ranking
	where rn <= 5

-- Above is the top 5 total order numbers which was done by 88 customers, 





				-- Product & Discount Analysis

-- 8. Which products have negative and positive profit, and percentage margin?


SELECT 
	product_name, 
	round(SUM(profit),2) as tot_profit
FROM Cleaned
group by product_name
having SUM(profit) > 0
order by tot_profit desc

-- Again Canon Advanced Copier is the most profitable product by total profit
-- which is 25200 $

SELECT 
	product_name, 
	round(SUM(profit),2) as tot_profit
FROM Cleaned
group by product_name
having SUM(profit) < 0
order by tot_profit


-- it turns out that Cubify CubeX 3D Printer 
--has the most negative profit around -8900 $ followed by Lexmark with - 4600$ loss of profit


;with act_cost as
(
	SELECT *, 
		sales - profit as actual_cost 
	FROM Cleaned
	where discount = 0
), margin as
(
select *,
	round(profit/actual_cost * 100,0) as margin_pers
from act_cost
)
select 
	product_name, 
	sales, 
	profit,
	margin_pers
from margin 
where margin_pers = 100

-- 53 products makes 100 margin profit from the sale, 
--it means if actual cost is 100 sale price is 200




-- 9. Does higher discount reduce profit?


SELECT 
    discount,
    AVG(profit) AS avg_profit
FROM Cleaned
GROUP BY discount
ORDER BY discount

-- Yes it does, average discounts above 30 % it results on loss of profit




-- 10. Which sub-categories receive the highest average discount?


SELECT 
	[sub-category], 
	AVG(discount) as avg_discount
FROM Cleaned
group by [sub-category]
order by avg_discount desc

-- binders and mashine subcategories tent to receive discount above 30 % 
--which results on loss




					-- Time Analysis

-- 11. Monthly sales trend


SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    SUM(sales) AS monthly_sales
FROM Cleaned
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year, month



-- 12. Which month had the highest profit?

;with monthly_prof as
(
	select 
		MONTH(order_date) as months,
		SUM(profit) as monthly_profit
	from Cleaned
	group by MONTH(order_date)
), perc_share as
(
select *, 
	SUM(monthly_profit) over () as total_profit
from monthly_prof
)
select *, 
	round(monthly_profit / total_profit * 100,1) as percentage_share
from perc_share
order by percentage_share desc


-- Last quater seems to have the highest profit share with 52% time of the year 
-- leading with december 15% due to Christmas Eve and holidays



-- 13. Average shipping time by ship mode


select 
	ship_mode, 
	AVG(DATEDIFF(DAY, order_date, ship_date)) as avg_shipping_days
from Cleaned
group by ship_mode
order by avg_shipping_days


-- Second Class and Standard Class shipping modes are taking between 3-5 days
-- the quickest are Same Day and First Class up to 2 days, but normally same day shipping


-- 14. Which states generate losses?


select 
	state, 
	SUM(profit) as total_profit_state
from Cleaned
group by state
having SUM(profit) < 0
order by total_profit_state 


-- Unfortunately Texas with - 26,000 $and Ohio with - 17000 $ 
-- have experiences the most lost with no profit


-- 15. Top 3 products by sales in each category


;with top_3 as 
(
	select 
		category, 
		product_name,
		SUM(sales) as total_sales, 
		ROW_NUMBER() over
			(partition by category order by SUM(sales) desc) as rn
	from Cleaned
	group by category, product_name
)
select * from top_3
where rn <=3


--- HON 5400 Chair is leading on sales on Furniture category, 
-- Fellowes Electric Plactic Comb on Office Suppliers category
-- Canon Advanced copier on Technology category 

