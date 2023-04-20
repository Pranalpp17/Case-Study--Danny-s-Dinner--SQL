-- Creating Database --

CREATE DATABASE IF NOT EXISTS resturant;

USE resturant;

-- Creating Tables and Inserting Data --

CREATE TABLE members(
	customer_id varchar(1) primary key,
    join_date date
);

INSERT INTO members VALUES
	("A", "2021-01-07"),
    ("B", "2021-01-09");
    
    
CREATE TABLE menu(
	product_id int primary key,
    product_name varchar(255),
    price int
);

INSERT INTO menu VALUES
	(1, "sushi", 10),
    (2, "curry", 15),
    (3, "ramen", 12);
    
CREATE TABLE sales(
	customer_id varchar(1),
    order_date date,
    product_id int 
);

INSERT INTO sales VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
  
												-- Data Analysis --
  
  -- Combined Table Using Joins -- 
WITH hotel AS (SELECT sales.customer_id, order_date, product_name, price,
CASE 
	WHEN sales.customer_id =  members.customer_id AND sales.order_date >= members.join_date THEN "Y"
    ELSE "N"
END AS 'members'
FROM sales
JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id)


-- 1. What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id AS 'customer_name',SUM(menu.price) AS 'total_amount_spent' FROM 
menu JOIN sales ON menu.product_id = sales.product_id
GROUP BY sales.customer_id;


-- 2. How many days has each customer visited the restaurant?
SELECT customer_id AS 'customer_name', COUNT(distinct(order_date)) AS 'no_of_days' FROM sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?
WITH hotel AS (SELECT sales.customer_id, order_date, product_name, price,
CASE 
	WHEN sales.customer_id =  members.customer_id AND sales.order_date >= members.join_date THEN "Y"
    ELSE "N"
END AS 'members'
FROM sales
JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id)

SELECT * FROM hotel h1 
WHERE h1.order_date = (SELECT  min(order_date) FROM hotel h2 WHERE h2.customer_id = h1.customer_id);


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH hotel AS (SELECT sales.customer_id, order_date, product_name, price,
CASE 
	WHEN sales.customer_id =  members.customer_id AND sales.order_date >= members.join_date THEN "Y"
    ELSE "N"
END AS 'members'
FROM sales
JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id)

SELECT customer_id,product_name,count(product_name) AS 'no_of_orders' FROM hotel WHERE product_name = 
(SELECT product_name FROM (SELECT product_name, count(product_name) AS 'no_of_times' From hotel
GROUP BY product_name) AS T1 WHERE no_of_times = 
(SELECT max(no_of_times) FROM
(SELECT product_name, count(product_name) AS 'no_of_times' From hotel
GROUP BY product_name) AS T))
GROUP BY customer_id;


-- 5. Which item was the most popular for each customer?
WITH orders AS (SELECT sales.customer_id, menu.product_name, count(sales.product_id) AS 'no_of_orders'
FROM sales JOIN menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id, menu.product_id)

SELECT * FROM orders o1 WHERE o1.no_of_orders = 
(SELECT max(no_of_orders) FROM orders o2 WHERE o1.customer_id = o2.customer_id);


-- 6. Which item was purchased first by the customer after they became a member?
WITH first_order AS (SELECT sales.customer_id, menu.product_name, sales.order_date, members.join_date FROM 
sales JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id 
WHERE members.join_date <= sales.order_date)

SELECT customer_id ,product_name, min(order_date) AS 'first_orderDate_after_membership' 
FROM first_order GROUP BY customer_id;


-- 7. Which item was purchased just before the customer became a member?
SELECT customer_id, product_name, max(order_date) AS 'item_purchased_just_before_membership'
FROM (SELECT sales.customer_id, menu.product_name, sales.order_date, members.join_date 
FROM sales JOIN menu ON sales.product_id = menu.product_id 
JOIN members ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date) AS T
GROUP BY customer_id;


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT sales.customer_id, count(sales.product_id) AS 'no_of_orders', SUM(menu.price) AS 'total_spent'
FROM sales JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- how many points would each customer have?
SELECT T2.customer_id,  
CASE
	WHEN ISNULL(sushi) THEN not_sushi
    ELSE sushi+not_sushi
END AS 'total_points_earned'
FROM(
SELECT sales.customer_id, (SUM(price)*10)*2 AS 'sushi'
FROM sales JOIN menu ON sales.product_id = menu.product_id
WHERE product_name = 'sushi'
GROUP BY customer_id) AS T1 
RIGHT JOIN 
(SELECT customer_id, sum(price*10) AS 'not_sushi' 
FROM sales JOIN menu ON sales.product_id = menu.product_id
WHERE product_name <> 'sushi'
GROUP BY customer_id) AS T2 
ON T1.customer_id = T2.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B 
-- have at the end of January?
SELECT sales.customer_id, ((SUM(menu.price)*10)*2) AS 'total_points_earned'
FROM sales JOIN menu ON sales.product_id = menu.product_id
JOIN members ON members.customer_id = sales.customer_id
WHERE sales.order_date >= members.join_date AND MONTH(sales.order_date) = 1
GROUP BY sales.customer_id;

