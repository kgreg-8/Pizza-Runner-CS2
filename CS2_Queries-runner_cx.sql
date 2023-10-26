/* 
	-----------------
	Runner & CX Focus
	-----------------
*/
SELECT * FROM runners;
# 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
	DATE_FORMAT(DATE_ADD(registration_date, INTERVAL -WEEKDAY(registration_date) DAY),'%Y-%m-%d') AS week, 
    COUNT(DISTINCT runner_id) AS signup_count
FROM runners
GROUP BY DATE_FORMAT(DATE_ADD(registration_date, INTERVAL -WEEKDAY(registration_date) DAY),'%Y-%m-%d');
-- 2 runners signed up during the week of 12/28/20-1/3/21, 1 runner signed up during the week of 1/4/21-1/10/21 & 1 runner signed up during the week of 1/11/21-1/17/21.


# 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH cte AS (
SELECT 
	r.order_id,
    r.runner_id,
    c.order_time,
    r.pickup_time,
    TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time) AS minute_diff
FROM runner_orders r
		JOIN
	customer_orders c ON r.order_id = c.order_id
)
SELECT
	runner_id,
    ROUND(AVG(minute_diff), 2) AS avg_time_to_pickup
FROM cte
GROUP BY runner_id;
-- It took Runner 1 an avg of 15.33 minutes to arrive at HQ to pickup the orders they delivered | 2: 23.40 mins | 3: 10 mins | 4: 0 deliveries so no time available


# 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- Think of this as - we need to determine how the number of pizzas ordered affects the preparation time
# Turn off only_full_group_by in SQL then:
SELECT 
	COUNT(c.pizza_id) AS pizzas_in_order,
    TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time) AS minute_diff
FROM runner_orders r
		JOIN
	customer_orders c ON r.order_id = c.order_id
GROUP BY COUNT(c.pizza_id);
-- Prep time increases as the number of pizzas ordered increases.

-- Pearson Correlation 
-- Creating temporary table 
DROP TABLE IF EXISTS pearson;
CREATE TEMPORARY TABLE pearson 
SELECT AVG(TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time)) AS order_prep_time
      ,COUNT(c.pizza_id) as pizza_count
      ,c.order_id
FROM runner_orders r 
JOIN customer_orders c ON c.order_id = r.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY c.order_id;
-- Creating average and std rows
SELECT @ax := ROUND(AVG(order_prep_time), 2) AS avg_prep_tim, 
       @ay := ROUND(AVG(pizza_count), 2) AS avg_pizzas_ordered, 
       @div := ROUND((stddev_samp(order_prep_time) * stddev_samp(pizza_count)), 2) AS stdev
FROM pearson;
-- Calculating pearson r value
SELECT ROUND(SUM(( order_prep_time - @ax ) * (pizza_count - @ay)) / ((count(order_prep_time) -1) * @div), 2) AS pearson_r
FROM pearson;
-- 84% correlation. Hence, we can say there is a correlation between prep time and the number of pizzas in an order.


# 4. What was the average distance travelled for each customer?
SELECT 
	c.customer_id,
    ROUND(AVG(r.distance_km), 2) as avg_distance
FROM runner_orders r
		JOIN
	customer_orders c ON r.order_id = c.order_id
GROUP BY c.customer_id;
-- AVG distance to deliver for each customer: 101=20 km | 102=16.33 km | 103=23 km | 104=10 km | 105=25 km


# 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
    MAX(duration_min) - MIN(duration_min) as diff
FROM runner_orders;
-- The variance between max and min order delivery times is 30 minutes.


# 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
    runner_id,   
    order_id,
    ROUND((distance_km * 60)/duration_min, 2) as speed
FROM runner_orders 
WHERE cancellation IS NULL;

# Step 2) Join this result set with the customer_orders table to see if the speed may be related to the customer they are delivering to.
SELECT
    r.runner_id,   
    r.order_id,
    c.customer_id,
    ROUND(AVG((r.distance_km * 60)/r.duration_min), 2) as speed
FROM runner_orders r
		JOIN
	customer_orders c ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY  r.runner_id, r.order_id, c.customer_id
ORDER BY runner_id;
-- Not enough data to notice a relevant trend (speed for each runner is either moderate & fast or insuficient)


# 7. What is the successful delivery percentage for each runner?
# Step 1) Find total orders assigned per runner
SELECT
	runner_id,
    COUNT(order_id) as total_orders_assigned
FROM runner_orders
GROUP BY runner_id;
# Step 2) Find total orders delivered per runner
SELECT 
	runner_id,
    COUNT(order_id) as total_orders_delivered
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id; 
# Step 3) Put it together and calculate percentage
WITH cte1 AS (
SELECT
	runner_id,
    COUNT(order_id) as total_orders_assigned
FROM runner_orders
GROUP BY runner_id
),
cte2 AS (
SELECT 
	runner_id,
    COUNT(order_id) as total_orders_delivered
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
)

SELECT 
	cte1.runner_id,
    ROUND((cte2.total_orders_delivered / cte1.total_orders_assigned) * 100, 2) AS successful_delivery_perc
FROM cte1
		JOIN
	cte2 ON cte1.runner_id = cte2.runner_id;
/* Runner 1 has a successful delivery percentage of 100%, while Runners 2 & 3 have percentages of 75% & 50%. 
The successful delivery of an order is not fully dependent upon the runner or the speed in which they deliver the order as both the customer 
or the restaurant may cancel the order. Runner 4 did not make a delivery. */