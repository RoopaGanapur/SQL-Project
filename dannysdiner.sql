

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
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
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  select * from members;
  select * from sales;
  select * from menu;


  ----What is the total amount each customer spent at the restaurant?


  SELECT  s.customer_id,
  SUM(me.price) AS total_amount   
  FROM sales s JOIN menu me
  ON s.product_id=me.product_id
  GROUP BY  s.customer_id;
  
   

-----How many days has each customer visited the restaurant?

SELECT customer_id,COUNT(DISTINCT order_date) FROM sales
GROUP BY customer_id;




----What was the first item from the menu purchased by each customer?
with cte as
(SELECT  s.customer_id,m.product_name,dense_rank() over(partition by customer_id order by order_date) as rn  FROM sales s join menu m on
s.product_id=m.product_id)
select customer_id, product_name from cte where rn=1
group by customer_id,product_name;


----What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name,count(s.order_date) as count from sales s join menu m
on s.product_id=m.product_id
group by m.product_name
order by count desc


---Which item was the most popular for each customer?
with cte as
(select s.customer_id,m.product_name,count(*)as count,dense_rank() over(partition by customer_id order by customer_id, count(*) desc ) as rn from sales s join menu m 
on s.product_id=m.product_id
group by s.customer_id,m.product_name 
)
select customer_id,product_name from cte where rn=1



---Which item was purchased first by the customer after they became a member?
with cte as
(select 
m.customer_id,s.product_id,s.order_date ,dense_rank() over(partition by s.customer_id order by s.order_date ) as rn  from sales  s join members m on
s.customer_id=m.customer_id 
where s.order_date>m.join_date)
select c.customer_id,p.product_name from cte c join menu p
on c.product_id=p.product_id where c.rn=1


--Which item was purchased just before the customer became a member?

with cte as
(select 
m.customer_id,s.product_id,s.order_date ,row_number() over(partition by s.customer_id order by s.order_date desc) as rn  from sales  s join members m on
s.customer_id=m.customer_id 
where s.order_date<m.join_date)
select c.customer_id,p.product_name from cte c join menu p
on c.product_id=p.product_id where c.rn=1

--What is the total items and amount spent for each member before they became a member?
with cte as(
select 
m.customer_id,s.product_id,s.order_date   from sales  s join members m on
s.customer_id=m.customer_id 
where s.order_date<m.join_date)
select c.customer_id,sum(m.price) as totalamount,count(c.product_id) as totalitems from cte c join menu m on
c.product_id=m.product_id
group by c.customer_id


---If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with cte as
(select product_id,
case 
when product_id=1 then 20*price
else 10*price end as points
from menu)
select s.customer_id,sum(c.points) from cte c join sales s
on c.product_id=s.product_id
group by s.customer_id


---In Join All The Things

----Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

SELECT 
  s.customer_id, 
  s.order_date,  
  me.product_name, 
  me.price,
  CASE
    WHEN m.join_date > s.order_date THEN 'N'
    WHEN m.join_date <= s.order_date THEN 'Y'
    ELSE 'N' END AS member_status
FROM sales s
LEFT JOIN members m
  ON s.customer_id = m.customer_id
INNER JOIN menu me
  ON me.product_id = s.product_id
ORDER BY s.customer_id,s.order_date



---Rank All The Things

---Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

WITH customers_data AS (
 SELECT 
  s.customer_id, 
  s.order_date,  
  me.product_name, 
  me.price,
  CASE
    WHEN m.join_date > s.order_date THEN 'N'
    WHEN m.join_date <= s.order_date THEN 'Y'
    ELSE 'N' END AS member_status
FROM sales s
LEFT JOIN members m
  ON s.customer_id = m.customer_id
INNER JOIN menu me
  ON me.product_id = s.product_id

)

SELECT 
  *, 
  CASE
    WHEN member_status = 'N' then NULL
    ELSE RANK () OVER (
      PARTITION BY customer_id, member_status
      ORDER BY order_date
  ) END AS ranking
FROM customers_data;