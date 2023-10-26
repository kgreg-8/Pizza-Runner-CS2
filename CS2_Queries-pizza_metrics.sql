/* 
	---------------------
	Pizza Metrics Focus
	---------------------
*/
SELECT * FROM customer_orders ORDER BY customer_id;

# 1. How many pizzas were ordered?
SELECT 
	COUNT(pizza_id) as total_pizzas_ordered
FROM customer_orders;
-- 14 pizzas were ordered.


# 2. How many unique customer orders were made? 
    -- means how many distinct orders did each customer place.
SELECT 
	customer_id,
    COUNT(DISTINCT order_time)
FROM customer_orders
GROUP BY customer_id;
-- Customer 101 placed 3 unique orders (called in 3 differnt times to place an order) | 102: 2 | 103: 2 | 104: 2 | 105: 1


# 3. How many successful orders were delivered by each runner?
SELECT * FROM runner_orders;
 -- number of orders that weren't cancelled
SELECT
	COUNT(*) AS orders_delivered
FROM runner_orders
WHERE cancellation IS NULL;
-- 8 successful orders were delivered.


# 4. How many of each type of pizza was delivered?
SELECT
	p.pizza_name,
    COUNT(c.pizza_id) as num_pizzas_delivered
FROM runner_orders r
		JOIN
	customer_orders c ON r.order_id = c.order_id
		JOIN
	pizza_names p ON c.pizza_id = p.pizza_id
WHERE r.cancellation IS NULL
GROUP BY p.pizza_name;
-- Pizza 1, Meatlovers, was (successfully orderded and) delivered 9 times, while Pizza 2, Vegetarian, was delivered 3 times.


# 5. How many Vegetarian and Meatlovers were ordered by each customer?
   -- question does not specify cancellations, so we are looking at total of all orders before cancellations.
SELECT
	c.customer_id,
    COUNT(CASE WHEN p.pizza_name = 'Meatlovers' THEN 1 ELSE NULL END) as meat_ordered_count,
    COUNT(CASE WHEN p.pizza_name = 'Vegetarian' THEN 1 ELSE NULL END) as veg_ordered_count
FROM runner_orders r
		JOIN
	customer_orders c ON r.order_id = c.order_id
		JOIN
	pizza_names p ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id;
-- Customer 101 ordered Meatlovers 2x and Vegetarian 1x | 102: M=2 & V=1 | 103: M=3 & V=1 | 104: M=3 & V=0 | 105: M=0 & V=1


# 6. What was the maximum number of pizzas delivered in a single order?
# Step 1) Find the counts of pizzas ordered and sort by their count to see most pizzas ordered in a single order
SELECT
	order_time,
    COUNT(pizza_id) as pizzas_ordered
FROM customer_orders
GROUP BY order_time
ORDER BY pizzas_ordered DESC;
# Step 2) Join customer_orders with runner_orders to find the count of successfully ordered pizzas that were delivered (i.e. exclude cancellations)
SELECT
	c.order_time,
    COUNT(c.pizza_id) as pizzas_ordered_successfully
FROM customer_orders c
		JOIN
	runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.order_time
ORDER BY pizzas_ordered_successfully DESC; # 2 fewer rows (makes sense b/c there are 2 cancellations)
-- The MAX pizzas delivered in a single order occurred on Jan. 4, 2020 and contained 3 pizzas.


# 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
      -- I am defining a change as a value existing in either the exclusions OR extras column
# Step 1) Find count of total orders for each customer
SELECT
	customer_id,
    COUNT(order_id) as total_orders
FROM customer_orders
GROUP BY customer_id;
# Step 2) Find the customers that had an order with a change made & then join with runner_orders to find the pizzas that were delivered that had a change.
SELECT
	c.customer_id,
    COUNT(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN NULL ELSE 1 END) AS changes_count
FROM customer_orders c
		JOIN
	runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.customer_id;
# Step 2) Find total count of both pizzas that were delivered had changes and pizzas that were delivered and weren't changed 
WITH cte1 AS (
	SELECT
		c.customer_id,
		COUNT(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN NULL ELSE 1 END) AS changes_count
	FROM customer_orders c
			JOIN
		runner_orders r ON c.order_id = r.order_id
	WHERE r.cancellation IS NULL
	GROUP BY c.customer_id
),
cte2 AS (
	SELECT
		customer_id,
		COUNT(order_id) as total_orders_delivered
	FROM customer_orders
	GROUP BY customer_id
)
SELECT 
	cte1.customer_id,
    cte1.changes_count,
    cte2.total_orders_delivered - cte1.changes_count AS not_changed_count
FROM cte1
		JOIN
	cte2 ON cte1.customer_id = cte2.customer_id;
-- For customer 101 all 3 of their orders, delivered, had 0 changes | 102: CHG=0 NOCHG=3 | 103: CHG=0 NOCHG=4 | 104: CHG=2 NOCHG=1 | 105: CHG=1 NOCHG=0


# 8. How many pizzas were delivered that had both exclusions and extras?
SELECT
	COUNT(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN NULL ELSE 1 END) AS excl_and_extras
FROM customer_orders c
		JOIN
	runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL;
-- 3 orders that were delivered had both exclusions and extras.


# 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	HOUR(order_time) AS hour_of_day, 
	COUNT(order_id) AS order_volume
FROM customer_orders
GROUP BY HOUR(order_time)
ORDER BY hour_of_day;
-- This pizzeria sees it's highest volume around dinner time (6 PM local time) to midnight.


# 10. What was the volume of orders for each day of the week?
SELECT
	DAYNAME(order_time) AS day_of_week,
    COUNT(order_id) AS order_volume
FROM customer_orders
GROUP BY DAYNAME(order_time)
ORDER BY day_of_week;
-- So far this place has received its orders between Wednesday - Saturday, with volume picking up on Thursdays and Saturdays.