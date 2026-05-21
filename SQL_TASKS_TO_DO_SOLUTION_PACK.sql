--SQL_TASK_TO_DO_SOLUTION_PACKS


-- PHASE 1 — EXPLORATORY ANALYSIS

	--1. Total Revenue


SELECT ROUND(SUM(order_amount),2) AS total_revenue
FROM orders;

--Output: Returns total business revenue.


	--2. Total Orders Per City

SELECT r.city,
       COUNT(o.order_id) AS total_orders
FROM orders o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY total_orders DESC;

-- Output: Shows city-wise order count.

--3. Top 10 Customers by Spending

SELECT c.customer_id,
       c.name,
       ROUND(SUM(o.order_amount),2) AS total_spent
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC
LIMIT 10;


--Output: Top 10 highest spending customers.

--  PHASE 2 — CUSTOMER SEGMENTATION


	--Customer Category (Gold / Silver / Bronze)

WITH customer_spending AS (
    SELECT c.customer_id,
           c.name,
           ROUND(SUM(o.order_amount),2) AS total_spent
    FROM customers c
    JOIN orders o
    ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name
)

SELECT customer_id,
       name,
       total_spent,
       CASE
           WHEN total_spent >= 1500 THEN 'Gold'
           WHEN total_spent >= 500 THEN 'Silver'
           ELSE 'Bronze'
       END AS customer_category
FROM customer_spending
ORDER BY total_spent DESC;

-- PHASE 3 — RESTAURANT PERFORMANCE

	--1. Top 10 Restaurants by Revenue

SELECT r.restaurant_name,
       ROUND(SUM(o.order_amount),2) AS total_revenue
FROM restaurants r
JOIN orders o
ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_name
ORDER BY total_revenue DESC
LIMIT 10;


--Output:

Top 10 revenue-generating restaurants.

--2. Average Rating vs Revenue

SELECT r.restaurant_name,
       r.rating,
       ROUND(SUM(o.order_amount),2) AS revenue
FROM restaurants r
JOIN orders o
ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_name, r.rating
ORDER BY revenue DESC;

-- Output: Shows relationship between rating and revenue.


	--PHASE 3 BONUS (recommended for dashboard)

--Revenue by Cuisine

SELECT cuisine,
       ROUND(SUM(o.order_amount),2) AS revenue
FROM restaurants r
JOIN orders o
ON r.restaurant_id = o.restaurant_id
GROUP BY cuisine
ORDER BY revenue DESC;

--PHASE 4 — DELIVERY ANALYSIS

--1. Average Delivery Time Per City

SELECT r.city,
       ROUND(AVG(o.delivery_time),2) AS avg_delivery_time
FROM orders o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY avg_delivery_time DESC;

--Output: Shows average delivery time city-wise.

--2. Late Deliveries (Above 45 Minutes)

SELECT order_id,
       customer_id,
       restaurant_id,
       delivery_time
FROM orders
WHERE delivery_time > 45
ORDER BY delivery_time DESC;

--Output: Identifies delayed orders.


	--PHASE 5 — PAYMENT & DISCOUNT ANALYSIS

--1. Payment Method Distribution

SELECT payment_method,
       COUNT(*) AS total_orders,
       ROUND(SUM(order_amount),2) AS revenue
FROM orders
GROUP BY payment_method
ORDER BY total_orders DESC;

--Output: Shows payment preference distribution

--2. Discount Impact on Revenue

SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 50 THEN 'Low Discount'
        ELSE 'High Discount'
    END AS discount_category,

    COUNT(*) AS total_orders,
    ROUND(SUM(order_amount),2) AS total_revenue
FROM orders
GROUP BY discount_category
ORDER BY total_revenue DESC;

--Output: Shows how discount affects revenue


	--PHASE 6 — ADVANCED SQL

--1. Monthly Revenue Using CTE

WITH monthly_revenue AS (
    SELECT TO_CHAR(order_date,'Month') AS month,
           ROUND(SUM(order_amount),2) AS revenue
    FROM orders
    GROUP BY TO_CHAR(order_date,'Month')
)

SELECT *
FROM monthly_revenue
ORDER BY revenue DESC;

--Uses: CTE and Aggregation

--2. Rank Restaurants by Revenue (Window Function)

SELECT restaurant_name,
       total_revenue,
       RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM (
    SELECT r.restaurant_name,
           ROUND(SUM(o.order_amount),2) AS total_revenue
    FROM restaurants r
    JOIN orders o
    ON r.restaurant_id = o.restaurant_id
    GROUP BY r.restaurant_name
) ranked_restaurants;


--Uses:Window Function and Ranking

--3. Above Average Revenue Restaurants (Subquery)

SELECT restaurant_name,
       total_revenue
FROM (
    SELECT r.restaurant_name,
           ROUND(SUM(o.order_amount),2) AS total_revenue
    FROM restaurants r
    JOIN orders o
    ON r.restaurant_id = o.restaurant_id
    GROUP BY r.restaurant_name
) revenue_data

WHERE total_revenue > (
    SELECT AVG(total_revenue)
    FROM (
        SELECT SUM(order_amount) AS total_revenue
        FROM orders
        GROUP BY restaurant_id
    ) avg_data
)
ORDER BY total_revenue DESC;

--Uses: Subquery and Compatison Logic

--PHASE 7 — DATABASE OBJECTS

--1. Create Revenue View

CREATE OR REPLACE VIEW revenue_view AS
SELECT r.city,
       ROUND(SUM(o.order_amount),2) AS total_revenue
FROM orders o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
GROUP BY r.city;

--2. Stored Procedure — Get Top N Restaurants

--Create Function

CREATE OR REPLACE FUNCTION get_top_n_restaurants(n INT)
RETURNS TABLE (
    restaurant_name VARCHAR,
    total_revenue NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
    SELECT r.restaurant_name,
           ROUND(SUM(o.order_amount),2) AS total_revenue
    FROM restaurants r
    JOIN orders o
    ON r.restaurant_id = o.restaurant_id
    GROUP BY r.restaurant_name
    ORDER BY total_revenue DESC
    LIMIT n;
END;
$$ LANGUAGE plpgsql;

--PHASE 8 — PERFORMANCE OPTIMIZATION

--1. Index on order_date

CREATE INDEX idx_order_date
ON orders(order_date);

--2. Index on customer name

CREATE INDEX idx_customer_name
ON customers(name);

--3. Index on restaurant name

CREATE INDEX idx_restaurant_name
ON restaurants(restaurant_name);


--PHASE 9 — AUTOMATION LOGIC

--TRIGGER 1 — Prevent Negative Discount	

--Step 1: Create Trigger Function

CREATE OR REPLACE FUNCTION prevent_negative_discount()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.discount < 0 THEN
        RAISE EXCEPTION 'Discount cannot be negative';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Step 2: Create Trigger

CREATE TRIGGER trg_prevent_negative_discount
BEFORE INSERT OR UPDATE
ON orders
FOR EACH ROW
EXECUTE FUNCTION prevent_negative_discount();

--TRIGGER 2 — Delivery Delay Warning

--Step 1: Create Trigger Function

CREATE OR REPLACE FUNCTION delivery_delay_warning()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.delivery_time > 45 THEN
        RAISE NOTICE 'Warning: Delivery time exceeded 45 minutes';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Step 2: Create Trigger

CREATE TRIGGER trg_delivery_delay_warning
BEFORE INSERT OR UPDATE
ON orders
FOR EACH ROW
EXECUTE FUNCTION delivery_delay_warning();

