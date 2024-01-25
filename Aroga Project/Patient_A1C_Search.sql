
WITH Min_Read AS (
  SELECT
    Patient_ID,
    Lab_Results AS First_Lab_Result,
    Visit_Number
  FROM
      [A1C Lab Results]
  WHERE Visit_Number = 1
)
SELECT Max_Read.Patient_ID, Min_Read.First_Lab_Result, Max_Read.Last_Lab_Result, (Last_Lab_Result - First_Lab_Result) AS Difference, Med_Count
FROM (SELECT
  [A1C Lab Results].Patient_ID,
  [A1C Lab Results].Lab_Results AS Last_Lab_Result,
  Visit_Number
  FROM
  [A1C Lab Results]
JOIN
  (SELECT Patient_ID, MAX(Visit_Number) AS Max_Visit_Number
  FROM [A1C Lab Results]
  GROUP BY Patient_ID) Max_Visit_Number ON [A1C Lab Results].Patient_ID = Max_Visit_Number.Patient_ID
  WHERE
  Visit_Number = Max_Visit_Number.Max_Visit_Number) Max_Read
JOIN Min_Read ON Min_Read.Patient_ID = Max_Read.Patient_ID
JOIN
  (SELECT Patient_ID, COUNT(Medications_Name) AS Med_Count
  FROM [Medications Appointments Days Count]
  GROUP BY Patient_ID) M ON M.Patient_ID = Max_Read.Patient_ID
ORDER BY Difference ASC