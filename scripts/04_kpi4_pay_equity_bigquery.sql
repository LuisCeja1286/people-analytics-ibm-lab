#Pay-gap no ajustado

WITH stads AS (
  SELECT
    Gender
    ,AVG(MonthlyIncome) AS Promedio
    ,COUNT(*) as n_empleados
    FROM `project-6d0ee2ab-21fb-44c5-a4e.ID_Empleado.IBM HR dataset`
    GROUP BY Gender
)

Select  
       ROUND(MAX(CASE WHEN Gender = 'Male' Then Promedio END),2) AS Promedio_H
       ,ROUND(MAX(CASE WHEN Gender = 'Female' Then Promedio END),2) AS Promedio_M
       ,ROUND((MAX(CASE WHEN Gender = 'Male' Then Promedio END) -
              MAX(CASE WHEN Gender = 'Female' Then Promedio END))/
              MAX(CASE WHEN Gender = 'Male' Then Promedio END)*100,2
       ) AS gap_percent
FROM stads;

#Pay-gab por nivel jerárgico (JobLevel)

WITH by_level AS (
  SELECT
     JobLevel
    ,Gender
    ,AVG(MonthlyIncome) as avg_salary
  FROM `project-6d0ee2ab-21fb-44c5-a4e.ID_Empleado.IBM HR dataset`
  GROUP BY JobLevel, Gender
)

Select 
       JobLevel
      ,ROUND(MAX(CASE WHEN Gender = 'Male' Then avg_salary END),2) AS Promedio_H
      ,ROUND(MAX(CASE WHEN Gender = 'Female' Then avg_salary END),2) AS Promedio_M
      ,ROUND((MAX(CASE WHEN Gender = 'Male' Then avg_salary END) -
              MAX(CASE WHEN Gender = 'Female' Then avg_salary END))/
              MAX(CASE WHEN Gender = 'Male' Then avg_salary END)*100,2
       ) AS porcentaje
FROM by_level 
GROUP BY JobLevel
ORDER BY JobLevel;

#Compa-ratio por punto medio del nivel JobLevel

WITH puntomedio AS (
  SELECT 
    JobLevel
    ,APPROX_QUANTILES(MonthlyIncome, 100)[OFFSET(50)] AS mediana_income
  FROM `project-6d0ee2ab-21fb-44c5-a4e.ID_Empleado.IBM HR dataset`
  GROUP BY JobLevel
)
SELECT 
  df.JobLevel
  ,df.Gender
  ,ROUND(AVG(df.MonthlyIncome / p.mediana_income), 3) AS avg_compa_ratio
  --,COUNT(*) AS n_employees
FROM `project-6d0ee2ab-21fb-44c5-a4e.ID_Empleado.IBM HR dataset` df
JOIN puntomedio p ON df.JobLevel = p.JobLevel
GROUP BY df.JobLevel, df.Gender
ORDER BY df.Gender,df.JobLevel;
 
