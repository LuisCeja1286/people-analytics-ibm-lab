# People Analytics Lab con IBM HR Dataset

![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)

## 📌 Descripción

Este repositorio contiene un laboratorio completo de **People Analytics** utilizando el dataset público de IBM HR. El objetivo es demostrar habilidades en:

- Análisis exploratorio y estadístico con **R** (tidyverse, survival, etc.)
- Generación de KPIs estratégicos de RRHH
- Visualización y storytelling con **Power BI**
- Buenas prácticas de control de versiones con **Git/GitHub**

## 📊 Dashboard Interactivo (MVP Producto Minimo Viable)

He construido un dashboard en **Power BI** que integra los primeros 3 KPIs del laboratorio. El modelo de datos utiliza esquema estrella (`FactEmpleados`, `DimJobLevel`, `DimDepartment`) Tablas de hechos de KPI (`FactTTF`,`FactSurvival`)

![Dashboard Overview](docs/images/dashboard_MVP.png)

### 🧠 Detalle técnico del gráfico Kaplan‑Meier

- **Datos**: Exportados desde R como tabla plana (`survival_by_dept_R.csv`) con columnas `Time_Years`, `Survival`, `CI_lower`, `CI_upper`, `Department`.
- **Visual en Power BI**: Script R que usa `ggplot2` + `geom_step` + `geom_ribbon`
- **Interactividad**: Responde a segmentaciones de departamento Ej. (`Human Resources` y `Sales`), manteniendo la asignación cromática consistente.

![Kaplan-Meier](docs/images/Kaplan-Meier_R.png)

## 📊 KPIs Implementados

| KPI | Descripción | Técnica | Archivo R |
|-----|-------------|---------|-----------|
| 1 | Turnover Rate por departamento | Análisis descriptivo | `scripts/01_kpi1_turnover.R` |
| 2 | Time-to-Fill simulado | Simulación con Faker | `scripts/02_kpi2_ttf.R` |
| 3 | Survival Analysis (retención) | Kaplan-Meier | `scripts/03_kpi3_survival.R` |
| 4 | Pay Equity (brecha salarial) | Regresión lineal | `scripts/04_kpi4_pay_equity.R` |
| 5 | Headcount Forecast | Proyección 12 meses | `scripts/05_kpi5_forecast.R` |
| 6 | Diversidad e Inclusión | Análisis de pipeline | `scripts/06_kpi6_diversity.R` |
| 7 | Engagement Index y eNPS proxy | Índice compuesto | `scripts/07_kpi7_engagement.R` |
| 8 | Absenteeism y Bradford Factor | Simulación con predictores | `scripts/08_kpi8_absenteeism.R` |

## 🚀 Cómo usar este repositorio

### Requisitos
- R (>= 4.0) con los paquetes: tidyverse, survival, survminer, faker, etc.
- Power BI Desktop (para ver el dashboard)

### Ejecutar los análisis
1. Clona el repositorio:
   ```bash
   git clone https://github.com/tu_usuario/people-analytics-ibm-lab.git