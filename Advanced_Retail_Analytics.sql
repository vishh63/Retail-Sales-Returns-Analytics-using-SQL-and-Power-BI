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
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\regions1.csv'
DELIMITER ','
CSV HEADER;

COPY customers(customer_id, customer_name, email, gender, region_id, signup_date)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\customers1.csv'
DELIMITER ','
CSV HEADER;

COPY products(product_id, product_name, category, price)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\products1.csv'
DELIMITER ','
CSV HEADER;

COPY orders(order_id, customer_id, order_date)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\orders1.csv'
DELIMITER ','
CSV HEADER;

COPY order_items(item_id, order_id, product_id, quantity, unit_price)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\order_items1.csv'
DELIMITER ','
CSV HEADER;


COPY returns(return_id, order_id, return_date, reason)
FROM 'C:\Program Files\PostgreSQL\17\data\CSV_FILES\returns1.csv'
DELIMITER ','
CSV HEADER;


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
WHERE customer_id = 143 AND order_date = '2024-08-31';

SELECT order_id, product_id, quantity, unit_price
FROM order_items
WHERE order_id IN (22, 267)
ORDER BY order_id, product_id;


-- checking duplicates for order_items
select order_id	,product_id, quantity, unit_price, count(*)
from order_items
group by order_id, product_id, quantity, unit_price
having count(*) > 1;

SELECT *
FROM order_items
WHERE item_id NOT IN (
    SELECT MIN(item_id)
    FROM order_items
    GROUP BY order_id, product_id, quantity, unit_price
);

SELECT *
FROM order_items
WHERE (order_id, product_id, quantity, unit_price) IN (
    SELECT order_id, product_id, quantity, unit_price
    FROM order_items
    GROUP BY order_id, product_id, quantity, unit_price
    HAVING COUNT(*) > 1
)
ORDER BY order_id, product_id;

DELETE FROM order_items
WHERE item_id NOT IN (
    SELECT MIN(item_id)
    FROM order_items
    GROUP BY order_id, product_id, quantity, unit_price
);


-- checking dullicates for returns
select order_id, return_date, reason
from returns
group by order_id, return_date, reason
having count(*) > 1;


-- Step 3.3: Check for Invalid Values
-- For customers 
-- Null or invalid emails
SELECT * FROM customers WHERE email IS NULL OR email NOT LIKE '%@%.%';

-- Invalid genders
SELECT * FROM customers WHERE gender NOT IN ('Male', 'Female', 'Other');

-- Invalid region reference
SELECT * FROM customers WHERE region_id NOT IN (SELECT region_id FROM regions);

-- Invalid dates
SELECT * FROM customers WHERE signup_date IS NULL;


-- For Products
-- Negative or null prices
SELECT * FROM products WHERE price IS NULL OR price < 0;

-- Null product names or categories
SELECT * FROM products WHERE product_name IS NULL OR category IS NULL;

-- For orders
-- Invalid status
SELECT * FROM orders WHERE status NOT IN ('Completed', 'Returned', 'Cancelled');

-- Invalid customer reference
SELECT * FROM orders WHERE customer_id NOT IN (SELECT customer_id FROM customers);

-- Null order dates
SELECT * FROM orders WHERE order_date IS NULL;


-- For order_items
-- Invalid quantity or unit_price
SELECT * FROM order_items WHERE quantity <= 0 OR unit_price < 0;

-- Invalid foreign keys
SELECT * FROM order_items
WHERE order_id NOT IN (SELECT order_id FROM orders)
OR product_id NOT IN (SELECT product_id FROM products);


-- For returns
-- Invalid return date or null reason
SELECT * FROM returns
WHERE return_date IS NULL OR reason IS NULL;

SELECT *
FROM returns
WHERE order_id NOT IN (SELECT order_id FROM orders);

-- Check for orphan returns
SELECT *
FROM returns
WHERE order_id NOT IN (SELECT order_id FROM orders);


-- Step 4: Data Exploration & Insight Generation
-- Step 4.1: Build Basic Analytical SQL Queries

-- 1. Total Revenue
SELECT 
    ROUND(SUM(quantity * unit_price), 2) AS total_revenue
FROM order_items;

-- 2. Monthly Sales Trend
SELECT 
    DATE_TRUNC('month', o.order_date) AS month,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS monthly_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- 3. Top 10 Customers by Revenue
SELECT 
    c.customer_id,
    c.customer_name,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- 4. Best-Selling Products
SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- 5. Sales by Region
SELECT 
    r.region_name,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_sales
FROM regions r
JOIN customers c ON r.region_id = c.region_id
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY r.region_name
ORDER BY total_sales DESC;

-- 6. Return Rate
SELECT 
    ROUND(COUNT(DISTINCT r.order_id)::decimal / COUNT(DISTINCT o.order_id) * 100, 2) AS return_rate_percentage
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id;




