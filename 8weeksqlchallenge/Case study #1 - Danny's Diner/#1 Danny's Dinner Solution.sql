/* --------------------
   Case Study Questions
   --------------------*/
-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id,
	SUM(m.price) as total_sales
FROM  dannys_diner.sales as s
LEFT JOIN dannys_diner.menu as m 
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT s.customer_id,
	COUNT(DISTINCT order_date) AS visit_count
FROM  dannys_diner.sales as s
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH firstPurchase AS (
    SELECT s.customer_id,
	s.product_id,
	s.order_date,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as rn
    FROM dannys_diner.sales as s
)
SELECT fp.customer_id,  m.product_name as item
FROM firstPurchase as fp
LEFT JOIN dannys_diner.menu as m 
    ON fp.product_id = m.product_id 
WHERE fp.rn = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name AS most_purchased_item,
       count(s.product_id) AS order_count
FROM dannys_diner.menu as m
INNER JOIN dannys_diner.sales as s ON m.product_id = s.product_id
GROUP BY product_name
ORDER BY order_count DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH purchase_counts AS (
    SELECT
        s.customer_id,
        s.product_id,
        COUNT(s.product_id) as purchase_count,
		DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY  COUNT(s.product_id) DESC) as rank
    FROM dannys_diner.sales as s
    GROUP BY s.customer_id, s.product_id
)
SELECT
    pc.customer_id,
    m.product_name as item,
    pc.purchase_count
FROM purchase_counts as pc
JOIN dannys_diner.menu as m
    ON pc.product_id = m.product_id
WHERE pc.rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH atDateMember AS (
	SELECT 
	s.customer_id,
	s.order_date,
	s.product_id,
	m.product_name,
	DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as rank
FROM dannys_diner.sales as s
LEFT JOIN dannys_diner.members AS mem 
	ON  s.customer_id = mem.customer_id
LEFT JOIN dannys_diner.menu AS m 
ON  s.product_id = m.product_id
WHERE join_date <= order_date
)
SELECT d.customer_id,
	d.order_date,
	d.product_name 
FROM atDateMember as d
WHERE rank = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH atDateMember AS (
	SELECT 
	s.customer_id,
	s.order_date,
	s.product_id,
	m.product_name,
	RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) as rank
	FROM dannys_diner.sales as s
LEFT JOIN dannys_diner.members AS mem 
ON  s.customer_id = mem.customer_id
LEFT JOIN dannys_diner.menu AS m 
ON  s.product_id = m.product_id
WHERE join_date > order_date
)
SELECT d.customer_id,
	d.product,
	d.order_date
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
WHERE mem.join_date > s.order_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
--- Assume total_points is only calculated after subcription
WITH points_calculation AS (
    SELECT
        s.customer_id,
        s.product_id,
		s.order_date,
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
LEFT JOIN dannys_diner.members as m
USING (customer_id)
WHERE m.join_date <= pc.order_date
GROUP BY pc.customer_id
ORDER BY total_points DESC;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
--- Assume total_points is only calculated after subcription
WITH points_calculation AS (
    SELECT
        s.customer_id,
        s.product_id,
		s.order_date,
		mem.join_date,
        m.product_name,
        m.price,
        CASE 
			WHEN s.order_date BETWEEN mem.join_date AND mem.join_date + interval '6 days' THEN m.price * 10 * 2
            WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
            ELSE m.price * 10
        END as points
    FROM dannys_diner.sales as s
    JOIN dannys_diner.menu as m
        ON s.product_id = m.product_id
	JOIN dannys_diner.members as mem 
		ON s.customer_id = mem.customer_id
)
SELECT 
    pc.customer_id,
    SUM(pc.points) as total_points
FROM points_calculation as pc
WHERE pc.order_date < '2021-02-01'
	AND pc.join_date <= pc.order_date
GROUP BY pc.customer_id
ORDER BY total_points DESC;

-- Bonus Questions
--- Join All The Things

SELECT customer_id, order_date, product_name, price,
    CASE WHEN order_date >= join_date
        THEN 'Y'
        ELSE 'N' END AS member
FROM sales 
LEFT JOIN menu
USING (product_id)
LEFT JOIN members
USING (customer_id)
ORDER BY customer_id, order_date;

-- Rank All The Things

SELECT customer_id, order_date, product_name, price, 
        CASE WHEN order_date < join_date THEN NULL
        ELSE RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) 
        END AS ranking
FROM (
    SELECT customer_id, order_date, join_date, product_name, price,
        CASE WHEN order_date >= join_date
            THEN 'Y'
            ELSE 'N' END AS member
    FROM sales 
    LEFT JOIN menu
    USING (product_id)
    LEFT JOIN members
    USING (customer_id)
    ORDER BY customer_id, order_date) AS subq;
