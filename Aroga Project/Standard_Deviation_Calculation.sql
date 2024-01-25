SELECT *
FROM [A1C Lab Results]
ORDER BY Standard_Deviation DESC

ALTER TABLE [A1C Lab Results]
ADD Standard_Deviation FLOAT;

WITH Stats AS (
    SELECT
        AVG(Lab_Result) AS mean_value,
        STDEV(Lab_Result) AS std_dev_value
    FROM [A1C Lab Results]
)

UPDATE [A1C Lab Results]
SET Standard_Deviation = subquery.Standard_Deviation
FROM (
    SELECT
        Patient_ID,
        Created_Date,
        ABS(Lab_Result - mean_value) / std_dev_value AS Standard_Deviation
    FROM [A1C Lab Results]
    JOIN Stats ON 1=1
) AS subquery
WHERE [A1C Lab Results].Patient_ID = subquery.Patient_ID AND [A1C Lab Results].Created_Date = subquery.Created_Date;