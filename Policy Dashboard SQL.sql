use Policy;
select * from additional_data;
select * from claims_data;
select * from customer_data;
select * from payment_data;
select * from policy_data;


-- ============================================================
--   INSURANCE POLICY DASHBOARD  –  35 KPI QUERIES
--   Database : Policy
--   Tables   : customer_data, policy_data, claims_data,
--              payment_data, additional_data
-- ============================================================

USE Policy;

-- ============================================================
-- SECTION 1 : POLICY KPIs  (Q1 – Q7)
-- ============================================================

-- Q1. Total number of policies by status
SELECT
    Status,
    COUNT(*) AS Policy_Count
FROM policy_data
GROUP BY Status
ORDER BY Policy_Count DESC;

-- Q2. Total coverage amount and average premium by policy type
SELECT
    Policy_Type,
    COUNT(*)                                              AS Policy_Count,
    CONCAT(ROUND(SUM(Coverage_Amount) / 1000000, 2), ' M') AS Total_Coverage_Amount,
    ROUND(AVG(Premium_Amount), 2)                         AS Avg_Premium_Amount
FROM policy_data
GROUP BY Policy_Type
ORDER BY Total_Coverage_Amount DESC;

-- Q3. Year-wise new policies issued
SELECT
    YEAR(STR_TO_DATE(Policy_Start_Date, '%d-%m-%Y')) AS Policy_Year,
    COUNT(*)                                          AS New_Policies
FROM policy_data
GROUP BY Policy_Year
ORDER BY Policy_Year;

-- Q4. Year-wise Active / Lapsed / Terminated policies
SELECT
    YEAR(STR_TO_DATE(Policy_End_Date, '%d-%m-%Y')) AS End_Year,
    Status,
    COUNT(*)                                        AS Policy_Count
FROM policy_data
WHERE Status IN ('Lapsed', 'Terminated', 'Active')
GROUP BY End_Year, Status
ORDER BY End_Year, Status;

-- Q5. Payment frequency distribution
SELECT
    Payment_Frequency,
    COUNT(*)                                              AS Policy_Count,
    CONCAT(ROUND(COUNT(*) * 100.0 /
           SUM(COUNT(*)) OVER (), 2), ' %')               AS Percentage
FROM policy_data
GROUP BY Payment_Frequency;

-- Q6. Average policy duration in days by policy type
SELECT
    Policy_Type,
    ROUND(AVG(DATEDIFF(
        STR_TO_DATE(Policy_End_Date,   '%d-%m-%Y'),
        STR_TO_DATE(Policy_Start_Date, '%d-%m-%Y')
    )), 0) AS Avg_Duration_Days
FROM policy_data
GROUP BY Policy_Type;

-- Q7. Top 10 customers by total coverage amount
SELECT
    c.Customer_ID,
    c.Name,
    COUNT(p.Policy_ID)                              AS Total_Policies,
    CONCAT(ROUND(SUM(p.Coverage_Amount) / 1000000, 2), ' M') AS Total_Coverage
FROM customer_data  c
JOIN policy_data    p ON c.Customer_ID = p.Customer_ID
GROUP BY c.Customer_ID, c.Name
ORDER BY SUM(p.Coverage_Amount) DESC
LIMIT 10;

-- ============================================================
-- SECTION 2 : CUSTOMER KPIs  (Q8 – Q14)
-- ============================================================

-- Q8. Customer distribution by gender
SELECT
    Gender,
    COUNT(*)                                              AS Customer_Count,
    CONCAT(ROUND(COUNT(*) * 100.0 /
           SUM(COUNT(*)) OVER (), 2), ' %')               AS Percentage
FROM customer_data
GROUP BY Gender;

-- Q9. Customer distribution by age group
SELECT
    CASE
        WHEN Age < 25              THEN 'Under 25'
        WHEN Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN Age BETWEEN 45 AND 54 THEN '45-54'
        WHEN Age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END              AS Age_Group,
    COUNT(*)         AS Customer_Count
FROM customer_data
GROUP BY Age_Group
ORDER BY Age_Group;

-- Q10. Customer distribution by marital status
SELECT
    Marital_Status,
    COUNT(*) AS Customer_Count
FROM customer_data
GROUP BY Marital_Status
ORDER BY Customer_Count DESC;

-- Q11. Top 10 occupations by number of policies held
SELECT
    c.Occupation,
    COUNT(p.Policy_ID) AS Total_Policies
FROM customer_data c
JOIN policy_data   p ON c.Customer_ID = p.Customer_ID
GROUP BY c.Occupation
ORDER BY Total_Policies DESC
LIMIT 10;

-- Q12. Customers with more than one active policy (cross-sell indicator)
SELECT
    c.Customer_ID,
    c.Name,
    COUNT(p.Policy_ID) AS Active_Policy_Count
FROM customer_data c
JOIN policy_data   p ON c.Customer_ID = p.Customer_ID
                     AND p.Status = 'Active'
GROUP BY c.Customer_ID, c.Name
HAVING Active_Policy_Count > 1
ORDER BY Active_Policy_Count DESC;

-- Q13. Average number of policies per customer
SELECT
    ROUND(COUNT(p.Policy_ID) / COUNT(DISTINCT c.Customer_ID), 2) AS Avg_Policies_Per_Customer
FROM customer_data c
LEFT JOIN policy_data p ON c.Customer_ID = p.Customer_ID;

-- Q14. Year-wise new customer acquisition
SELECT
    YEAR(STR_TO_DATE(p.Policy_Start_Date, '%d-%m-%Y')) AS Year,
    COUNT(DISTINCT c.Customer_ID)                       AS New_Customers
FROM customer_data c
JOIN policy_data   p ON c.Customer_ID = p.Customer_ID
GROUP BY Year
ORDER BY Year;

-- ============================================================
-- SECTION 3 : CLAIMS KPIs  (Q15 – Q21)
-- ============================================================

-- Q15. Total claims and amount by claim status
SELECT
    Claim_Status,
    COUNT(*)                                              AS Total_Claims,
    CONCAT(ROUND(SUM(Claim_Amount) / 1000000, 2), ' M')   AS Total_Claim_Amount,
    ROUND(AVG(Claim_Amount), 2)                           AS Avg_Claim_Amount
FROM claims_data
GROUP BY Claim_Status;

-- Q16. Year-wise claims volume and amount
SELECT
    YEAR(STR_TO_DATE(Date_of_Claim, '%d-%m-%Y'))          AS Claim_Year,
    COUNT(*)                                               AS Total_Claims,
    CONCAT(ROUND(SUM(Claim_Amount) / 1000000, 2), ' M')    AS Total_Claim_Amount
FROM claims_data
GROUP BY Claim_Year
ORDER BY Claim_Year;

-- Q17. Claim approval rate (%)
SELECT
    CONCAT(ROUND(
        SUM(CASE WHEN Claim_Status = 'Approved' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2), ' %') AS Claim_Approval_Rate_Pct
FROM claims_data;

-- Q18. Average claim settlement time in days
SELECT
    Claim_Status,
    ROUND(AVG(DATEDIFF(
        STR_TO_DATE(Settlement_Date, '%d-%m-%Y'),
        STR_TO_DATE(Date_of_Claim,   '%d-%m-%Y')
    )), 1) AS Avg_Settlement_Days
FROM claims_data
WHERE Settlement_Date IS NOT NULL
  AND Settlement_Date <> ''
GROUP BY Claim_Status;

-- Q19. Loss ratio by policy type  (Total Claims / Total Premium)
SELECT
    p.Policy_Type,
    CONCAT(ROUND(SUM(cl.Claim_Amount)  / 1000000, 2), ' M') AS Total_Claims,
    CONCAT(ROUND(SUM(p.Premium_Amount) / 1000000, 2), ' M') AS Total_Premium,
    CONCAT(ROUND(SUM(cl.Claim_Amount) /
           NULLIF(SUM(p.Premium_Amount), 0) * 100, 2), ' %') AS Loss_Ratio_Pct
FROM policy_data p
JOIN claims_data cl ON p.Policy_ID = cl.Policy_ID
GROUP BY p.Policy_Type
ORDER BY SUM(cl.Claim_Amount) / NULLIF(SUM(p.Premium_Amount), 0) DESC;

-- Q20. Top 10 policies by total claim amount
SELECT
    cl.Policy_ID,
    p.Policy_Type,
    COUNT(cl.Claim_ID)                                        AS Claim_Count,
    CONCAT(ROUND(SUM(cl.Claim_Amount) / 1000000, 2), ' M')   AS Total_Claimed
FROM claims_data cl
JOIN policy_data p ON cl.Policy_ID = p.Policy_ID
GROUP BY cl.Policy_ID, p.Policy_Type
ORDER BY SUM(cl.Claim_Amount) DESC
LIMIT 10;

-- Q21. Year-wise claim approval vs rejection vs pending
SELECT
    YEAR(STR_TO_DATE(Date_of_Claim, '%d-%m-%Y'))                  AS Year,
    SUM(CASE WHEN Claim_Status = 'Approved' THEN 1 ELSE 0 END)    AS Approved,
    SUM(CASE WHEN Claim_Status = 'Rejected' THEN 1 ELSE 0 END)    AS Rejected,
    SUM(CASE WHEN Claim_Status = 'Pending'  THEN 1 ELSE 0 END)    AS Pending
FROM claims_data
GROUP BY Year
ORDER BY Year;

-- ============================================================
-- SECTION 4 : PAYMENT KPIs  (Q22 – Q28)
-- ============================================================

-- Q22. Total revenue collected by payment status
SELECT
    Payment_Status,
    COUNT(*)                                              AS Transaction_Count,
    CONCAT(ROUND(SUM(Amount_Paid) / 1000000, 2), ' M')   AS Total_Amount
FROM payment_data
GROUP BY Payment_Status;

-- Q23. Payment method distribution
SELECT
    Payment_Method,
    COUNT(*)                                              AS Transactions,
    CONCAT(ROUND(SUM(Amount_Paid) / 1000000, 2), ' M')   AS Total_Amount,
    CONCAT(ROUND(COUNT(*) * 100.0 /
           SUM(COUNT(*)) OVER (), 2), ' %')               AS Pct_Transactions
FROM payment_data
GROUP BY Payment_Method
ORDER BY Transactions DESC;

-- Q24. Year-wise revenue trend (successful payments only)
SELECT
    YEAR(STR_TO_DATE(Date_of_Payment, '%d-%m-%Y'))        AS Payment_Year,
    CONCAT(ROUND(SUM(Amount_Paid) / 1000000, 2), ' M')    AS Total_Revenue
FROM payment_data
WHERE Payment_Status = 'Successful'
GROUP BY Payment_Year
ORDER BY Payment_Year;

-- Q25. Failed payment rate by year
SELECT
    YEAR(STR_TO_DATE(Date_of_Payment, '%d-%m-%Y'))        AS Year,
    COUNT(*)                                               AS Total_Transactions,
    SUM(CASE WHEN Payment_Status = 'Failed' THEN 1 ELSE 0 END) AS Failed_Count,
    CONCAT(ROUND(
        SUM(CASE WHEN Payment_Status = 'Failed' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2), ' %')                              AS Failed_Rate_Pct
FROM payment_data
GROUP BY Year
ORDER BY Year;

-- Q26. Average payment amount by payment method
SELECT
    Payment_Method,
    ROUND(AVG(Amount_Paid), 2) AS Avg_Payment_Amount
FROM payment_data
WHERE Payment_Status = 'Successful'
GROUP BY Payment_Method
ORDER BY Avg_Payment_Amount DESC;

-- Q27. Monthly revenue for the most recent year
SELECT
    MONTH(STR_TO_DATE(Date_of_Payment, '%d-%m-%Y'))       AS Month_Num,
    MONTHNAME(STR_TO_DATE(Date_of_Payment, '%d-%m-%Y'))   AS Month_Name,
    CONCAT(ROUND(SUM(Amount_Paid) / 1000000, 2), ' M')    AS Monthly_Revenue
FROM payment_data
WHERE Payment_Status = 'Successful'
  AND YEAR(STR_TO_DATE(Date_of_Payment, '%d-%m-%Y')) = (
      SELECT MAX(YEAR(STR_TO_DATE(Date_of_Payment, '%d-%m-%Y')))
      FROM payment_data
  )
GROUP BY Month_Num, Month_Name
ORDER BY Month_Num;

-- Q28. Customers with outstanding (failed) payments
SELECT
    c.Customer_ID,
    c.Name,
    COUNT(pay.Payment_ID)                                     AS Failed_Payments,
    CONCAT(ROUND(SUM(pay.Amount_Paid) / 1000, 2), ' K')      AS Outstanding_Amount
FROM payment_data  pay
JOIN policy_data   p ON pay.Policy_ID  = p.Policy_ID
JOIN customer_data c ON p.Customer_ID  = c.Customer_ID
WHERE pay.Payment_Status = 'Failed'
GROUP BY c.Customer_ID, c.Name
ORDER BY SUM(pay.Amount_Paid) DESC
LIMIT 20;

-- ============================================================
-- SECTION 5 : RISK & AGENT KPIs  (Q29 – Q35)
-- ============================================================

-- Q29. Policy distribution by risk category
SELECT
    Risk_category,
    COUNT(*)                                              AS Policy_Count,
    ROUND(AVG(Risk_Score), 2)                             AS Avg_Risk_Score,
    CONCAT(ROUND(COUNT(*) * 100.0 /
           SUM(COUNT(*)) OVER (), 2), ' %')               AS Pct_Share
FROM additional_data
GROUP BY Risk_category
ORDER BY Avg_Risk_Score DESC;

-- Q30. Average discount offered by risk category
SELECT
    Risk_category,
    CONCAT(ROUND(AVG(Policy_Discounts), 2), ' %') AS Avg_Discount_Pct
FROM additional_data
GROUP BY Risk_category
ORDER BY AVG(Policy_Discounts) DESC;

-- Q31. Renewal status breakdown
SELECT
    Renewal_Status,
    COUNT(*)                                              AS Count,
    CONCAT(ROUND(COUNT(*) * 100.0 /
           SUM(COUNT(*)) OVER (), 2), ' %')               AS Pct
FROM additional_data
GROUP BY Renewal_Status;

-- Q32. Agent-wise portfolio size (top 15 agents)
SELECT
    ad.Agent_ID,
    COUNT(ad.Policy_ID)                                       AS Policies_Managed,
    CONCAT(ROUND(SUM(p.Coverage_Amount) / 1000000, 2), ' M') AS Total_Coverage,
    CONCAT(ROUND(SUM(p.Premium_Amount)  / 1000000, 2), ' M') AS Total_Premium
FROM additional_data ad
JOIN policy_data     p ON ad.Policy_ID = p.Policy_ID
GROUP BY ad.Agent_ID
ORDER BY Policies_Managed DESC
LIMIT 15;

-- Q33. Agent-wise renewal rate
SELECT
    ad.Agent_ID,
    COUNT(ad.Policy_ID)                                            AS Total_Policies,
    SUM(CASE WHEN ad.Renewal_Status = 'Renewed' THEN 1 ELSE 0 END) AS Renewed_Count,
    CONCAT(ROUND(
        SUM(CASE WHEN ad.Renewal_Status = 'Renewed' THEN 1 ELSE 0 END) * 100.0
        / COUNT(ad.Policy_ID), 2), ' %')                           AS Renewal_Rate_Pct
FROM additional_data ad
GROUP BY ad.Agent_ID
ORDER BY SUM(CASE WHEN ad.Renewal_Status = 'Renewed' THEN 1 ELSE 0 END) * 100.0
         / COUNT(ad.Policy_ID) DESC
LIMIT 15;

-- Q34. High-risk policies with approved claims (risk exposure analysis)
SELECT
    ad.Risk_category,
    COUNT(cl.Claim_ID)                                        AS Approved_Claims,
    CONCAT(ROUND(SUM(cl.Claim_Amount) / 1000000, 2), ' M')   AS Total_Claim_Amount,
    ROUND(AVG(ad.Risk_Score), 2)                              AS Avg_Risk_Score
FROM additional_data ad
JOIN claims_data     cl ON ad.Policy_ID    = cl.Policy_ID
                        AND cl.Claim_Status = 'Approved'
GROUP BY ad.Risk_category
ORDER BY SUM(cl.Claim_Amount) DESC;

-- ============================================================
-- Q35. Stored Procedure – Year-wise KPI Summary
--      Returns: policies issued, total premium, revenue collected,
--               claims filed, claims approved for a given year.
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_yearly_kpi_summary $$

CREATE PROCEDURE sp_yearly_kpi_summary(IN p_year INT)
BEGIN
    SELECT
        p_year                                           AS KPI_Year,

        -- Policy KPIs
        COUNT(DISTINCT p.Policy_ID)                      AS Policies_Issued,
        CONCAT(ROUND(SUM(p.Premium_Amount) / 1000000, 2), ' M')
                                                         AS Total_Premium,

        -- Payment KPIs
        CONCAT(ROUND(
            (SELECT SUM(pay.Amount_Paid)
             FROM payment_data pay
             WHERE pay.Payment_Status = 'Successful'
               AND YEAR(STR_TO_DATE(pay.Date_of_Payment, '%d-%m-%Y')) = p_year
            ) / 1000000, 2), ' M')                       AS Revenue_Collected,

        -- Claims KPIs
        (SELECT COUNT(*)
         FROM claims_data cl
         WHERE YEAR(STR_TO_DATE(cl.Date_of_Claim, '%d-%m-%Y')) = p_year
        )                                                AS Total_Claims_Filed,

        (SELECT COUNT(*)
         FROM claims_data cl
         WHERE cl.Claim_Status = 'Approved'
           AND YEAR(STR_TO_DATE(cl.Date_of_Claim, '%d-%m-%Y')) = p_year
        )                                                AS Claims_Approved

    FROM policy_data p
    WHERE YEAR(STR_TO_DATE(p.Policy_Start_Date, '%d-%m-%Y')) = p_year;
END $$

DELIMITER ;

-- Usage:
CALL sp_yearly_kpi_summary(2022);
CALL sp_yearly_kpi_summary(2023);
CALL sp_yearly_kpi_summary(2024);