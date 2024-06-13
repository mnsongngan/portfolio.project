/* --------------------
   Case Study Questions
   --------------------*/
-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id,
	SUM(m.price)
FROM  dannys_diner.sales as s
LEFT JOIN dannys_diner.menu as m 
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT s.customer_id,
	COUNT(DISTINCT order_date)
FROM  dannys_diner.sales as s
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH firstPurchase AS (
    SELECT s.customer_id, s.product_id, s.order_date,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as rn
    FROM dannys_diner.sales as s
)
SELECT fp.customer_id,  m.product_name as item
FROM firstPurchase as fp
JOIN dannys_diner.menu as m 
    ON fp.product_id = m.product_id 
WHERE fp.rn = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

WITH numProduct AS (
SELECT s.product_id,
	COUNT(*) as num
FROM dannys_diner.sales as s
GROUP BY s.product_id
ORDER BY num DESC
)
SELECT n.product_id, n.num
FROM numProduct as n
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH purchase_counts AS (
    SELECT
        s.customer_id,
        s.product_id,
        COUNT(*) as purchase_count
    FROM dannys_diner.sales as s
    GROUP BY s.customer_id, s.product_id
),
ranked_purchases AS (
    SELECT
        pc.customer_id,
        pc.product_id,
        pc.purchase_count,
        DENSE_RANK() OVER (PARTITION BY pc.customer_id ORDER BY pc.purchase_count DESC) as rank
    FROM purchase_counts as pc
)
SELECT
    rp.customer_id,
    m.product_name as item,
    rp.purchase_count
FROM ranked_purchases as rp
JOIN dannys_diner.menu as m
    ON rp.product_id = m.product_id
WHERE rp.rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH atDateMember AS (
	SELECT 
	s.customer_id,
	s.order_date,
	s.product_id,
	DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as rank
FROM dannys_diner.sales as s
LEFT JOIN dannys_diner.members AS mem 
ON  s.customer_id = mem.customer_id
WHERE join_date <= order_date
)
SELECT d.customer_id,
	d.order_date,
	d.product_id 
FROM atDateMember as d
WHERE rank = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH atDateMember AS (
	SELECT 
	s.customer_id,
	s.order_date,
	s.product_id,
	RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) as rank,
	COUNT() OVER (PARTITION BY s.product_id ORDER BY s.order_date DESC) as total_item
FROM dannys_diner.sales as s
LEFT JOIN dannys_diner.members AS mem 
ON  s.customer_id = mem.customer_id
WHERE join_date > order_date
)
SELECT d.customer_id,
	d.order_date,
	d.product_id 
FROM atDateMember as d
WHERE rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
	s.customer_id,
	COUNT(s.product_id) as total_item,
	SUM(m.price) as spent	
FROM dannys_diner.sales as s
LEFT JOIN dannys_diner.members AS mem 
ON  s.customer_id = mem.customer_id
LEFT JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
WHERE mem.join_date <= s.order_date
GROUP BY s.customer_id, s.product_id, m.price
ORDER BY s.customer_id, s.product_id, m.price;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH points_calculation AS (
    SELECT
        s.customer_id,
        s.product_id,
        m.product_name,
        m.price,
        CASE
            WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
            ELSE m.price * 10
        END as points
    FROM dannys_diner.sales as s
    JOIN dannys_diner.menu as m
        ON s.product_id = m.product_id
)
SELECT 
    pc.customer_id,
    SUM(pc.points) as total_points
FROM points_calculation as pc
GROUP BY pc.customer_id
ORDER BY total_points;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
