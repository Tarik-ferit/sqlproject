/*
Customer Segmentation
Categorize customers based on their frequency of visits. The following steps will guide you. If you want, you can track your own way.
1. Create a “view” that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)


 ***************** ACIKLAMA  *****************

-- Lead ile customer segmentation yaparken isimlendirmeler dogru oldu. Ancak retention rate hesaplarken satirlar bir ust satira kaymis oldu. Ornek olarak 2009 Subat ayinda alisverislerin retention_rate'i Ocak ayi hizasinda geldi.

-- Bir kisi ayni ayda birden fazla alisveris yapti ise, time_diff '0' geliyor. Bunlar false bicimde regular gorunuyordu. Cunku bizim ilgi odagimiz sadece gecen ay alisveris yapmis musterilerin bu ay da alisveris yapti ise regular gorunmesi. Ayni ay icinde iki alisveris varsa time_diff '0' oluyor. Biz buna regular demekten kacinmak icin time_diff = 1 ise 'regular' olarak isimlendirdik.

-- Lag ile islem yaptigimizda customer segmentation isimlerini tek basina olmasi gerektigi gibi isimlendiremedik. Bunun icin lead isleminde gelen NULL degerleri churn olarak isimlendirdik. Customer_segmentation sutununda lead() ve lag() fonksiyonlarindan gelen degerleri kombine olarak degerlendirdik. Tek siparisi olanlar churn; birden fazla siparisi varsa a) ilk siparis first_order, b) time_diff 1 ise regular, c) time_diff > 1 ise lagger, d) son siparisi ise churn olarak isimlendirildi. */

USE Project;

DROP VIEW monthly_visit_log

CREATE VIEW monthly_visit_log AS (
	SELECT DISTINCT Ord_ID, Cust_ID, YEAR(Order_Date) [Year], MONTH(Order_Date) [Month]
	FROM e_commerce_data
	)

SELECT * FROM monthly_visit_log

/* 2. Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning business) */

DROP VIEW monthly_visit_count


CREATE VIEW monthly_visit_count AS(
	SELECT DISTINCT [Year], [Month], 
		COUNT(Ord_ID) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month] ) monthly_visit_count
	FROM monthly_visit_log
	--ORDER BY [Year], [Month]
	)

SELECT * FROM monthly_visit_count
ORDER BY [Year], [Month]

-- Second Solution

CREATE VIEW monthly_visit_count AS(
	SELECT *
	FROM(
		SELECT [Year], [Month], COUNT(*) AS MonthlyVisits
		FROM monthly_visit_log
		GROUP BY [Year], [Month]
		) subq
	ORDER BY [Year], [Month]
	)

-- 3. For each visit of customers, create the next month of the visit as a separate column.

DROP VIEW time_lapse

CREATE VIEW time_lapse AS (
	SELECT * ,
		LEAD([Year]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) next_visit_year,
		LEAD([Month]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) next_visit_month,
		LAG([Year]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) previous_visit_year,
		LAG([Month]) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID, [Year], [Month]) previous_visit_month
	FROM monthly_visit_log
	--ORDER BY [Cust_ID], [Year], [Month]
	)

SELECT * FROM time_lapse

-- 4. Calculate the monthly time gap between two consecutive visits by each customer.

DROP VIEW time_diff_months

CREATE VIEW time_diff_months AS		(
	SELECT *,
		(([Year]- previous_visit_year) * 12) + ([Month] - previous_visit_month) time_diff
	FROM time_lapse
	)

SELECT *
FROM time_diff_months


/*5. Categorise customers using average time gaps. Choose the most fitted labeling model for you.
	For example:
	o Labeled as churn if the customer hasn't made another purchase in the months since they made their first purchase.
	o Labeled as regular if the customer has made a purchase every month.
	Etc. */

DROP VIEW segmentation

CREATE VIEW segmentation AS (
	SELECT *,
		CASE
			WHEN time_diff = 1 THEN 'regular' -- 0 indicates that a purchase was made in the same month. We are interested in those who made in the past month.
			WHEN next_visit_month IS NULL THEN 'churn'
			WHEN time_diff IS NULL THEN 'first_order'
			WHEN time_diff > 1 THEN 'lagger'	
		END AS customer_segment
	FROM time_diff_months
	) 

SELECT *
FROM segmentation
--WHERE Cust_ID = 'Cust_1001'
--ORDER BY  [Year], [Month]



----------------- Month-Wise Retention Rate -----------------------
-- 1. Find the number of customers retained month-wise. (You can use time gaps)

SELECT *
FROM segmentation
WHERE [Year]=2009 AND [Month]=1 /*AND customer_segment = 'regular'*/
ORDER BY [Year], [Month]

SELECT DISTINCT [Year], [Month],
	SUM(CASE WHEN customer_segment = 'regular' THEN 1 END) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) count_regular
FROM segmentation
ORDER BY [Year], [Month]

--2. Calculate the month-wise retention rate.

SELECT DISTINCT [Year], [Month],
	SUM(CASE WHEN customer_segment = 'regular' THEN 1 END) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) count_regular,
	COUNT(Ord_ID) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) count_total,
	CAST(1.0 * SUM(CASE WHEN customer_segment = 'regular' THEN 1 END) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) / COUNT(Ord_ID) OVER (PARTITION BY [Year], [Month] ORDER BY [Year], [Month]) AS DECIMAL(5,2)) retention_rate
FROM segmentation
ORDER BY [Year], [Month]
