-- Table Setup

-- Table: regions
CREATE TABLE regions (
    region_id SERIAL PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL
);

-- Table: customers
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    gender VARCHAR(10),
    region_id INT REFERENCES regions(region_id),
    signup_date DATE
);

-- Table: products
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2) CHECK (price >= 0)
);

-- Table: orders
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE NOT NULL,
    status VARCHAR(50) CHECK (status IN ('Completed', 'Returned', 'Cancelled'))
);

-- Table: order_items
CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT CHECK (quantity > 0),
    unit_price DECIMAL(10,2) CHECK (unit_price >= 0)
);

-- Table: returns
CREATE TABLE returns (
    return_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    return_date DATE,
    reason TEXT
);

-- Load the Data from CSV Files
COPY regions(region_id, region_name)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\regions.csv'
DELIMITER ','
CSV HEADER;

COPY customers(customer_id, customer_name, email, gender, region_id, signup_date)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\customers_1000.csv'
DELIMITER ','
CSV HEADER;

COPY products(product_id, product_name, category, price)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\products.csv'
DELIMITER ','
CSV HEADER;

COPY orders(order_id, customer_id, order_date)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\orders.csv'
DELIMITER ','
CSV HEADER;

COPY order_items(item_id, order_id, product_id, quantity, unit_price)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\order_items_500.csv'
DELIMITER ','
CSV HEADER;


COPY returns(return_id, order_id, return_date, reason)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\returns_with_reason_200.csv'
DELIMITER ','
CSV HEADER;

drop TABLE returns;

-- Step 3: Data Validation & Cleaning

-- Step 3.1: Check For Null Values

-- NULL check in customers
SELECT COUNT(*) 
FROM customers 
WHERE customer_name IS NULL 
   OR email IS NULL 
   OR gender IS NULL 
   OR signup_date IS NULL;


-- NULL check in orders
SELECT COUNT(*) FROM orders WHERE customer_id IS NULL OR order_date IS NULL;

-- NULL check in products
SELECT COUNT(*) FROM products WHERE product_name IS NULL OR category IS NULL OR price IS NULL;

-- NULL check in order_items
SELECT COUNT(*) FROM order_items WHERE order_id IS NULL OR product_id IS NULL OR quantity IS NULL OR unit_price IS NULL;

-- NULL check in regions 
SELECT COUNT(*) 
FROM regions 
WHERE region_name IS NULL;

-- NULL Checks in return
SELECT COUNT(*) 
FROM returns 
WHERE reason IS NULL;



-- Step 3.2: Check for Duplicate Rows

--checking duplicates for customers 
SELECT customer_name,email, gender,region_id, signup_date, count(*)
from customers 
group by customer_name, email, gender, region_id, signup_date
having count(*) > 1;

-- chceking duplicate for products
select product_name, category, price , count(*)
from products
group by product_name, category, price
having count(*) > 1;

-- checking duplicates for order
select customer_id, order_date,count(*)
from orders
group by customer_id, order_date
having count(*) >1;


SELECT order_id, customer_id, order_date
FROM orders
WHERE customer_id = 109 AND order_date = '2020-06-28';

SELECT order_id, customer_id, order_date
FROM orders
WHERE customer_id = 347 AND order_date = '2021-07-30';

SELECT order_id, customer_id, order_date
FROM orders
WHERE customer_id = 69 AND order_date = '2021-07-25';

SELECT order_id, product_id, quantity, unit_price
FROM order_items
WHERE order_id IN (332, 556)
ORDER BY order_id, product_id;




customer_id   order_date
109	          "2020-06-28"
347	          "2021-07-30"
69	          "2021-07-25"

order_id  customer_id   order_date
332	      109	        "2020-06-28"
556	      109	        "2020-06-28"


select * from order_items 
where order_id in (332, 556);

select * from order_items 
where order_id in (222, 837);

select * from order_items 
where order_id in (745, 1431);



DELETE FROM orders WHERE order_id = 556;


SELECT *
FROM orders
WHERE (customer_id, order_date) IN (
  SELECT customer_id, order_date
  FROM orders
  GROUP BY customer_id, order_date
  HAVING COUNT(*) > 1
);

SELECT *
FROM order_items
WHERE order_id IN (222, 837, 332, 556, 745, 1431);

SELECT *
FROM order_items
WHERE order_id = 837;


-- checking duplicates for order_items
select order_id	,product_id, quantity, unit_price, count(*)
from order_items
group by order_id, product_id, quantity, unit_price
having count(*) > 1;


-- checking dullicates for returns
select order_id, return_date, reason
from returns
group by order_id, return_date, reason
having count(*) > 1;


-- Step 3.3: Check for Invalid Values

-- Step 3.4: Fixing the Data (if needed)
