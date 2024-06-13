
-- Creat order table 
CREATE TABLE public.orders (
    order_no VARCHAR ,
    order_date DATE,
    customer_name VARCHAR(255),
    address TEXT,
    city VARCHAR(255),
    state VARCHAR(255),
    customer_type VARCHAR(255),
    account_id INT,
    order_priority VARCHAR(255),
    product_id INT,
    product_container VARCHAR(255),
    ship_mode VARCHAR(255),
    ship_date DATE,
    cost_price NUMERIC(10, 2),
    retail_price NUMERIC(10, 2),
    order_quantity INT,
    sub_total NUMERIC(10, 2),
    discount_percent NUMERIC(5, 2),
    discount_dollar NUMERIC(10, 2),
    order_total NUMERIC(10, 2),
    shipping_cost NUMERIC(10, 2),
    total NUMERIC(10, 2)
);
-- Overview of data
select * from orders;
-- describe data
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_name = 'orders';

--> Same check for products and account_managers, they have been ready to explore

--Data cleaning for orders
SELECT COUNT(*)
FROM orders
WHERE order_no IS NULL;

--Checking for duplicates
SELECT order_no, COUNT(order_no)
FROM orders
GROUP BY order_no
HAVING COUNT(order_no)>1;
-- Check if it is an actual duplicate
SELECT * 
FROM orders
WHERE order_no = '5768-2'or order_no= '6159-2';
--checking product
SELECT COUNT(*)
FROM products
WHERE product_id IS NULL;
SELECT product_id, COUNT(product_id)
FROM products
GROUP BY product_id
HAVING COUNT(product_id)>1;
--checking account_managers

-- 1. What is the total revenue generated by each product category?
SELECT p.product_category,
	ROUND(SUM(total),2) AS Revenue
FROM orders o
JOIN products p
ON p.product_id = o.product_id
GROUP BY p.product_category

-- 2.How many unique products have been ordered?
SELECT COUNT(DISTINCT product_name) AS unique_product
FROM products;
-- 3. What is the total revenue generated each year?
SELECT EXTRACT(YEAR FROM order_date) AS Year,
	SUM(total) as Revenue_year
FROM orders
GROUP BY Year
ORDER BY Year;
-- 4. What is the date of the latest and earliest order?
SELECT 
    MIN(order_date) AS earliest_date,
    MAX(order_date) AS latest_date
FROM orders;

-- 6. What product category has the lowest average price of products?
SELECT product_category,
	ROUND(AVG(retail_price), 2) Average_price
FROM orders
JOIN products
USING(product_id)
GROUP BY product_category
ORDER BY Average_price
LIMIT 1;
-- 7. What are the top 10 highest performing products?
SELECT p.product_name,
sum(total) as revenue
FROM orders o
JOIN products p on p.product_id = o.product_id
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 10;
-- 8. Show the total revenue and profit generated by each account_manager?
SELECT a.account_manager, 
SUM(total) as revenue,
SUM(total) - SUM(cost_price) as profit
FROM orders
JOIN account_managers a
USING(account_id)
GROUP BY a.account_manager;
--  9. What is the name, city and account manager of the highest selling product in 2017?
SELECT product_name,
	city,
	account_manager,
	SUM(total) as revenue
FROM orders
JOIN account_managers as a
USING(account_id)
JOIN products USING (product_id)
WHERE EXTRACT(YEAR FROM order_date)=2017
GROUP BY product_name,
	city,
	account_manager
ORDER BY revenue DESC
LIMIT 1;
-- 10. Find the mean amount spent per order by each Customer type?
SELECT customer_type,
	AVG(total) 
FROM orders
GROUP BY customer_type;

-- 11. What is the 5th highest selling product? 
WITH ranked_products AS (
    SELECT
        product_id,
        SUM(total) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(total) DESC) AS rank
    FROM orders
    GROUP BY product_id
)
SELECT
    product_id
FROM ranked_products
WHERE rank = 5;
