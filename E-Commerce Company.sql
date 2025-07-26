USE E_COMMERCE_COMPANY;

/* Q.1. You can analyze all the tables by describing their contents.
-- Task: Describe the Tables:
Customers
Products
Orders
OrderDetails */

DESC Customers;
DESC Products;
DESC Orders;
DESC OrderDetails;


/* Q.2. Identify the top 3 cities with the highest number of customers to determine 
key markets for targeted marketing and logistic optimization.
Hint:
Use the “Customers” Table.
Return the result table limited to top 3 locations in descending order */

SELECT Location, COUNT(*) AS Number_of_Customers
FROM Customers
GROUP BY Location
ORDER BY Number_of_Customers
DESC
LIMIT 3;

/* Q.3. Determine the distribution of customers by the number of orders placed.
This insight will help in segmenting customers into one-time buyers, occasional shoppers, 
and regular customers for tailored marketing strategies.
Hint:
- Use the “Orders” table.
- Return the result table which helps you to segment customers 
on the basis of the number of orders in ascending order.
*/

SELECT No_of_Orders, COUNT(Customer_id) AS CustomerCount
from (
SELECT Customer_ID, COUNT(Order_id) AS No_OF_Orders
FROM ORDERS 
GROUP BY Customer_ID
ORDER BY Customer_ID
) AS Customer_segment
group by NO_of_Orders
order by NO_of_Orders
asc;
-- Alternative

WITH CustomerSegment AS (
SELECT Customer_ID, Count(Order_ID) AS NumberOfOrders
FROM Orders
GROUP BY Customer_ID
)
SELECT NumberOfOrders, COUNT(Customer_ID) AS CustomerCount
FROM CustomerSegment
GROUP BY NumberOfOrders
ORDER BY NumberOfOrders;

/* Q.4. Identify products where the average purchase quantity per order is 2 but with a high total revenue,
 suggesting premium product trends.
Hint:
Use “OrderDetails”.
Return the result table which includes average quantity and the total revenue in descending order.
*/

SELECT Product_id, AVG(Quantity) AS AverageQuantity,
SUM(Quantity * Price_per_unit) AS TotalRevenue
FROM OrderDetails
GROUP BY Product_id
HAVING AverageQuantity = 2
ORDER BY TotalRevenue;

/* Q.5. For each product category, calculate the unique number of customers purchasing from it.
 This will help understand which categories have wider appeal across the customer base.
Hint:
Use the “Products”, “OrderDetails” and “Orders” table.
Return the result table which will help you count the unique number of customers in descending order.
*/

WITH CUSTOMER_REACH AS
(
SELECT P.CATEGORY, O.CUSTOMER_ID, 
COUNT(DISTINCT(O.ORDER_ID)) AS ORDER_COUNT
FROM ORDERS O
JOIN ORDERDETAILS OD ON O.ORDER_ID = OD.ORDER_ID
JOIN PRODUCTS P ON OD.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.CATEGORY, O.CUSTOMER_ID
)
SELECT CATEGORY,
COUNT(DISTINCT(CUSTOMER_ID)) AS UNIQUE_CUSTOMERS
FROM CUSTOMER_REACH
GROUP BY CATEGORY
ORDER BY UNIQUE_CUSTOMERS
DESC
;

-- ALTERNATIVE

WITH CUSTOMER_REACH AS
(
SELECT DISTINCT O.ORDER_ID, P.CATEGORY, O.CUSTOMER_ID
FROM ORDERS O
JOIN ORDERDETAILS OD ON O.ORDER_ID = OD.ORDER_ID
JOIN PRODUCTS P ON OD.PRODUCT_ID = P.PRODUCT_ID
)
SELECT CATEGORY, COUNT(DISTINCT(CUSTOMER_ID)) AS UNIQUE_CUSTOMER
FROM CUSTOMER_REACH
GROUP BY CATEGORY
ORDER BY UNIQUE_CUSTOMER
DESC
;

-- ALTERNATIVE

SELECT P.CATEGORY, COUNT(DISTINCT O.CUSTOMER_ID) AS UNIQUE_CUSTOMERS
FROM ORDERS O
JOIN ORDERDETAILS OD ON O.ORDER_ID = OD.ORDER_ID
JOIN PRODUCTS P ON OD.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.CATEGORY
ORDER BY UNIQUE_CUSTOMERS DESC;


/* Q.6. Analyze the month-on-month percentage change in total sales to identify growth trends.
Hint:
Use the “Orders” table.
Return the result table which will help you get the month (YYYY-MM), 
Total Sales and Percent Change of the total amount 
(Present month value- Previous month value/ Previous month value)*100.
The resulting change in percentage should be rounded to 2 decimal places.
*/

WITH MONTHLY_SALES AS
(
SELECT 
DATE_FORMAT(ORDER_DATE,"%Y-%m") AS MONTH,
SUM(TOTAL_AMOUNT) AS TOTALSALES
FROM ORDERS
GROUP BY MONTH
)
SELECT MONTH,
TOTALSALES,
ROUND(CASE
WHEN LAG(TOTALSALES)OVER(ORDER BY MONTH) IS NULL THEN NULL
ELSE (TOTALSALES - LAG(TOTALSALES) OVER(ORDER BY MONTH))/
LAG(TOTALSALES)OVER(ORDER BY MONTH)*100
END,
2) AS PERCENTCHANGE
FROM MONTHLY_SALES
ORDER BY MONTH;

-- BETTER ALTERNATIVE

WITH MONTHLY_SALES AS
(
SELECT DATE_FORMAT(ORDER_DATE,"%Y-%m") AS MONTH,
SUM(TOTAL_AMOUNT) AS TOTALSALES
FROM ORDERS
GROUP BY MONTH
)
SELECT MONTH, TOTALSALES, 
ROUND((TOTALSALES - LAG(TOTALSALES) OVER (ORDER BY MONTH))*100/
LAG(TOTALSALES) OVER (ORDER BY MONTH),2) AS PERCENTCHANGE
FROM MONTHLY_SALES
ORDER BY MONTH;


/* Q.7. Examine how the average order value changes month-on-month.
Insights can guide pricing and promotional strategies to enhance order value.
Hint:
Use the “Orders” Table.
Return the result table which will help you get the month (YYYY-MM), 
Average order value and Change in the average order value (Present month value- Previous month value).
Both the resulting AvgOrderValue and ChangeInValue column should be rounded to two decimal places, 
with the final results ordered in descending order by ChangeInValue.
*/

WITH MLYAVG AS
( 
SELECT DATE_FORMAT(ORDER_DATE,"%Y-%m") AS MONTH,
AVG(TOTAL_AMOUNT) AS AVGORDERVALUE
FROM ORDERS
GROUP BY MONTH
),
PREVAVG AS
(
SELECT MONTH,
AVGORDERVALUE,
LAG(AVGORDERVALUE) OVER (ORDER BY MONTH)
AS PREVMONTHVALUE
FROM MLYAVG
)
SELECT MONTH,
AVGORDERVALUE,
ROUND(AVGORDERVALUE - PREVMONTHVALUE,2) AS CHANGEINVALUE
FROM PREVAVG
ORDER BY CHANGEINVALUE 
DESC
;

-- ALTERNATIVE

SET @PREV_VALUE = NULL;
SELECT 
MONTH,
AVGORDERVALUE,
ROUND(AVGORDERVALUE - @PREV_VALUE,2) AS CHANGEINVALUE,
@PREV_VALUE := AVGORDERVALUE
FROM (
SELECT
DATE_FORMAT(ORDER_DATE,'%Y-%m') AS MONTH,
AVG(TOTAL_AMOUNT) AS AVGORDERVALUE
FROM ORDERS
GROUP BY MONTH  
ORDER BY MONTH
) AS MONTHLYAVG
;

/* Q.8. Based on sales data, identify products with the fastest turnover rates, 
suggesting high demand and the need for frequent restocking.
Hint:
Use the “OrderDetails” table.
Return the result table limited to top 5 product according to the SalesFrequency column in 
descending order.
*/

SELECT PRODUCT_ID,
COUNT(ORDER_ID) AS SALESFREQUENCY
FROM ORDERDETAILS
GROUP BY PRODUCT_ID
ORDER BY SALESFREQUENCY
DESC
LIMIT 5;

/* Q.9. List products purchased by less than 40% of the customer base, 
indicating potential mismatches between inventory and customer interest.
Hint:
Use the “Products”, “Orders”, “OrderDetails” and “Customers” table.
Return the result table which will help you get the product names 
along with the count of unique customers who belong to the lower 40% of the customer pool.
*/

WITH TOTALCUSTOMER AS
(
SELECT COUNT(DISTINCT CUSTOMER_ID ) AS TOTAL_CUSTOMER_COUNT
FROM CUSTOMERS
),
TOTALPRODUCT AS 
(
SELECT 
P.PRODUCT_ID,
P.NAME,
COUNT(DISTINCT O.CUSTOMER_ID) AS CUSTOMERCOUNT
FROM ORDERS O
JOIN ORDERDETAILS OD ON O.ORDER_ID = OD.ORDER_ID
JOIN PRODUCTS P ON OD.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.PRODUCT_ID, P.NAME
)
SELECT 
TP.PRODUCT_ID,
TP.NAME,
ROUND(TP.CUSTOMERCOUNT*100/TC.TOTAL_CUSTOMER_COUNT) AS UNIQUECUSTOMERCOUNT
FROM TOTALPRODUCT TP 
CROSS JOIN TOTALCUSTOMER TC
WHERE CUSTOMERCOUNT < TOTAL_CUSTOMER_COUNT * 0.4
ORDER BY UNIQUECUSTOMERCOUNT ASC;

/* Q.10. Evaluate the month-on-month growth rate in the customer 
base to understand the effectiveness of marketing campaigns and market expansion efforts.
Hint:
Use the “Orders” table.
Return the result table which will help you get the count of the number of customers 
who made the first purchase on monthly basis.
The resulting table should be ascendingly ordered according to the month.
*/

WITH FIRSTPURCHASE AS
(
SELECT DATE_FORMAT(MIN(ORDER_DATE),'%Y-%m') AS FIRST_PURCHASE_MONTH,
COUNT(DISTINCT CUSTOMER_ID) AS TOTALCUSTOMER
FROM ORDERS
GROUP BY CUSTOMER_ID
)
SELECT FIRST_PURCHASE_MONTH,
SUM(TOTALCUSTOMER) AS TOTALNEWCUSTOMER
FROM FIRSTPURCHASE
GROUP BY 1
ORDER BY 1 
;
-- ALTERNATIVE

WITH FIRSTPURCHASE AS
(
SELECT CUSTOMER_ID,
DATE_FORMAT(MIN(ORDER_DATE),'%Y-%m') AS FIRSTPURCHASEMONTH
FROM ORDERS
GROUP BY CUSTOMER_ID
)
SELECT 
FIRSTPURCHASEMONTH,
COUNT(*) AS TOTALNEWCUSTOMERS
FROM FIRSTPURCHASE
GROUP BY 1
ORDER BY 1;

/* Q.11. Identify the months with the highest sales volume, aiding in planning for stock levels,
 marketing efforts, and staffing in anticipation of peak demand periods.
Hint:
Use the “Orders” table.
Return the result table which will help you get the month (YYYY-MM) and 
the Total sales made by the company limiting to top 3 months.
The resulting table should be in descending order suggesting the highest sales month.
*/

SELECT
DATE_FORMAT(ORDER_DATE,'%Y-%m') AS MONTH,
SUM(TOTAL_AMOUNT) AS TOTALSALES
FROM ORDERS
GROUP BY 1
ORDER BY 2
DESC
LIMIT 3;
