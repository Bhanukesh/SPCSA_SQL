create database SPCSA;
use spcsa;
create table sales_data ( InvoiceNO VARCHAR(10), StockCode varchar(10), Decription text, Quantity INT, Invoive Datetime, 
						UnitPrice decimal (10,2), CustomerID Int, Country VARCHAR(50) ); 
                        
# First 10 Rows of the Dataset Command                         
select * from onlineretail LIMIT 10; 

# Checking the Size of the Dataset                      
select count(*) from onlineretail;

# Missing Values Commad
SELECT COUNT(*) AS missing_count, 'Invoice_No' AS column_name FROM onlineretail WHERE Invoice_No IS NULL
UNION ALL
SELECT COUNT(*) AS missing_count, 'Stock_Code' AS column_name FROM onlineretail WHERE Stock_Code IS NULL
UNION ALL
SELECT COUNT(*) AS missing_count, 'Description' AS column_name FROM onlineretail WHERE Description IS NULL
UNION ALL
SELECT COUNT(*) AS missing_count, 'Quantity' AS column_name FROM onlineretail WHERE Quantity IS NULL
UNION ALL
SELECT COUNT(*) AS missing_count, 'Invoice_Date' AS column_name FROM onlineretail WHERE Invoice_Date IS NULL
UNION ALL
SELECT COUNT(*) AS missing_count, 'Unit_Price' AS column_name FROM onlineretail WHERE Unit_Price IS NULL
UNION ALL
SELECT COUNT(*) AS missing_count, 'Customer_ID' AS column_name FROM onlineretail WHERE Customer_ID IS NULL
UNION ALL
SELECT COUNT(*) AS missing_count, 'Country' AS column_name FROM onlineretail WHERE Country IS NULL;

# All Countries Names and Unit Price Values Command
SELECT DISTINCT Country FROM onlineretail;
Select distinct Unit_Price from onlineretail; 
select distinct Invoice_Date from onlineretail;

# Min and Max Values Command
select min(Unit_price) from onlineretail;
select max(Unit_price) from onlineretail;

# Summary Statistics for Numerical Columns
SELECT MIN(Quantity) AS min_quantity, MAX(Quantity) AS max_quantity,
       AVG(Quantity) AS avg_quantity,
       MIN(Unit_Price) AS min_price, MAX(Unit_Price) AS max_price,
       AVG(Unit_Price) AS avg_price
FROM onlineretail;

# Total Sales Revenue (Calculate the total sales revenue to get an overall idea of the dataset's scale)
SELECT SUM(Quantity * Unit_Price) AS Total_Sales_Revenue FROM onlineretail;

# Sales Breakdown by Country (Understanding where your sales are coming from can help identify key markets)
SELECT Country, SUM(Quantity * Unit_Price) AS Sales_Revenue
FROM onlineretail
GROUP BY Country
ORDER BY Sales_Revenue DESC; # Highest UK and Lowest Netherlands

# Top Selling Products (Identify which items are the most popular in terms of units sold)
SELECT Description, SUM(Quantity) AS Total_Sold
FROM onlineretail
GROUP BY Description
ORDER BY Total_Sold DESC
LIMIT 10; # World war 2... is the most selling and Assorted Colour... is the least selling

# Average Transaction Value (This metric can help understand spending behavior)
SELECT AVG(Quantity * Unit_Price) AS Average_Transaction_Value FROM onlineretail;

# Monthly Sales Trend (Understanding how sales fluctuate over time can help in forecasting and planning)
SELECT Invoice_Date FROM onlineretail LIMIT 10;
SELECT COUNT(*) FROM onlineretail WHERE Invoice_Date IS NULL;
SELECT LEFT(Invoice_Date, 7) AS Month, SUM(Quantity * Unit_Price) AS Monthly_Sales
FROM onlineretail
GROUP BY Month
ORDER BY Month;

# Step 1: Calculating RFM Metrics

# SQL Query to Calculate RFM Metrics
SELECT 
    Customer_ID,
    DATEDIFF(CURDATE(), MAX(STR_TO_DATE(Invoice_Date, '%d-%m-%Y %H:%i'))) AS Recency,
    COUNT(DISTINCT Invoice_No) AS Frequency,
    SUM(Quantity * Unit_Price) AS Monetary
FROM onlineretail
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID
ORDER BY Recency, Frequency DESC, Monetary DESC;

# (SELECT 
    CustomerID,
    DATEDIFF(CURDATE(), MAX(InvoiceDate)) AS Recency,  -- Days since last purchase
    COUNT(DISTINCT InvoiceNo) AS Frequency,  -- Count of transactions
    SUM(Quantity * UnitPrice) AS Monetary  -- Total amount spent
FROM onlineretail
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY Recency, Frequency DESC, Monetary DESC;) This code is wrong, explaination is mentioned down.

# (1. Date Format Correction
The initial problem was that MySQL was not recognizing your Invoice_Date as a date type because it was stored in a string format
 (DD-MM-YYYY HH:MM). MySQL requires a proper date type to perform date arithmetic like calculating differences.
To fix this:
We used the STR_TO_DATE() function to convert the string representation of your dates into a MySQL-compatible date type.
The format specifier %d-%m-%Y %H:%i tells MySQL exactly how to interpret each part of the date string:
%d - Day of the month as a numeric value (01 to 31)
%m - Month of the year as a numeric value (01 to 12)
%Y - Year as a four-digit numeric value
%H - Hour of the day (00 to 23)
%i - Minutes past the hour (00 to 59)
2. RFM Calculation Adjustments
We recalculated the RFM (Recency, Frequency, Monetary) values using this correctly formatted date:
Recency: The DATEDIFF() function was used to find the difference in days between the current date (CURDATE()) and 
the most recent purchase date (MAX(Invoice_Date)). 
This required the dates to be in a proper date format, which we achieved with STR_TO_DATE().
Frequency: We counted the distinct InvoiceNo per customer to determine how many times they purchased.
Monetary: We calculated the total money spent by each customer by summing up Quantity * UnitPrice.
3. Grouping and Ordering
We grouped the results by CustomerID to ensure we calculated the RFM metrics per customer.
The results were ordered by Recency, Frequency DESC, and Monetary DESC to prioritize customers who have recently made purchases, 
those who purchase frequently, and those who spend the most, respectively.
Summary
This approach allows you to properly utilize date operations in SQL and provides a solid foundation for advanced data analysis, 
like customer segmentation based on purchasing behavior. You now have a dataset organized by key marketing metrics,
which can inform strategies to enhance customer engagement and retention.)

# Step 2: RFM Segmentation
SELECT Invoice_Date, STR_TO_DATE(Invoice_Date, '%d-%m-%Y %H:%i') AS Converted_Date
FROM onlineretail
LIMIT 10;

SELECT Invoice_Date, STR_TO_DATE(TRIM(Invoice_Date), '%d-%m-%Y %H:%i') AS Converted_Date
FROM onlineretail
LIMIT 10;

SELECT
    Customer_ID,
    Recency,
    Frequency,
    Monetary,
    NTILE(5) OVER (ORDER BY Recency ASC) AS R_Score,  -- Lower recency, higher score
    NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,  -- Higher frequency, higher score
    NTILE(5) OVER (ORDER BY Monetary DESC) AS M_Score  -- Higher monetary, higher score
FROM
    (SELECT 
        Customer_ID,
        DATEDIFF(CURDATE(), MAX(STR_TO_DATE(TRIM(Invoice_Date), '%d-%m-%Y %H:%i'))) AS Recency,
        COUNT(DISTINCT Invoice_No) AS Frequency,
        SUM(Quantity * Unit_Price) AS Monetary
    FROM onlineretail
    WHERE Customer_ID IS NOT NULL
    GROUP BY Customer_ID) AS RawData
ORDER BY Customer_ID;

# (The issues you initially encountered with the RFM query were primarily due to how the Invoice_Date data was 
formatted and handled within your SQL environment. Here's a breakdown of why the original attempts didn't work and 
what changed to make it successful:
1. Date Format and String Handling Issues
Invisible Characters or Whitespace: Your Invoice_Date values likely contained extra spaces or non-visible characters that were not 
initially apparent. These extraneous characters can prevent functions like STR_TO_DATE() from correctly parsing the string as 
a date because the function requires an exact match to the format pattern specified. By using TRIM(), 
we removed these potential invisible characters or any leading/trailing whitespace, allowing the date conversion to succeed.
2. Assumptions About Date Format
Incorrect Assumptions: Initially, the exact format of Invoice_Date might have been assumed incorrectly. 
Through trial and error, and especially through examining the data directly and using diagnostic queries, 
you were able to confirm the exact format and thereby correctly specify it in the STR_TO_DATE() function.
3. Error Handling in SQL
Diagnostic Queries: Running queries to directly output the conversion results (as you did) and 
to check for entries that could not be converted (where STR_TO_DATE() returned NULL) helped
in diagnosing the problem more precisely. Without such diagnostics, pinpointing the exact cause of the 
failure in SQL functions that depend on precise formatting can be challenging.
4. SQL Function Specificity
Format String Specificity: SQL date functions are very specific about format strings. 
Any deviation from the expected date-time string structure, including mismatches in separators, the order of date and time components, 
or unexpected characters, will lead to errors or NULL results.
Lessons Learned:
Always Validate Data Formats: Especially when working with external or unfamiliar datasets, validate and 
clean the data formats early in your data handling process.
Use Diagnostic Tools: Use SQL's diagnostic capabilities (like viewing converted data or checking for NULLs post-conversion) 
to understand issues.
Be Specific with SQL Functions: Ensure that format strings in functions like STR_TO_DATE() are exactly aligned with your data's format.
This experience underlines the importance of thorough data inspection and understanding the functions and their requirements in SQL. 
You did a great job iterating through the solutions until finding one that worked, which is a key skill in data management and analysis.)

# Step 3: RFM Score-Based Segmentation (Define Segments: You can define segments based on RFM scores. 
A common approach is to label customers as Champions, Loyal, Potential, 
At Risk, and others based on their score combinations)






