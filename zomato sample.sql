CREATE DATABASE ZOMATO;
DROP DATABASE ZOMATO;
USE  ZOMATO;
CREATE  TABLE GOLDUSER_SIGNUP
(USER_ID INT,
 GOLD_SIGNUP_DATE DATE);

INSERT INTO GOLDUSER_SIGNUP
VALUES
(1,'2017-09-22'),
(3,'2017-04-21');

CREATE TABLE PRODUCT
(product_id INT,
 product_name VARCHAR(20),
 price Float );
 
INSERT INTO  PRODUCT
VALUES
(1,	'p1',980),
(2,	'p2',870),
(3,	'p3',330);

CREATE  TABLE SALES
(userid INT,
 created_date DATE,
 product_id INT);
 
INSERT INTO SALES
VALUES
(1,	'2017-04-19',2),
(3,'2019-12-18',1),
(2,	'2020-07-20',3),
(1,	'2019-10-23',2),
(1,	'2018-03-19',3),
(3,	'2016-12-20',2),
(1,	'2016-11-09',1),
(1,'2016-05-20',3),
(2,	'2017-09-24',1),
(1,	'2017-03-11',2),
(1,	'2016-03-11',1),
(3,	'2016-11-10',1),
(3,	'2017-12-07',2),
(3,	'2016-12-15',2),
(2,	'2017-11-08',2),
(2,'2018-09-10',3);

CREATE TABLE USERS 
(userid INT,
 signup_date DATE);
 
 INSERT INTO USERS
 VALUES
 (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

SELECT * FROM GOLDUSER_SIGNUP;
SELECT * FROM PRODUCT;
SELECT * FROM SALES;
SELECT * FROM USERS;

SELECT userid,monthname(created_date) as month,count(userid)as TOTAL_ORDER FROM SALES     /*----user how as order more than two time */
GROUP BY 1,2
ORDER BY 1;
---- HAVING COUNT(USERID)>2
/*1. What is the total amount each customer spent on zomato?
--- 2. How many days has each customer visited zomato?
-- 3. What was the first product purchased by each of the customer?
--- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
--- 5.  Which item was the most popular for each customer?
--- 6.which item was purchased first by customer after they become a member ?
--- 7. which item was purchased just before the customer became a member?
--- 8. what is total orders and amount spent for each member before they become a member?
--- 9. If buying each product generates points for eg 5rs=2 zomato point and each product has different purchasing points for eg for p1 5rs=1 zomato point,for p2 10rs=zomato point and p3 5rs=1 zomato point 2rs =1zomato point, 
--calculate points collected by each customer and for which product most points have been given till now.
--10. In the first year after a customer joins the gold program (including the join date ) irrespective of what customer has purchased earn 5 zomato points for every 10rs spent who earned more more 1 or 3 what int earning in first yr ? 1zp = 2rs
--- 11. Ranking all the transaction of the customers . */



 -- What is the total amount each customer spent on zomato?
 
SELECT S.userid,sum(P.price) as Total  FROM SALES S 
JOIN PRODUCT P ON S.product_id = P.product_id
group by 1;

SELECT userid,monthname(created_date) as month,count(userid)as TOTAL_ORDER FROM SALES     /*----user how as order more than two time */
GROUP BY 1,2
ORDER BY 1;

-- How many days has each customer visited zomato?

SELECT userid,count(distinct created_date)as visited from sales 
group by userid;

-- What was the first product purchased by each of the customer?

WITH CTE AS(
 SELECT * , RANK() OVER (PARTITION BY userid  ORDER BY created_date) AS RANKING
FROM SALES)
SELECT * FROM CTE WHERE RANKING = 1;


-- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT P.PRODUCT_NAME,S.PRODUCT_ID ,
COUNT(S.PRODUCT_ID) AS PURCHASE_FREQUENCY
FROM SALES S 
JOIN PRODUCT P ON S.PRODUCT_ID = P.PRODUCT_ID
GROUP BY 1,2
ORDER BY COUNT(S.PRODUCT_ID) DESC
LIMIT 1;

-- Which item was the most popular for each customer?
WITH CTE AS (
SELECT USERID,PRODUCT_ID,COUNT(PRODUCT_ID) AS ORDER_COUNT FROM SALES
GROUP BY 1,2)
SELECT USERID,PRODUCT_ID,product_name FROM (
SELECT C.USERID , C.PRODUCT_ID,P.product_name  ,DENSE_RANK() OVER(PARTITION BY USERID ORDER BY ORDER_COUNT DESC) AS RANK_NO 
FROM CTE C
JOIN PRODUCT P ON C.PRODUCT_ID = P.PRODUCT_ID
) AS FAV
WHERE RANK_NO = 1;

-- which item was purchased first by customer after they become a member ?
WITH CTE AS(
SELECT G.USER_ID ,G.GOLD_SIGNUP_DATE,S.CREATED_DATE,S.PRODUCT_ID,
RANK () OVER (PARTITION BY G.USER_ID  ORDER BY S.CREATED_DATE ) AS RANK_NO
 FROM GOLDUSER_SIGNUP G 
JOIN SALES S ON G.USER_ID = S. USERID
WHERE S.CREATED_DATE >= G.GOLD_SIGNUP_DATE)
SELECT USER_ID, PRODUCT_ID FROM CTE WHERE RANK_NO = 1;

-- which item was purchased just before the customer became a member?

WITH CTE AS(
SELECT G.USER_ID ,G.GOLD_SIGNUP_DATE,S.CREATED_DATE,S.PRODUCT_ID,
RANK () OVER (PARTITION BY G.USER_ID  ORDER BY S.CREATED_DATE ) AS RANK_NO
 FROM GOLDUSER_SIGNUP G 
JOIN SALES S ON G.USER_ID = S. USERID
WHERE S.CREATED_DATE < G.GOLD_SIGNUP_DATE)
SELECT USER_ID, PRODUCT_ID FROM CTE WHERE RANK_NO = 1;

-- what is total orders and amount spent for each member before they become a member?

SELECT G.USER_ID ,G.GOLD_SIGNUP_DATE,S.CREATED_DATE,SUM(P.PRICE)
FROM GOLDUSER_SIGNUP G 
JOIN SALES S ON G.USER_ID = S. USERID
JOIN PRODUCT P ON S.PRODUCT_ID = P.PRODUCT_ID
WHERE S.CREATED_DATE < G.GOLD_SIGNUP_DATE
GROUP BY 1
ORDER BY 1;


-- If buying each product generates points for eg 5rs=2 
-- zomato point and each product has different purchasing points 
-- for eg for p1 5rs=1 zomato point,for p2 2rs=1 zomato point and p3 5rs=1 zomato point 2rs =1zomato point, 
-- calculate points collected by each customer and for which product most points have been given till now.


WITH POINT_CALCULATIONS AS
(SELECT PRICE ,PRODUCT_ID,
CASE WHEN PRODUCT_ID = 1 THEN 5
WHEN PRODUCT_ID = 2 THEN 2
WHEN PRODUCT_ID = 3 THEN 5 ELSE 0 
END AS POINTS 
FROM PRODUCT),
MOST_POINT AS (SELECT S.USERID,P.PRODUCT_ID,SUM(P.PRICE) AS TOTAL_SPENT,SUM(PRICE/POINTS) AS TOTAL_POINTS,
RANK () OVER (PARTITION BY S.USERID ORDER BY (SUM(PRICE/POINTS)) DESC ) AS RANK_NO
FROM POINT_CALCULATIONS P 
JOIN SALES S ON P.PRODUCT_ID = S.PRODUCT_ID
GROUP BY 1,2)
SELECT * FROM MOST_POINT WHERE RANK_NO = 1 ;


-- In the first year after a customer joins the gold program (including the join date ) irrespective of what customer has purchased earn 5 zomato points for every 10rs 
-- spent who earned more more 1 or 3 what int earning in first yr ?

WITH AFTER_JOIN AS
(SELECT G.*,P.*,S.created_date 
FROM golduser_signup G 
JOIN SALES S ON G.USER_ID = S.USERID
JOIN PRODUCT P ON S.PRODUCT_ID = P.PRODUCT_ID
WHERE S.created_date >= G.GOLD_SIGNUP_DATE AND S.created_date <= DATE_ADD(GOLD_SIGNUP_DATE, INTERVAL 1 YEAR))
SELECT USER_ID ,PRICE, (PRICE*0.5) AS ZP FROM AFTER_JOIN
;

-- Ranking all the transaction of the customers .
SELECT S.* ,P.PRICE , RANK () OVER (PARTITION BY S.USERID ORDER BY S.CREATED_DATE ) AS TRNXS_NU
FROM SALES S 
JOIN PRODUCT P ON S.PRODUCT_ID = P.PRODUCT_ID ;




























