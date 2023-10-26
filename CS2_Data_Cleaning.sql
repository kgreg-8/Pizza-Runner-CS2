# Quick way to id data types in each table
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'PizzaRunner'
AND TABLE_NAME = 'customer_orders';

# Quick access to review the data in each table
SELECT * FROM pizza_names; # No issues
SELECT * FROM pizza_recipes; # Key: toppings is a string, the numbers in the string relate to a toppings_id in the pizza recipes table
SELECT * FROM pizza_toppings; # No issues -> will need to determine a way to relate this table with the pizza_recipes table
SELECT * FROM customer_orders; # 1) handle Nulls 2) how to handle translating values in string in Extras/Exclusions to Toppings? 
SELECT * FROM runner_orders; # Needs data cleansing: 1) handle NULL values in different columns 2) convert Distance column to INT from VARCHAR 3) determine how to handle the Duration column 4) convert Pickup_Time to DATETIME from VARCHAR
SELECT * FROM runners; # No issues in this data table

/* 
-----------------------------------------------------------
Create a Junction Table for Pizza_Recipes <> Pizza_Toppings
-----------------------------------------------------------
*/
DROP TABLE IF EXISTS pizza_toppings_junc;

CREATE TABLE pizza_toppings_junc 
(pizza_id INTEGER, topping_id INTEGER);

# Extract and translate the values in the string in pizza_recipes to new junction table in an automated manner - Recursive procedure
DROP PROCEDURE IF EXISTS extract_toppings;
DELIMITER $$
CREATE PROCEDURE extract_toppings(pizza_id INT, toppings_list TEXT)
BEGIN
    DECLARE topping_id INT;
    DECLARE pos INT;

    SET pos = LOCATE(',', toppings_list);

    WHILE pos > 0 DO
        SET topping_id = CAST(SUBSTRING(toppings_list, 1, pos - 1) AS DOUBLE);
        INSERT INTO pizza_toppings_junc (pizza_id, topping_id) VALUES (pizza_id, topping_id);
        SET toppings_list = SUBSTRING(toppings_list, pos + 1);
        SET pos = LOCATE(',', toppings_list);
    END WHILE;

    IF toppings_list != '' THEN
        SET topping_id = CAST(toppings_list AS DOUBLE);
        INSERT INTO pizza_toppings_junc (pizza_id, topping_id) VALUES (pizza_id, topping_id);
    END IF;
END $$
DELIMITER ;

CALL extract_toppings(1, '1, 2, 3, 4, 5, 6, 8, 10');
CALL extract_toppings(2, '4, 6, 7, 9, 11, 12');

/*
INSERT INTO pizza_toppings_junc
(pizza_id, topping_id) 
SELECT 
	pizza_id, 
	SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', n), ',', -1) AS topping_id 
FROM pizza_recipes, 
	(SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS num 
WHERE LENGTH(toppings) - LENGTH(REPLACE(toppings, ',', '')) >= n AND SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', n), ',', -1) REGEXP '^[0-9]+$';
*/
SELECT * FROM pizza_toppings_junc;


/* 
-----------------------------------------------------------
Cleanse Customer_Orders Table
-----------------------------------------------------------
1) handle Nulls 2) handle blank cells 3) translate values in string in Extras/Exclusions to Toppings 
*/
#1 handle 'null' cells
SELECT * FROM customer_orders;

UPDATE customer_orders 
SET extras = CASE WHEN extras = 'null' THEN NULL ELSE extras END;

UPDATE customer_orders
SET exclusions = CASE WHEN exclusions = 'null' THEN NULL ELSE exclusions END;

#2 handle blank cells
  # First, find the blank cells
SELECT *
FROM customer_orders
WHERE TRIM(extras) = '';
  # Then update them 
UPDATE customer_orders
SET 
	extras = NULL,
    exclusions = NULL    
WHERE TRIM(extras) = '' OR TRIM(exclusions) = '';

#3 Determine how to translate values in string in Extras/Exclusions to Toppings 
 -- will update with learnings later
 


/* 
---------------------------
Cleanse Runner_Orders Table
---------------------------
1) handle NULL values in different columns 2) convert Distance column to INT from VARCHAR 3) determine how to handle the Duration column 4) convert Pickup_Time to DATETIME from VARCHAR
*/
SELECT * FROM runner_orders; 

#1 Convert 'null' & blank cells to NULL
SELECT *
FROM runner_orders
WHERE TRIM(cancellation) = ''; -- validates the cells are blank due to an empty string

UPDATE runner_orders 
SET 
	pickup_time = CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END,
    distance = CASE WHEN distance = 'null' THEN NULL ELSE distance END,
	duration = CASE WHEN duration = 'null' THEN NULL ELSE duration END,
    cancellation = CASE WHEN cancellation = 'null' THEN NULL ELSE cancellation END;

UPDATE runner_orders
SET 
	cancellation = NULL
WHERE TRIM(cancellation) = '';

#2 & 3 convert Distance column to INT from VARCHAR
  -- First TRIM & REPLACE the units (km) characters 
UPDATE runner_orders
SET distance = TRIM(REPLACE(distance, 'km', ''));
  -- Lastly, alter the data type
ALTER table runner_orders
MODIFY distance INT; 
  -- Repeat for the Duration column (#3)
UPDATE runner_orders
SET duration = TRIM(REPLACE(REPLACE(REPLACE(duration, 'minutes', ''), 'mins', ''), 'minute', ''));

ALTER table runner_orders
MODIFY duration INT;

#4 convert Pickup_Time to DATETIME from VARCHAR
ALTER TABLE runner_orders
MODIFY pickup_time DATETIME;

#5 update column names to be more relevant/helpful to reader
ALTER TABLE runner_orders
CHANGE distance distance_km INT;
ALTER TABLE runner_orders
CHANGE duration duration_min INT;

-- The data is now clean & ready for your future queries :) --
