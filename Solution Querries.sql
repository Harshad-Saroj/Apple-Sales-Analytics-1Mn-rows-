-- Apple Sales Project - 1M rows sales dataset
CREATE DATABASE apple_db;
select * from category;
select * from stores;
select * from products;
select * from sales;
select * from warranty;

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE store_id = 'ST-31';

-- “Optimized query performance by creating appropriate indexes, reducing execution time from 0.297s to 0.172s.”

CREATE INDEX sales_store_id ON sales(store_id);
CREATE INDEX sales_sale_date ON sales(sale_date);
CREATE INDEX sales_product_id ON sales(product_id);

-- Buissness Problems

-- 1. Find the number of stores in each country
SELECT country, COUNT(store_id) AS total_stores
FROM stores
GROUP BY 1
ORDER BY 2 DESC;

-- 2. Calculate the total number of units sold by each store
SELECT 
	s.store_id,
    st.store_name,
    SUM(s.quantity) as total_units_sold
FROM sales as s
JOIN stores as st
ON st.store_id = s.store_id
GROUP BY 1, 2
ORDER BY 3 DESC;

-- How many sales occured in 2023.
SELECT COUNT(sale_id) as total_sale
FROM sales
WHERE YEAR(sale_date) = '2023' 
AND MONTH(sale_date) = '12';

-- Determine how many stores have never had a warranty claim filed.
SELECT COUNT(*) 
FROM stores
WHERE store_id NOT IN ( SELECT DISTINCT store_id
						FROM sales AS s
						RIGHT JOIN warranty AS w
						ON s.sale_id = w.sale_id);
-- 5. Calculate the percentage of warranty claims marked as "Pending"
SELECT 
   ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM warranty), 2) AS pending_percentage
FROM warranty
WHERE repair_status = 'Pending';

-- 6. Identify which store had the highest total units sold in the last year
SELECT 
	S.store_id,
    ST.store_name,
    SUM(S.quantity)
FROM sales AS S
JOIN stores AS ST
ON S.store_id = ST.store_id
WHERE sale_date >= (CURRENT_DATE - INTERVAL 1 YEAR)
GROUP BY 1 , 2
ORDER BY 3 DESC
LIMIT 1;

-- 7. Count the number of unique products sold in the last year
SELECT 
    COUNT(DISTINCT product_id)
FROM sales
WHERE sale_date >= (CURRENT_DATE - INTERVAL 1 YEAR);

-- 8. Find the average price of products in each category.
select * from category;
select * from sales;
select * from products;
SELECT 
	P.category_id, 
    C.category_name,
    ROUND(AVG(P.price), 2) AS average_price
FROM products AS P
JOIN category AS C
ON P.category_id = C.category_id
GROUP BY 1,2
ORDER BY 3 DESC;

-- 9. How many warranty claims were filed in 2024
SELECT COUNT(*) AS total_warranty_claims
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2024;

-- 10. For each store , identify the best-selling day based on highest quantity sold
SELECT *
FROM (SELECT
		store_id,
		DAYNAME(sale_date) as day_name,
		SUM(quantity) AS total_unit_sold,
		DENSE_RANK() OVER (PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS rnk
	FROM sales
	GROUP BY 1, 2) AS TEMP
WHERE rnk = 1;

-- 11. Identify the least selling product in each country for each year based on total units sold.
WITH product_rank AS (
	SELECT 
			product_name, 
			country, 
			SUM(quantity) AS total_units_sold,
			DENSE_RANK() OVER (PARTITION BY country ORDER BY SUM(quantity)) AS rnk
	FROM sales AS SL
	JOIN stores AS S 
		ON SL.store_id = S.store_id
	JOIN products AS P
		ON P.product_id = SL.product_id
	GROUP BY 1, 2)
SELECT 
	product_name AS least_sold_product,
    country, 
    total_units_sold AS least_units_sold
FROM product_rank
WHERE rnk = 1;

-- 12. Calculate how many warranty claims were filed within 180 days of a product sale.
SELECT COUNT(*) AS claims
FROM warranty AS W 
LEFT JOIN sales AS S
	ON S.sale_id = W.sale_id
WHERE DATEDIFF(claim_date, sale_date) < 180;

-- 13. Determine how many warranty claims were filed for the products launched in last two years.
SELECT 
	P.product_name,
    COUNT(W.claim_id) AS total_claims,
    COUNT(S.sale_id) AS total_sales
FROM warranty AS W
RIGHT JOIN sales AS S
ON S.sale_id = W.sale_id
JOIN products AS P 
ON P.product_id = S.product_id
WHERE p.launch_date >= DATE_SUB(CURDATE(), INTERVAL 2 YEAR)
GROUP BY 1
HAVING COUNT(W.claim_id) > 0;

-- 14. List the months in the last three years where sales exceeded 5,000 units in the USA.
SELECT 
	YEAR(sale_date) AS sale_year,
    MONTH(sale_date) AS sale_month,
    SUM(quantity) AS sold_units
FROM sales AS S
JOIN stores AS ST
ON S.store_id = ST.store_id
WHERE 
	  ST.country = 'United States'
	  AND sale_date >= DATE_SUB(CURDATE(), INTERVAL 3 YEAR)
GROUP BY YEAR(sale_date), MONTH(sale_date)
HAVING SUM(quantity) > 5000
ORDER BY YEAR(sale_date), MONTH(sale_date);

-- 15. Identify the product category with the most warranty claims filed in the last two yeards
SELECT 
	P.category_id,
    C.category_name,
    COUNT(W.claim_id) AS total_claims
FROM warranty AS W
LEFT JOIN sales AS S
ON W.sale_id = S.sale_id
JOIN products AS P 
ON S.product_id = P.product_id 
JOIN category AS C
ON P.category_id = C.category_id
WHERE W.claim_date > DATE_SUB(CURDATE(), INTERVAL 2 YEAR)
GROUP BY 1
ORDER BY 3 DESC
;

-- 16. Determine the percentage chance of receiving warranty claims after each purchase for each country. 
SELECT 
	country,
    total_units_sold,
    total_claims,
    COALESCE(total_claims* 100.0/total_units_sold , 0) AS risk_percentage
FROM (
	SELECT 
		ST.country,
        SUM(S.quantity) AS total_units_sold,
        COUNT(W.claim_id) AS total_claims
	FROM sales AS S
    JOIN stores AS ST
    ON S.store_id = ST.store_id
    LEFT JOIN warranty AS W
    ON W.sale_id = S.sale_id
    GROUP BY 1) AS t1
ORDER BY 4 DESC;

-- 17. Analyze the year-by-year growth ration for each store
WITH yearly_sales AS (
	SELECT 
		S.store_id,
        ST.store_name,
        YEAR(sale_date) AS sale_year,
        SUM(S.quantity*P.price) AS total_sales
	FROM sales AS S
    JOIN products AS P
    ON S.product_id = P.product_id
    JOIN stores AS ST 
    ON ST.store_id = S.store_id
    GROUP BY 1, 2, 3
    ORDER BY 2, 3),
growth_ratio AS (
	SELECT 
		store_name,
		sale_year,
		LAG(total_sales, 1) OVER (PARTITION BY store_name ORDER BY sale_year) AS last_year_sales,
		total_sales AS current_year_sales
	FROM yearly_sales)
SELECT 
	store_name,
    sale_year,
    last_year_sales,
    current_year_sales,
    ROUND(((current_year_sales - last_year_sales)*100/last_year_sales), 2) AS growth_ratio
FROM growth_ratio
WHERE last_year_sales IS NOT NULL
	  AND sale_year <> YEAR(CURDATE());
	
-- 18. Calculate the correlation between product price and warranty claims for products sold in the last fice years, segmented by price range. 
SELECT 
	CASE 
		WHEN P.price < 500 THEN 'Less Expensive Product'
        WHEN P.price BETWEEN 500 AND 1000 THEN 'Mid Range Product'
        ELSE 'Expensive'
        END AS price_segment,
        COUNT(W.claim_id) AS total_claims
FROM warranty AS W
LEFT JOIN sales AS S
ON W.sale_id = S.sale_id
JOIN products AS P
ON P.product_id = S.product_id
WHERE claim_date >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR)
GROUP BY 1;

-- 19. Identify the store with the highest percentage of "Paid Repaired" claims relative to total claims filed. 
WITH completed_repair AS
(SELECT 
	S.store_id,
    COUNT(W.claim_id) AS repaired_claims
FROM sales AS S
RIGHT JOIN warranty AS W
ON W.sale_id = S.sale_id
WHERE W.repair_status = "Completed"
GROUP BY 1 ),
total_claims AS
(SELECT
	S.store_id,
    COUNT(W.claim_id) AS total_claims
FROM sales AS S
RIGHT JOIN warranty AS W
ON W.sale_id = S.sale_id
GROUP BY 1)

SELECT 
	TC.store_id,
    ST.store_name,
    PR.repaired_claims,
    TC.total_claims,
    ROUND(PR.repaired_claims*100.0/TC.total_claims, 2) AS percentage_completed_claims
FROM completed_repair AS PR
JOIN total_claims AS TC
JOIN stores AS ST
ON TC.store_id = ST.store_id
ON PR.store_id = TC.store_id;

-- 20. Write a query to calculate the monthly running total of sales for each store
WITH monthly_sales AS
(SELECT
	store_id,
    MONTH(sale_date) AS month,
    YEAR(sale_date) AS year,
    SUM(P.price*S.quantity) AS total_revenue
FROM sales AS S
JOIN products AS P
ON S.product_id = P.product_id
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3 )
 
SELECT 
	store_id,
    month,
    year,
    total_revenue,
    SUM(total_revenue) OVER (PARTITION BY store_id ORDER BY year, month) AS running_total
FROM monthly_sales;

-- 21. Analyze product sales trends over time, segmented into key periods: from launch to 6 month, 6-12 months, 12-18 months, 18+ months. 
SELECT 
	P.product_name,
    CASE
		WHEN S.sale_date BETWEEN P.launch_date AND DATE_ADD(P.launch_date, INTERVAL 6 MONTH) THEN '0-6 month' 
        WHEN S.sale_date BETWEEN DATE_ADD(P.launch_date, INTERVAL 6 MONTH) AND DATE_ADD(P.launch_date, INTERVAL 12 MONTH) THEN '6-12 month' 
        WHEN S.sale_date BETWEEN DATE_ADD(P.launch_date, INTERVAL 12 MONTH) AND DATE_ADD(P.launch_date, INTERVAL 18 MONTH) THEN '12-18 month' 
        ELSE '18+'
        END AS date_range,
        SUM(S.quantity) AS total_quantity_sold
FROM sales AS S
JOIN products AS P
ON S.product_id = P.product_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
        