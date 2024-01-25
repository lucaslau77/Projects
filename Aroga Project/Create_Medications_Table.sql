SELECT *
FROM [Medications Appointments Days Count]
ORDER BY End_Days_After_First_Appointment ASC

-- DROP TABLE [Medications Appointments Days Count]

-- Create the table
SELECT
    MCF.Patient_ID,
    A.First_Appointment_Date,
    MCF.Medications_Name,
    MCF.Medications_Start_Date,
    MCF.Medications_End_Date,
    DATEDIFF(DAY, Medications_Start_Date, Medications_End_Date) AS Medications_Duration_Days,
    CASE
        WHEN Medications_Start_Date < First_Appointment_Date THEN 'Before Aroga'
        ELSE 'After Aroga'
    END AS Before_First_Appointment,
    CASE
        WHEN Medications_Start_Date > First_Appointment_Date THEN
            DATEDIFF(DAY, First_Appointment_Date, Medications_Start_Date)
        ELSE NULL
    END AS Start_Days_After_First_Appointment,
    CASE
        WHEN Medications_End_Date > First_Appointment_Date THEN
            DATEDIFF(DAY, First_Appointment_Date, Medications_End_Date)
        ELSE NULL
    END AS End_Days_After_First_Appointment,
    CASE
        WHEN ABS(DATEDIFF(MONTH, A.First_Appointment_Date, MCF.Medications_Start_Date)) < 12 OR ABS(DATEDIFF(MONTH, MCF.Medications_Start_Date, A.First_Appointment_Date)) < 12 THEN
            'Yes'
        ELSE 'No'
    END AS Within_One_Year
INTO [Medications Appointments Days Count]
FROM [Medications Count Filtered] MCF
JOIN (SELECT Patient_ID, MIN(Created_Date) AS First_Appointment_Date
    FROM [A1C Lab Results]
    GROUP BY Patient_ID
    ) A ON A.Patient_ID = MCF.Patient_ID


-- Add normal distribution columns
ALTER TABLE [Medications Appointments Days Count]
ADD End_Days_Normal_Distribution FLOAT;

WITH RankedData AS (
    SELECT
        End_Days_After_First_Appointment,
        Normal_Distribution = PERCENT_RANK() OVER (ORDER BY End_Days_After_First_Appointment)
    FROM
        [Medications Appointments Days Count]
)
UPDATE [Medications Appointments Days Count]
SET End_Days_Normal_Distribution = RankedData.Normal_Distribution
FROM RankedData
WHERE [Medications Appointments Days Count].End_Days_After_First_Appointment = RankedData.End_Days_After_First_Appointment;

ALTER TABLE [Medications Appointments Days Count]
ADD Med_Duration_Normal_Distribution FLOAT;

WITH RankedData AS (
    SELECT
        End_Days_After_First_Appointment,
        Normal_Distribution = PERCENT_RANK() OVER (ORDER BY End_Days_After_First_Appointment)
    FROM
        [Medications Appointments Days Count]
)
UPDATE [Medications Appointments Days Count]
SET Med_Duration_Normal_Distribution = RankedData.Normal_Distribution
FROM RankedData
WHERE [Medications Appointments Days Count].End_Days_After_First_Appointment = RankedData.End_Days_After_First_Appointment;


-- Add Z score columns
ALTER TABLE [Medications Appointments Days Count]
ADD End_Days_Z_Score FLOAT;

UPDATE [Medications Appointments Days Count]
SET End_Days_Z_Score = T1.Z_Score
FROM (
    SELECT
        End_Days_After_First_Appointment,
        ABS((End_Days_After_First_Appointment - AVG(End_Days_After_First_Appointment) OVER ()) / STDEV(End_Days_After_First_Appointment) OVER ()) AS Z_Score
    FROM [Medications Appointments Days Count]
) AS T1
WHERE [Medications Appointments Days Count].End_Days_After_First_Appointment = T1.End_Days_After_First_Appointment;

ALTER TABLE [Medications Appointments Days Count]
ADD Med_Duration_Z_Score FLOAT;

UPDATE [Medications Appointments Days Count]
SET Med_Duration_Z_Score = T1.Z_Score
FROM (
    SELECT
        End_Days_After_First_Appointment,
        ABS((End_Days_After_First_Appointment - AVG(End_Days_After_First_Appointment) OVER ()) / STDEV(End_Days_After_First_Appointment) OVER ()) AS Z_Score
    FROM [Medications Appointments Days Count]
) AS T1
WHERE [Medications Appointments Days Count].End_Days_After_First_Appointment = T1.End_Days_After_First_Appointment;