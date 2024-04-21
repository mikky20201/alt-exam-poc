/*
--QUESTION 1
-- The query is designed to find the most ordered item that checked out successfully

-- Create a Common Table Expression to isolate successful orders and count the number of times each product was ordered
with successful_order as (
    select 
        p.id, -- Product ID
        p.name, -- Product name
        count(o.status) as num_times, -- Count the number of times the product was ordered successfully
        -- Use a window function 'dense_rank' to rank the products based on the number of successful orders
        dense_rank() over(order by count(o.status) desc) as rank
    from alt_school.orders as o
    inner join alt_school.line_items as l on o.order_id = l.order_id
    inner join alt_school.products as p on p.id = l.item_id
    -- Filter based on successfully checked out items
    where o.status = 'success'
    -- Group by product ID and name to perform aggregations
    group by p.id, p.name
)

-- Select product ID, product name, and the number of times the product appeared in successful orders
select 
    id as product_id,
    name as product_name,
    num_times as num_times_in_successful_orders
from successful_order
-- Filter results to include only products with rank = 1, meaning the most ordered product
where rank = 1;

*/

/*
-- QUESTION 2
-- Define a CTE named 'flatten_json' to flatten JSON data from the 'events' table
with flatten_json as (
    -- Select specific fields from 'events' table and extract data from 'event_data' column
    select 
        event_id, 
        customer_id, 
        (event_data ->> 'item_id')::bigint as "item_id",
        (event_data->> 'quantity')::bigint as "quantity",
        event_data->> 'timestamp' as "timestamp",
        event_data->> 'event_type' as "event_type",
        event_timestamp
    from alt_school.events
), 

-- Define another CTE named 'result' to process flattened JSON data and calculate total spend
result as (
    -- Select customer_id, location, and calculate total spend by joining with other tables
    select 
        o.customer_id,
        location,
        sum(quantity*p.price) as total_spend,
        dense_rank() over(order by sum(quantity*p.price) desc) as rank
    from flatten_json as f
    -- Join with 'orders', 'products', and 'customers' tables
    inner join alt_school.orders as o on f.customer_id=o.customer_id
    inner join alt_school.products as p on f.item_id = p.ID
    inner join alt_school.customers as c on c.customer_id=o.customer_id
    -- Filter rows where item_id, quantity are not null and status is 'success'
    where (item_id is not null and quantity is not null) and status = 'success'
    -- Group results by customer_id and location
    group by o.customer_id, location
)

-- Select customer_id, location, and total_spend from the 'result' CTE
select 
    customer_id,
    location,
    total_spend
from result
-- Filter results to include only customers with ranks between 1 and 5
where rank between 1 and 5;
*/


/*
--QUESTION 3
-- Common Table Expression to flatten JSON data from events table
with flatten_json as (
    select 
        event_id,
        customer_id,
        (event_data ->> 'item_id')::bigint as "item_id",
        (event_data->> 'quantity')::bigint as "quantity",
        event_data->> 'timestamp' as "timestamp",
        event_data->> 'event_type' as "event_type",
        event_timestamp
    from alt_school.events
),
-- Subquery to calculate checkout counts and ranks by location
location_checkout as (
    select 
        location,
        count(f.event_type) as checkout_count,
        dense_rank() over(order by count(f.event_type) desc) as rank
    from flatten_json as f
    inner join alt_school.customers as c on c.customer_id=f.customer_id
    inner join alt_school.orders as o on o.customer_id=c.customer_id
    where event_type = 'add_to_cart' and status = 'success'
    group by location
)
-- Main query to select location and checkout count, ordered by rank
select 
    location,
    checkout_count
from location_checkout
order by rank;
*/



/*
-- QUESTION 4
-- CTE to flatten JSON data from 'events' table
WITH flatten_json AS (
    SELECT
        event_id,
        customer_id,
        (event_data ->> 'item_id')::bigint AS "item_id",
        (event_data ->> 'quantity')::bigint AS "quantity",
        event_data ->> 'timestamp' AS "timestamp",
        event_data ->> 'event_type' AS "event_type",
        event_timestamp
    FROM 
        alt_school.events
)

-- Main query to count events for abandoned their carts
SELECT 
    o.customer_id,
    COUNT(event_type) AS num_events
FROM 
    alt_school.orders AS o
INNER JOIN flatten_json AS f ON f.customer_id = o.customer_id

WHERE 
    (event_type <> 'visit' AND event_type <> 'checkout') AND status = 'cancelled'
GROUP BY 
    o.customer_id
ORDER BY 
    num_events DESC;

*/
/*
-- QUESTION 5
--  Common Table Expression to flatten JSON data from events table
with flatten_json as (
    select 
        event_id,
        customer_id,
        (event_data ->> 'item_id')::bigint as "item_id",
        (event_data ->> 'quantity')::bigint as "quantity",
        event_data ->> 'timestamp' as "timestamp",
        event_data ->> 'event_type' as "event_type",
        event_timestamp
    from alt_school.events
),
--  Calculate visit counts for each customer
visit as (
    select 
        o.customer_id,
        sum(case 
            when event_type = 'visit' and status = 'cancelled' then 1
            when event_type = 'visit' and status = 'failed' then 1
            when event_type = 'visit' and status = 'success' then 1
            else 0
        end) as visit_count
    from alt_school.orders as o
    inner join flatten_json as f on f.customer_id = o.customer_id
    --where status = 'success'
    group by o.customer_id, status
)
-- Calculate the average visit count across all customers
select 
    cast(avg(visit_count) as decimal(10,2)) as average_visits
from visit;

*/