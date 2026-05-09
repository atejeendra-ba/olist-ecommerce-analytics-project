CREATE DATABASE olist_project;
USE olist_project;

SELECT * FROM customers LIMIT 10;
SELECT * FROM orders LIMIT 10;
SELECT * FROM order_items LIMIT 10;
SELECT * FROM order_payments LIMIT 10;
SELECT * FROM order_reviews LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM sellers LIMIT 10;

-- Check total orders
SELECT COUNT(*) AS total_orders
FROM orders;

-- Check total customers
SELECT COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers;

-- How many orders does a real customer place?

SELECT 
	c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id;

-- How many customers placed more than 1 order?

SELECT
	COUNT(*) AS repeat_customers
FROM (
	SELECT
		c.customer_unique_id
	FROM customers c 
	INNER JOIN orders o ON o.customer_id = c.customer_id
	GROUP BY c.customer_unique_id
	HAVING COUNT(o.order_id) > 1
) AS t;

-- Find top 5 customers who placed the most orders

SELECT
	c.customer_unique_id,
    COUNT(o.order_id) AS most_orders
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
ORDER BY most_orders DESC
LIMIT 5;

-- Which states have the highest number of orders?

SELECT
	c.customer_state,
    COUNT(o.order_id) AS total_orders
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;

-- Time-Based Analysis

-- How many orders are placed each month?

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS monthly,
    COUNT(o.order_id) AS total_orders
FROM orders o
GROUP BY monthly
ORDER BY monthly ASC;

-- What is the total revenue generated?

SELECT
	ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi;

-- Which product categories generate the highest revenue?

SELECT
	p.product_category_name,
    ROUND(SUM(oi.price),2) AS total_revenue
FROM products p
INNER JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;

--  imported category_translation table faced BOM(Byte Order Mark) fails when we join tables. therefore, rename the table.

ALTER TABLE category_translation
RENAME COLUMN `ï»¿product_category_name` TO product_category_name;

-- Revenue by product category (in English)

SELECT
	ct.product_category_name_english,
    ROUND(SUM(oi.price),2) AS total_revenue
FROM category_translation ct
INNER JOIN products p ON p.product_category_name = ct.product_category_name
INNER JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY ct.product_category_name_english
ORDER BY total_revenue DESC;

-- Top 5 customers by revenue

SELECT
	c.customer_unique_id,
    ROUND(SUM(oi.price),2) AS total_revenue
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_unique_id
ORDER BY total_revenue DESC
LIMIT 5;

-- Average order value (AOV)?
-- Average money per order
-- Total revenue / total number of orders

SELECT
	ROUND(SUM(oi.price) / COUNT(DISTINCT oi.order_id),2) AS aov_order
FROM order_items oi;

-- How many customers are one-time vs repeat customers?
SELECT
	CASE
		WHEN total_orders = 1 THEN 'one-time'
        ELSE 'repeat'
        END AS customer_type,
        COUNT(*) AS total_customers
FROM (
SELECT
	c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
) AS t
GROUP BY customer_type;

-- What % of customers are repeat customers?

SELECT
	ROUND(100.0 * COUNT(CASE WHEN total_orders > 1 THEN 1 END) / COUNT(*),2) AS repeat_customer_percentage
FROM (
-- repeated customers
SELECT
	c.customer_unique_id,
    COUNT(*) AS total_orders
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
) AS t;
	
-- How many orders are placed each month?

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS monthly_orders,
    COUNT(o.order_id) AS total_orders
FROM orders o
GROUP BY monthly_orders
ORDER BY monthly_orders;

-- What is the monthly revenue trend?

SELECT
	DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS monthly,
    ROUND(SUM(oi.price),2) AS revenue
FROM orders o
INNER JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY monthly
ORDER BY monthly;

-- What is the month-over-month (MoM) growth in revenue?

SELECT
	order_date,
    revenue,
    LAG(revenue) OVER (ORDER BY order_date) AS prev_month_revenue,
    ROUND(
    (revenue - LAG(revenue) OVER (ORDER BY order_date))
    / LAG(revenue) OVER (ORDER BY order_date) * 100
    ,2) AS mom_growth_percentage
FROM (
SELECT
	DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_date,
	ROUND(SUM(oi.price),2) AS revenue
FROM orders o
INNER JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY order_date
) AS t;

-- Top products contributing to revenue (with % contribution)

SELECT
	t.product_category_name_english,
    t.revenue,
	ROUND((t.revenue / SUM(t.revenue) OVER ()) * 100,2) AS contribution
FROM (
SELECT
	ct.product_category_name_english,
    ROUND(SUM(oi.price),2) AS revenue
FROM products p
INNER JOIN order_items oi ON oi.product_id = p.product_id
INNER JOIN category_translation ct ON ct.product_category_name = p.product_category_name
GROUP BY ct.product_category_name_english
) AS t
ORDER BY t.revenue DESC;

SELECT * FROM customers;
SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM order_payments;
SELECT * FROM order_reviews;
SELECT * FROM products;
SELECT * FROM sellers;
SELECT * FROM category_translation;