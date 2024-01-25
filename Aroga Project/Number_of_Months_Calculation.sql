SELECT *
FROM Vitals
WHERE Blood_Pressure IS NOT NULL
ORDER BY Respondent_ID, Created_Time

ALTER TABLE Vitals
ADD Months_Since_First_Visit INT;

UPDATE Vitals
SET Months_Since_First_Visit = subquery.Months_Since_First_Visit
FROM (
    SELECT
        Respondent_ID,
        Created_Time,
        DATEDIFF(MONTH, MIN(Created_Time) OVER (PARTITION BY Respondent_ID), Created_Time) AS Months_Since_First_Visit
    FROM Vitals
    WHERE Blood_Pressure IS NOT NULL
) AS subquery
WHERE Vitals.Respondent_ID = subquery.Respondent_ID AND Vitals.Created_Time = subquery.Created_Time;