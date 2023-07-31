
/*
Customer Segmentation
Categorize customers based on their frequency of visits. The following steps will guide you. If you want, you can track your own way.
1. Create a “view” that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)
2. Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning business)
3. For each visit of customers, create the next month of the visit as a separate column.
4. Calculate the monthly time gap between two consecutive visits by each customer.
5. Categorise customers using average time gaps. Choose the most fitted labeling model for you.
For example:
o Labeled as churn if the customer hasn't made another purchase in the months since they made their first purchase.
o Labeled as regular if the customer has made a purchase every month.
Etc.

Month-Wise Retention Rate
Find month-by-month customer retention ratei since the start of the business.
There are many different variations in the calculation of Retention Rate. But we will try to calculate the month-wise retention rate in this project.
So, we will be interested in how many of the customers in the previous month could be retained in the next month.
Proceed step by step by creating “views”. You can use the view you got at the end of the Customer Segmentation section as a source.
1. Find the number of customers retained month-wise. (You can use time gaps)
2. Calculate the month-wise retention rate.
Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total Number of Customers in the Current Month
*/

CREATE VIEW cust_segment AS(
	SELECT *,
		CASE
			WHEN time_diff = 1 THEN 'regular' -- 0 indicates that a purchase was made in the same month. We are interested in those who made in the past month.
			WHEN next_visit_month IS NULL THEN 'churn'
			WHEN time_diff IS NULL THEN 'first_order'
			WHEN time_diff > 1 THEN 'lagger'	
			END AS customer_segment
	FROM (
		SELECT *,
				LEAD([Year]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) next_visit_year,
				LEAD([Month]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) next_visit_month,
				LAG([Year]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) previous_visit_year,
				LAG([Month]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) previous_visit_month,
				(([Year]- LAG([Year]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month])) * 12) + ([Month] - LAG([Month]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month])) time_diff
		FROM (
			SELECT DISTINCT Ord_ID, Cust_ID, YEAR(Order_Date) AS [Year], MONTH(Order_Date) AS [Month]
			FROM e_commerce_data
			) subq1
			) subq2
		);

SELECT DISTINCT [Year], [Month],
	SUM(CASE WHEN customer_segment = 'regular' THEN 1 END) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) count_regular,
	COUNT(Ord_ID) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) count_total,
	CAST(1.0 * SUM(CASE WHEN customer_segment = 'regular' THEN 1 END) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) / COUNT(Ord_ID) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) AS DECIMAL(5,2)) retention_rate
FROM cust_segment
ORDER BY [Year], [Month]


---- cte ---


WITH t1 AS(
	SELECT *,
		CASE
			WHEN time_diff = 1 THEN 'regular' -- 0 indicates that a purchase was made in the same month. We are interested in those who made in the past month.
			WHEN next_visit_month IS NULL THEN 'churn'
			WHEN time_diff IS NULL THEN 'first_order'
			WHEN time_diff > 1 THEN 'lagger'	
			END AS customer_segment
	FROM (
		SELECT *,
				LEAD([Year]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) next_visit_year,
				LEAD([Month]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) next_visit_month,
				LAG([Year]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) previous_visit_year,
				LAG([Month]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) previous_visit_month,
				(([Year]- LAG([Year]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month])) * 12) + ([Month] - LAG([Month]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month])) time_diff
		FROM (
			SELECT DISTINCT Ord_ID, Cust_ID, YEAR(Order_Date) AS [Year], MONTH(Order_Date) AS [Month]
			FROM e_commerce_data
			) subq1
			) subq2
		)
SELECT DISTINCT [Year], [Month],
	SUM(CASE WHEN customer_segment = 'regular' THEN 1 END) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) count_regular,
	COUNT(Ord_ID) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) count_total,
	CAST(1.0 * SUM(CASE WHEN customer_segment = 'regular' THEN 1 END) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) / COUNT(Ord_ID) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) AS DECIMAL(5,2)) retention_rate
FROM t1
ORDER BY [Year], [Month];



/*-- MONTH-WISE CUSTOMER RETENTION RATE IN SINGLE CODE BLOCK --*/
	SELECT DISTINCT [Year], [Month],
		SUM(CASE WHEN time_diff = 1 THEN 1 END) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) count_regular,
		COUNT(Ord_ID) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) count_total,
		CAST(1.0 * SUM(CASE WHEN time_diff = 1 THEN 1 END) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) / COUNT(Ord_ID) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) AS DECIMAL(5,2)) retention_rate
	FROM (
		SELECT *,
				LAG([Year]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) previous_visit_year,
				LAG([Month]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) previous_visit_month,
				(([Year]- LAG([Year]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month])) * 12) + ([Month] - LAG([Month]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month])) time_diff
		FROM (
			SELECT DISTINCT Ord_ID, Cust_ID, YEAR(Order_Date) AS [Year], MONTH(Order_Date) AS [Month]
			FROM e_commerce_data
			) subq1
			) subq2
	ORDER BY [Year], [Month]


--INNER JOIN USING WHERE EXAMPLE--

SELECT *
FROM SALES A
INNER JOIN CUSTOMERS B ON A.CUST_ID = B.CUST_ID 

SELECT *
FROM SALES A, CUSTOMERS B
WHERE A.CUST_ID = B.CUST_ID




SELECT Cust_ID, [Year], [Month],
       DATEDIFF(MONTH, Order_Date, LEAD(Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date)) AS TimeGapInMonths
FROM (
    SELECT DISTINCT Ord_ID, Cust_ID, YEAR(Order_Date) AS [Year], MONTH(Order_Date) AS [Month], Order_Date
    FROM e_commerce_data
) AS VisitData;