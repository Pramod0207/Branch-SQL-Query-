use branch;
-- 1. Total Revenue
SELECT
concat(round(sum(Invoice_Amount)/1000000,2),' M') AS Total_Revenue
FROM Invoice;

-- 2. Total Target
SELECT
concat(round(SUM(Total_Target)/1000000,2),' M') AS Total_Target
FROM individual_budget;

-- 3. Total Achivement
SELECT
concat(round((
   (SELECT SUM(Achieved_Amount) FROM brokerage) +
    (SELECT SUM(Achieved_Amount) FROM fees)
)/1000000,2), ' M') AS Total_Achievement;


-- 4. Achivement %
SELECT
concat(ROUND(
(
    (
        (SELECT SUM(achieved_amount) FROM brokerage) +
        (SELECT SUM(Achieved_amount) FROM fees)
    )
    /
    (SELECT SUM(Total_target) FROM individual_budget)
) * 100,
2
), ' %') AS 'Achievement %';

-- 5. branchwise Target VS Achivement

SELECT
    ib.Branch_Name,
    concat(round(SUM(ib.total_target)/1000000,2),' M') AS Target,
    concat(round(COALESCE(b.Achievement, 0)/1000000 + COALESCE(f.Achievement, 0)/1000000,2),' M') AS Achievement
FROM individual_budget ib
LEFT JOIN (
    SELECT
        Branch_Name,
        SUM(Achieved_Amount) AS Achievement
    FROM Brokerage
    GROUP BY Branch_Name
) b
    ON ib.Branch_Name = b.Branch_Name
LEFT JOIN (
    SELECT
        Branch_Name,
        SUM(Achieved_Amount) AS Achievement
    FROM Fees
    GROUP BY Branch_Name
) f
    ON ib.Branch_Name = f.Branch_Name
GROUP BY
    ib.Branch_Name,
    b.Achievement,
    f.Achievement;
    
    -- 6. Top 10 Performer
    
    SELECT
    ib.Account_Exe_Id,
    ib.Employee_Name,
    concat(round(SUM(ib.total_target)/1000000,2),' M') AS Target,
    concat(round(COALESCE(b.Achievement, 0)/1000000 + COALESCE(f.Achievement, 0)/1000000,2),' M') AS Achievement
FROM individual_budget ib
LEFT JOIN (
    SELECT
        Exe_Name,
        SUM(Achieved_Amount) AS Achievement
    FROM Brokerage
    GROUP BY Exe_Name
) b
    ON ib.Employee_Name = b.Exe_Name
LEFT JOIN (
    SELECT
        Account_executive,
        SUM(Achieved_Amount) AS Achievement
    FROM Fees
    GROUP BY Account_executive
) f
    ON ib.Employee_Name = f.Account_executive
GROUP BY
	ib.account_Exe_Id,
    ib.Employee_Name,
    b.Achievement,
    f.Achievement
    order by
	 b.Achievement desc,
    f.Achievement desc
    limit 10;
    
    -- 7. bottom 10 Performer
    
        SELECT
    ib.Account_Exe_Id,
    ib.Employee_Name,
    concat(round(SUM(ib.total_target)/1000000,2),' M') AS Target,
    concat(round(COALESCE(b.Achievement, 0)/1000000 + COALESCE(f.Achievement, 0)/1000000,2), ' M') AS Achievement
FROM individual_budget ib
LEFT JOIN (
    SELECT
        Exe_Name,
        SUM(Achieved_Amount) AS Achievement
    FROM Brokerage
    GROUP BY Exe_Name
) b
    ON ib.Employee_Name = b.Exe_Name
LEFT JOIN (
    SELECT
        Account_executive,
        SUM(Achieved_Amount) AS Achievement
    FROM Fees
    GROUP BY Account_executive
) f
    ON ib.Employee_Name = f.Account_executive
GROUP BY
	ib.account_Exe_Id,
    ib.Employee_Name,
    b.Achievement,
    f.Achievement
order by
	 b.Achievement asc,
    f.Achievement asc
    limit 10;
    
  -- 8.  Meeting Count 
  
	SELECT COUNT(*) AS Meeting_Count
FROM Meeting;

 -- 9.  Opportunity Count
 
 select count(*) as Opportunity_Count
 from opportunity;
 
 -- 10.  Opportunity count by stages
 select
 stage,
 count(*) as Opportunity_Count
 from Opportunity
 group by stage;
 
 -- 11.  Win Ratio
 select
 concat(round(
 count(case when stage = 'won'then 1 end)*100/
 nullif	(count(case when stage in ('won', 'Lost') then 1 end),0),2),' %'
 ) as Win_Ratio
 from opportunity;
 
  -- 12  Variance Analysis
  
  SELECT
    'New sell' AS Sell_Type,
    concat(ROUND(SUM(New_Budget)/1000000,2),' M') AS Target,
    concat(ROUND(
        (
            COALESCE((SELECT SUM(Achieved_Amount)
                      FROM Brokerage
                      WHERE income_class = 'New'),0)
          + COALESCE((SELECT SUM(Achieved_Amount)
                      FROM Fees
                      WHERE Income_class = 'New'),0)
        ) / 1000000, 2
    ), ' M') AS Achievement,
    concat(ROUND(
        COALESCE((SELECT SUM(Invoice_Amount)
                  FROM Invoice
                  WHERE income_class = 'New'),0)
        / 1000000, 2
    ),' M') AS Revenue
FROM individual_budget

UNION ALL

SELECT
    'Cross sell',
    concat(ROUND(SUM(Cross_sell_Budget)/1000000,2),' M'),
    concat(ROUND(
        (
            COALESCE((SELECT SUM(Achieved_Amount)
                      FROM Brokerage
                      WHERE Income_class = 'Cross sell'),0)
          + COALESCE((SELECT SUM(Achieved_Amount)
                      FROM Fees
                      WHERE Income_class = 'Cross sell'),0)
        ) / 1000000, 2
    ),' M'),
    concat(ROUND(
        COALESCE((SELECT SUM(Invoice_Amount)
                  FROM Invoice
                  WHERE income_class = 'Cross sell'),0)
        / 1000000, 2
    ),' M')
FROM individual_budget

UNION ALL

SELECT
    'Renewal sell',
    concat(ROUND(SUM(Renewal_budget)/1000000,2),' M'),
    concat(ROUND(
        (
            COALESCE((SELECT SUM(Achieved_Amount)
                      FROM Brokerage
                      WHERE income_class = 'Renewal'),0)
          + COALESCE((SELECT SUM(Achieved_Amount)
                      FROM Fees
                      WHERE Income_class = 'Renewal'),0)
        ) / 1000000, 2
    ),' M'),
    concat(ROUND(
        COALESCE((SELECT SUM(Invoice_Amount)
                  FROM Invoice
                  WHERE income_class = 'Renewal'),0)
        / 1000000, 2
    ),' M')
FROM individual_budget;


 -- 13  Branch wise Variance Analysis
 
 SELECT
    ib.Branch_Name,
    'New Sell' AS Sell_Type,
    CONCAT(ROUND(SUM(ib.New_Budget)/1000000,2),' M') AS Target,
    CONCAT(ROUND(
        (
            COALESCE(b_new.Achievement,0) +
            COALESCE(f_new.Achievement,0)
        ) / 1000000, 2
    ),' M') AS Achievement,
    CONCAT(ROUND(
        COALESCE(i_new.Revenue,0) / 1000000, 2
    ),' M') AS Revenue
FROM individual_budget ib
LEFT JOIN (
    SELECT Branch_Name, SUM(Achieved_Amount) AS Achievement
    FROM Brokerage
    WHERE Income_Class = 'New'
    GROUP BY Branch_Name
) b_new ON ib.Branch_Name = b_new.Branch_Name
LEFT JOIN (
    SELECT Branch_Name, SUM(Achieved_Amount) AS Achievement
    FROM Fees
    WHERE Income_Class = 'New'
    GROUP BY Branch_Name
) f_new ON ib.Branch_Name = f_new.Branch_Name
LEFT JOIN (
    SELECT Branch_Name, SUM(Invoice_Amount) AS Revenue
    FROM Invoice
    WHERE Income_Class = 'New'
    GROUP BY Branch_Name
) i_new ON ib.Branch_Name = i_new.Branch_Name
GROUP BY
    ib.Branch_Name,
    b_new.Achievement,
    f_new.Achievement,
    i_new.Revenue
    
    Union all
    
    SELECT
    ib.Branch_Name,
    'Cross Sell',
    CONCAT(ROUND(SUM(ib.cross_sell_Budget)/1000000,2),' M') AS Target,
    CONCAT(ROUND(
        (
            COALESCE(b_Cross_sell.Achievement,0) +
            COALESCE(f_Cross_sell.Achievement,0)
        ) / 1000000, 2
    ),' M') AS Achievement,
    CONCAT(ROUND(
        COALESCE(i_Cross_sell.Revenue,0) / 1000000, 2
    ),' M') AS Revenue
FROM individual_budget ib
LEFT JOIN (
    SELECT Branch_Name, SUM(Achieved_Amount) AS Achievement
    FROM Brokerage
    WHERE Income_Class = 'Cross Sell'
    GROUP BY Branch_Name
) b_Cross_sell ON ib.Branch_Name = b_Cross_sell.Branch_Name
LEFT JOIN (
    SELECT Branch_Name, SUM(Achieved_Amount) AS Achievement
    FROM Fees
    WHERE Income_Class = 'Cross Sell'
    GROUP BY Branch_Name
) f_Cross_sell ON ib.Branch_Name = f_Cross_sell.Branch_Name
LEFT JOIN (
    SELECT Branch_Name, SUM(Invoice_Amount) AS Revenue
    FROM Invoice
    WHERE Income_Class = 'Cross Sell'
    GROUP BY Branch_Name
) i_Cross_sell ON ib.Branch_Name = i_Cross_sell.Branch_Name
GROUP BY
    ib.Branch_Name,
    b_Cross_sell.Achievement,
    f_Cross_sell.Achievement,
    i_Cross_sell.Revenue
    
    Union all
    
    SELECT
    ib.Branch_Name,
    'Renewal Sell',
    CONCAT(ROUND(SUM(ib.Renewal_Budget)/1000000,2),' M') AS Target,
    CONCAT(ROUND(
        (
            COALESCE(b_Renewal.Achievement,0) +
            COALESCE(f_Renewal.Achievement,0)
        ) / 1000000, 2
    ),' M') AS Achievement,
    CONCAT(ROUND(
        COALESCE(i_Renewal.Revenue,0) / 1000000, 2
    ),' M') AS Revenue
FROM individual_budget ib
LEFT JOIN (
    SELECT Branch_Name, SUM(Achieved_Amount) AS Achievement
    FROM Brokerage
    WHERE Income_Class = 'Renewal'
    GROUP BY Branch_Name
) b_Renewal ON ib.Branch_Name = b_Renewal.Branch_Name
LEFT JOIN (
    SELECT Branch_Name, SUM(Achieved_Amount) AS Achievement
    FROM Fees
    WHERE Income_Class = 'Renewal'
    GROUP BY Branch_Name
) f_Renewal ON ib.Branch_Name = f_Renewal.Branch_Name
LEFT JOIN (
    SELECT Branch_Name, SUM(Invoice_Amount) AS Revenue
    FROM Invoice
    WHERE Income_Class = 'Renewal'
    GROUP BY Branch_Name
) i_Renewal ON ib.Branch_Name = i_Renewal.Branch_Name
GROUP BY
    ib.Branch_Name,
    b_Renewal.Achievement,
    f_Renewal.Achievement,
    i_Renewal.Revenue
    ORDER BY
    Branch_Name,
    CASE Sell_Type
        WHEN 'New Sell' THEN 1
        WHEN 'Cross Sell' THEN 2
        WHEN 'Renewal Sell' THEN 3
    END;
    
     -- 14  Branch Performance rank by Revenue
    
    SELECT
    Branch_Name,
    RANK() OVER (ORDER BY SUM(Invoice_Amount) DESC) AS Branch_Rank
FROM Invoice
GROUP BY Branch_Name
ORDER BY Branch_Rank;

-- 15  Branch Matrix table

SELECT
    db.branch_name,
    concat(round(SUM(ib.total_target)/1000000,2),' M') AS Target,
		concat(round(COALESCE(b.Achievement,0)/1000000 + COALESCE(f.Achievement,0)/1000000,2),' M') AS Achievement,
    concat(ROUND(
        (COALESCE(b.Achievement,0) + COALESCE(f.Achievement,0))
        * 100 /
        NULLIF(SUM(ib.total_target),0),
        2
    ),' %') AS 'Achievement %',

    COALESCE(m.Meeting_Count,0) AS Meeting_Count,

    CONCAT(
        ROUND(
            COALESCE(w.Won_Count,0) * 100.0 /
            NULLIF(
                COALESCE(w.Won_Count,0) +
                COALESCE(w.Lost_Count,0),
                0
            ),
            2
        ),
        ' %'
    ) AS 'Win %'

FROM dim_branch db

LEFT JOIN individual_budget ib
    ON db.branch_id = ib.branch_id

LEFT JOIN (
    SELECT
        branch_id,
        SUM(Achieved_Amount) AS Achievement
    FROM Brokerage
    GROUP BY branch_id
) b ON db.branch_id = b.branch_id

LEFT JOIN (
    SELECT
        branch_id,
        SUM(Achieved_Amount) AS Achievement
    FROM Fees
    GROUP BY branch_id
) f ON db.branch_id = f.branch_id

LEFT JOIN (
    SELECT
        branch_id,
        COUNT(*) AS Meeting_Count
    FROM Meeting
    GROUP BY branch_id
) m ON db.branch_id = m.branch_id

LEFT JOIN (
    SELECT
        branch_id,
        COUNT(CASE WHEN Stage = 'Won' THEN 1 END) AS Won_Count,
        COUNT(CASE WHEN Stage = 'Lost' THEN 1 END) AS Lost_Count
    FROM Opportunity
    GROUP BY branch_id
) w ON db.branch_id = w.branch_id

GROUP BY
    db.branch_name,
    b.Achievement,
    f.Achievement,
    m.Meeting_Count,
    w.Won_Count,
    w.Lost_Count

ORDER BY db.branch_name;

-- 16  State-Wise Achievement

SELECT
    db.state,
    concat(ROUND(
        (
            COALESCE(SUM(b.Achievement),0) +
            COALESCE(SUM(f.Achievement),0)
        ) / 1000000,
        2),' M'
    ) AS Achievement
FROM dim_branch db
LEFT JOIN (
    SELECT
        branch_id,
        SUM(Achieved_Amount) AS Achievement
    FROM Brokerage
    GROUP BY branch_id
) b ON db.branch_id = b.branch_id

LEFT JOIN (
    SELECT
        branch_id,
        SUM(Achieved_Amount) AS Achievement
    FROM Fees
    GROUP BY branch_id
) f ON db.branch_id = f.branch_id

GROUP BY db.state
ORDER BY Achievement DESC;