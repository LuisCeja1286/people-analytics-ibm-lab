# People Analytics Lab — IBM HR Dataset

![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![BigQuery](https://img.shields.io/badge/BigQuery-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)
![Looker Studio](https://img.shields.io/badge/Looker%20Studio-4285F4?style=for-the-badge&logo=looker&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)

## 📌 Descripción

Laboratorio completo de **People Analytics** utilizando el dataset público IBM HR (1,470 empleados, 35 variables). El objetivo es demostrar un stack de análisis de datos de RRHH de nivel profesional, combinando dos ecosistemas:

- **Ecosistema Microsoft**: R + Python → Power BI (KPIs 1–3)
- **Ecosistema Google**: BigQuery SQL → Vistas → Looker Studio (KPI 4)

Habilidades demostradas:
- Análisis estadístico con **R** (tidyverse, survival, survminer, regresión)
- Transformación y análisis con **Python** (pandas, lifelines, scikit-learn, faker)
- Modelado dimensional (esquema estrella + Constellation Schema con Conformed Dimensions)
- SQL avanzado en **BigQuery** (CTEs, window functions, APPROX_QUANTILES, vistas semánticas)
- Visualización y storytelling en **Power BI** y **Looker Studio**
- Control de versiones con **Git/GitHub**

---

## 🛠️ Stack Tecnológico

### Ecosistema Microsoft (KPIs 1–3)
| Capa | Herramienta | Uso |
|------|-------------|-----|
| Análisis estadístico | R (tidyverse, survival, survminer) | Kaplan-Meier, regresión, visualización estadística |
| Transformación | Python (pandas, faker, scikit-learn) | ETL, simulación de datos, modelos predictivos |
| Modelado | Power BI (Power Query, DAX) | Modelo estrella, medidas, relaciones |
| Visualización | Power BI Desktop + Visual R | Dashboard ejecutivo con visual R interactivo |

### Ecosistema Google (KPI 4)
| Capa | Herramienta | Uso |
|------|-------------|-----|
| Almacenamiento | BigQuery | Dataset IBM HR como tabla nativa |
| Transformación | BigQuery SQL (CTEs, window functions) | Pay gap, compa-ratio |
| Capa semántica | Vistas en BigQuery | Fuente de datos para Looker Studio |
| Visualización | Looker Studio | Dashboard de compensación y equidad |

> **Nota sobre modelado**: La lógica de negocio compleja (ratios, promedios ponderados, regresiones) se resuelve en BigQuery antes de llegar a Looker Studio — a diferencia de Power BI donde DAX permite calcularla en la capa de visualización.

---

## 📊 Dashboard Interactivo — Power BI (KPIs 1–3)

Modelo de datos con esquema Constellation (variante del modelo estrella con múltiples tablas de hechos y Conformed Dimensions):

```
FactEmpleados ──→ DimDepartment ←── FactTTF
FactEmpleados ──→ DimJobLevel   ←── FactTTF
FactEmpleados ──→ DimGender
                  DimDepartment ←── FactSurvival
```

![Dashboard Overview](docs/images/dashboard_MVP.png)

### 🧠 Detalle técnico — Visual R (Kaplan-Meier en Power BI)
- **Datos**: Exportados desde R como tabla plana `survival_by_dept_R.csv` con columnas `Time_Years`, `Survival`, `CI_lower`, `CI_upper`, `Department` (filtrado a ≤15 años)
- **Visual**: Script R con `ggplot2` + `geom_step` + `geom_ribbon` dentro de Power BI Desktop
- **Interactividad**: Responde a segmentaciones de departamento manteniendo asignación cromática consistente
- **DAX clave**: TTF Promedio usa promedio ponderado (`SUMX(FactTTF, avg_ttf * n_vacantes) / SUM(n_vacantes)`) — no `AVERAGE` simple

![Kaplan-Meier](docs/images/Kaplan-Meier_R.png)

---

## 📊 Dashboard Pay Equity — Looker Studio + BigQuery (KPI 4)

Primer KPI del ecosistema Google. Las transformaciones se resuelven en BigQuery como vistas semánticas; Looker Studio solo visualiza.

**Hallazgos principales:**
- Gap no ajustado: las mujeres ganan un **4.8% más** que los hombres a nivel global
- Controlando por JobLevel: en niveles 1, 2, 4 y 5 los hombres tienen salarios superiores (0.4%–2%)
- Nivel 3 (Mid-Senior): las mujeres ganan un 2.6% más — anomalía que requiere revisión
- Compa-ratio: entre 0.96 y 1.04 en todos los grupos → estructura salarial interna consistente
- **Conclusión**: el problema no es la política salarial sino el acceso a promociones en niveles senior

![Pay Equity Dashboard](docs/images/KPI4_lookerstudio.png)

**SQL clave (BigQuery):**
```sql
-- Compa-ratio con punto medio de banda por nivel
WITH puntomedio AS (
  SELECT JobLevel,
    APPROX_QUANTILES(MonthlyIncome, 100)[OFFSET(50)] AS mediana_income
  FROM `proyecto.dataset.IBM_HR`
  GROUP BY JobLevel
)
SELECT df.JobLevel, df.Gender,
  ROUND(AVG(df.MonthlyIncome / p.mediana_income), 3) AS avg_compa_ratio
FROM `proyecto.dataset.IBM_HR` df
JOIN puntomedio p ON df.JobLevel = p.JobLevel
GROUP BY df.JobLevel, df.Gender
ORDER BY df.Gender, df.JobLevel
```

---

## 📋 KPIs Implementados

| # | KPI | Técnica | Stack | Archivo |
|---|-----|---------|-------|---------|
| 1 | Turnover Rate por departamento | Análisis descriptivo + semáforo de riesgo | R + Python → Power BI | `scripts/01_kpi1_turnover.R` |
| 2 | Time-to-Fill simulado | Simulación con benchmarks + costo por vacante | Python → Power BI (DAX ponderado) | `scripts/02_kpi2_ttf.R` |
| 3 | Survival Analysis (retención) | Kaplan-Meier + intervalos de confianza | R (survminer) → Power BI Visual R | `scripts/03_kpi3_survival.R` |
| 4 | Pay Equity — brecha salarial | CTEs + APPROX_QUANTILES + compa-ratio | BigQuery SQL → Looker Studio | `sql/04_kpi4_pay_equity_bigquery.sql` |
| 5 | Headcount Forecast | Proyección 12 meses con tasa de cobertura | Python → Power BI | `scripts/05_kpi5_forecast.R` |
| 6 | Diversidad e Inclusión | Pipeline D&I + attrition disparity ratio | R + Python | `scripts/06_kpi6_diversity.R` |
| 7 | Engagement Index / eNPS proxy | Índice ponderado + segmentación Promoters/Detractors | R + Python | `scripts/07_kpi7_engagement.R` |
| 8 | Absenteeism + Bradford Factor | Síntesis con predictores reales | R + Python | `scripts/08_kpi8_absenteeism.R` |

> **KPI 4 en adelante**: se construyen en paralelo en ambos ecosistemas para demostrar portabilidad del conocimiento entre herramientas.

---

## 🚀 Cómo usar este repositorio

### Requisitos
- **R** (>= 4.0): tidyverse, survival, survminer, ggplot2, dplyr, readr
- **Python** (>= 3.9): pandas, numpy, matplotlib, seaborn, lifelines, faker, scikit-learn
- **Power BI Desktop** (para visualizar el dashboard .pbix)
- **Cuenta Google Cloud** con BigQuery habilitado (free tier suficiente)
- **Looker Studio** (lookerstudio.google.com — gratuito)

### Estructura del repositorio
```
people-analytics-lab/
├── data/
│   └── WA_Fn-UseC_-HR-Employee-Attrition.csv
├── scripts/          # Scripts R por KPI
├── python/           # Scripts Python por KPI
├── sql/              # Queries BigQuery por KPI
├── outputs/
│   ├── tablas/       # CSVs exportados por KPI
│   └── graficos/     # Imágenes PNG por KPI
├── dashboard/        # Archivo .pbix Power BI
├── docs/
│   └── images/       # Capturas del dashboard
└── README.md
```

### Ejecutar los análisis
```bash
# 1. Clonar el repositorio
git clone https://github.com/LuisCeja1286/DataInsightsPortfolio.git

# 2. Ejecutar setup de Python
python scripts/00_setup.py

# 3. Ejecutar KPIs en orden (R)
Rscript scripts/01_kpi1_turnover.R
Rscript scripts/02_kpi2_ttf.R
Rscript scripts/03_kpi3_survival.R

# 4. Para KPI 4: ejecutar SQL en BigQuery Console
# Archivo: 04_kpi4_pay_equity_bigquery.sql
```

---


*Dataset: [IBM HR Analytics Employee Attrition & Performance](https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset) — Kaggle*
*Autor: Ing. Luis Alberto Ceja de León — [LinkedIn](https://www.linkedin.com/in/lceja21) | [GitHub](https://github.com/LuisCeja1286)*