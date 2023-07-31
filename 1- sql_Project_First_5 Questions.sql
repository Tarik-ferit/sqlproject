--1. Find the top 3 customers who have the maximum count of orders.

SELECT TOP 3 Cust_ID, Customer_Name, COUNT(Ord_ID) order_count
FROM e_commerce_data
GROUP BY Cust_ID, Customer_Name
ORDER BY order_count DESC


WITH t1 AS (
	SELECT Cust_ID,COUNT(Ord_ID) order_count
	FROM e_commerce_data
	GROUP BY Cust_ID
	)
SELECT DISTINCT TOP 3 t1.Cust_ID, t2.Customer_Name, t1.order_count
FROM t1
INNER JOIN e_commerce_data t2 ON t1.Cust_ID = t2.Cust_ID
ORDER BY order_count DESC


SELECT DISTINCT TOP 3 Cust_ID, Customer_Name,
	COUNT(Ord_ID) OVER (PARTITION BY Cust_Id) order_count
FROM e_commerce_data
ORDER BY order_count DESC


--2. Find the customer whose order took the maximum time to get shipping.

SELECT TOP 1 Ord_ID, Cust_ID, Customer_Name, DaysTakenForShipping
FROM e_commerce_data
ORDER BY DaysTakenForShipping DESC

SELECT TOP 1 Cust_ID, Customer_Name, DaysTakenForShipping
FROM e_commerce_data
ORDER BY DaysTakenForShipping DESC


--3. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011

--USING IN OPERATOR

SELECT MONTH(Order_Date) "month", DATENAME(MONTH, Order_Date) month_name, COUNT(DISTINCT Cust_ID) customer_count
FROM e_commerce_data
WHERE YEAR(Order_Date) = 2011 AND Cust_ID IN (
	SELECT DISTINCT Cust_ID
	FROM e_commerce_data
	WHERE Order_Date LIKE '2011-01-%' )
GROUP BY MONTH(Order_Date), DATENAME(MONTH, Order_Date)
ORDER BY 1


-- SOLUTION USING EXISTS

SELECT MONTH(Order_Date) "month", DATENAME(MONTH, Order_Date) month_name, COUNT(DISTINCT Cust_ID) customer_count
FROM e_commerce_data a
WHERE YEAR(Order_Date) = 2011 AND EXISTS (
	SELECT 1
	FROM e_commerce_data
	WHERE Order_Date LIKE '2011-01-%' 
	AND a.Cust_ID = Cust_ID )
GROUP BY MONTH(Order_Date), DATENAME(MONTH, Order_Date)
ORDER BY 1

/*
SELECT MONTH(Order_Date)[month], DATENAME(MONTH,Order_Date) month_name,
		COUNT(distinct Cust_ID) cust_cnt
FROM e_commerce_data
WHERE  YEAR(Order_Date)=2011 AND Cust_ID IN
		(SELECT DISTINCT Cust_ID
		FROM e_commerce_data
		WHERE Order_Date like'2011-01-%'
)
GROUP BY datename(month,Order_Date),month(Order_Date) 
ORDER BY month(Order_Date) */

SELECT
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 1 THEN Cust_ID END) AS January,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 2 THEN Cust_ID END) AS February,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 3 THEN Cust_ID END) AS March,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 4 THEN Cust_ID END) AS April,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 5 THEN Cust_ID END) AS May,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 6 THEN Cust_ID END) AS June,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 7 THEN Cust_ID END) AS July,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 8 THEN Cust_ID END) AS August,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 9 THEN Cust_ID END) AS September,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 10 THEN Cust_ID END) AS October,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 11 THEN Cust_ID END) AS November,
    COUNT(DISTINCT CASE WHEN MONTH(Order_Date) = 12 THEN Cust_ID END) AS December
FROM e_commerce_data
WHERE YEAR(Order_Date) = 2011 AND Cust_ID IN 
	(
	SELECT DISTINCT Cust_ID
	FROM e_commerce_data
	WHERE Order_Date LIKE '2011-01-%'
	);



--4. Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID.

WITH cte AS(
SELECT *,
	ROW_NUMBER () OVER (PARTITION BY Cust_ID ORDER BY Order_Date) nth_order ,
	lead(Order_Date,2) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) third_ord,
	DATEDIFF(DAY,Order_Date,lead(Order_Date,2) OVER (PARTITION BY Cust_ID ORDER BY Order_Date)) day_diff
FROM (
		SELECT DISTINCT Ord_ID ,Cust_ID, Customer_Name,Order_Date
		FROM e_commerce_data
) subq
)
SELECT *
FROM cte
WHERE nth_order=1 and third_ord is not null


WITH cte as (SELECT *,	LEAD(Order_Date,2) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) third_order_day,	DATEDIFF(DAY,Order_Date,LEAD(Order_Date,2) OVER (PARTITION BY Cust_ID ORDER BY Order_Date)) day_diff,	ROW_NUMBER() OVER(PARTITION BY Cust_ID ORDER BY Cust_ID,Order_Date) AS nth_orderFROM(	SELECT DISTINCT Ord_ID,Cust_ID,Customer_Name,Order_Date					FROM [dbo].[e_commerce_data]	--WHERE Cust_ID='Cust_100') subq)SELECT * FROM cte aWHERE nth_order=1 AND third_order_day IS NOT NULL-- Asagidaki cozum 1 adet fazladan satir getiriyor. Yukaridaki cozumle karsilastir.WITH cte as (SELECT *,	LEAD(Order_Date,2) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) third_order_day,	DATEDIFF(DAY,Order_Date,LEAD(Order_Date,2) OVER (PARTITION BY Cust_ID ORDER BY Order_Date)) day_diff,	FIRST_VALUE(Order_Date) OVER(PARTITION BY Cust_ID ORDER BY Cust_ID,Order_Date) AS first_orderFROM(	SELECT DISTINCT Ord_ID,Cust_ID,Customer_Name,Order_Date					FROM [dbo].[e_commerce_data]	--WHERE Cust_ID='Cust_100') subq)SELECT * FROM cteWHERE Order_Date=first_order AND third_order_day IS NOT NULLORDER BY Cust_ID, Order_Date


SELECT 
	Cust_ID, Order_Date, third_order,
	DATEDIFF(DAY, Order_Date, third_order) AS diff_first_third_order
FROM 
	(
		SELECT *,  
			ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) nth_order,
			LEAD(Order_Date,2) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) third_order
		FROM (
				SELECT DISTINCT Ord_ID ,Cust_ID, Customer_Name,Order_Date
				FROM e_commerce_data
				) a
	) subq
WHERE nth_order = 1 AND third_order IS NOT NULL
ORDER BY Cust_ID;

SELECT Cust_ID, Order_Date
FROM e_commerce_data
WHERE Cust_ID = 'Cust_1001'
ORDER BY Order_Date

--5. Write a query that returns customers who purchased both product 11 and product 14, as well as the ratio of these products to the total number of products purchased by the customer.

-- First Solution

SELECT Cust_ID, Customer_Name,
	SUM(CASE WHEN Prod_Id = 'Prod_11' THEN Order_Quantity END) qnty_prod_11,
	SUM(CASE WHEN Prod_Id = 'Prod_14' THEN Order_Quantity END) qnty_prod_14,
	SUM(CASE WHEN Prod_Id = 'Prod_11' THEN Order_Quantity END) + SUM(CASE WHEN Prod_Id = 'Prod_14' THEN Order_Quantity END) qnty_11_14,
	SUM(Order_Quantity) qnty_total,
	(1.0*(SUM(CASE WHEN Prod_Id = 'Prod_11' THEN Order_Quantity END) + SUM(CASE WHEN Prod_Id = 'Prod_14' THEN Order_Quantity END)) / SUM(Order_Quantity)) * 100 prcnt_11_14
FROM e_commerce_data
WHERE Cust_ID IN
(	SELECT Cust_ID
	FROM e_commerce_data
	WHERE Prod_ID = 'Prod_11'
	INTERSECT
	SELECT Cust_ID
	FROM e_commerce_data
	WHERE Prod_ID = 'Prod_14'
	--ORDER BY Cust_ID
)
GROUP BY Cust_ID, Customer_Name

--- Second Solution
SELECT DISTINCT Cust_ID, Customer_Name, qnty_prod_11_14, qnty_total, prcnt_11_14
FROM
(
SELECT *,
	SUM(CASE WHEN Prod_Id = 'Prod_11' THEN Order_Quantity ELSE 0 END) OVER (PARTITION BY Cust_Id) qnty_prod_11,
	SUM(CASE WHEN Prod_Id = 'Prod_14' THEN Order_Quantity ELSE 0 END) OVER (PARTITION BY Cust_Id) qnty_prod_14,
	SUM(CASE WHEN Prod_Id = 'Prod_11' OR Prod_Id = 'Prod_14' THEN Order_Quantity ELSE 0 END) OVER (PARTITION BY Cust_Id) qnty_prod_11_14,
	SUM(Order_Quantity) OVER (PARTITION BY Cust_Id) qnty_total,
	ROUND(CAST(SUM(CASE WHEN Prod_Id = 'Prod_11' OR Prod_Id = 'Prod_14' THEN Order_Quantity ELSE 0 END) OVER (PARTITION BY Cust_Id) AS DECIMAL(10,2)) / SUM(Order_Quantity) OVER (PARTITION BY Cust_Id) * 100,2)  prcnt_11_14
FROM e_commerce_data
WHERE Cust_ID IN (
	SELECT Cust_ID
	FROM e_commerce_data
	WHERE Prod_Id = 'Prod_11'
	INTERSECT
	SELECT Cust_ID
	FROM e_commerce_data
	WHERE Prod_ID = 'Prod_14'
) 
--ORDER BY Cust_ID, Prod_ID
) subq
ORDER BY prcnt_11_14;
go
