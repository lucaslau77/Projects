SELECT *
FROM Vitals
WHERE Blood_Pressure IS NOT NULL
ORDER BY Blood_Pressure DESC

UPDATE Vitals
SET Blood_Pressure = SUBSTRING(Blood_Pressure, 2,LEN(Blood_Pressure)-1)
FROM Vitals
WHERE Blood_Pressure LIKE '%,%'