# Microsoft Fabric Lab — People Analytics en la Nube

## Descripción

Este laboratorio documenta la implementación del proyecto **People Analytics IBM HR Dataset** sobre **Microsoft Fabric**, simulando un entorno corporativo Enterprise con almacenamiento en la nube, ETL con Dataflow Gen2, modelo semántico publicado y actualizaciones programadas automáticas.

Es la extensión cloud del laboratorio local que usa Power BI Desktop + archivos CSV. Con Fabric, los datos viven en **OneLake**, el ETL corre en la nube y el reporte se consume desde el servicio de Power BI sin depender de una máquina local.

---

## Arquitectura implementada

```
┌─────────────────────────────────────────────────────────────────┐
│  Microsoft Fabric — Workspace: People-Analytics-Lab             │
│                                                                 │
│  [1] OneLake / Lakehouse (people_analytics_lh)                  │
│       └── Files/raw/                                            │
│           ├── WA_Fn-UseC_-HR-Employee-Attrition.csv  ← IBM HR   │
│           ├── turnover_dept_Py.csv                              │
│           ├── ttf_resumen_Py.csv                                │
│           └── survival_by_dept_R.csv                            │
│       └── Tables/dbo/                                           │
│           └── ibm_hr_raw  ← Tabla Delta (formato Parquet)       │
│                                                                 │
│  [2] Dataflow Gen2 (Dataflow_PeopleAnalytics_IBM)               │
│       └── Transformación: nueva columna AttritionBin            │
│       └── Destino: Lakehouse (capa Silver)                      │
│                                                                 │
│  [3] Modelo Semántico (People Analytics Dashboard)              │
│       ├── _Medidas (tabla de medidas DAX)                       │
│       ├── DimDepartment                                         │
│       ├── DimGender                                             │
│       ├── DimJobLevel                                           │
│       ├── DimJobRole                                            │
│       ├── FactEmpleados                                         │
│       ├── FactSurvival                                          │
│       ├── FactTTF                                               │
│       └── FactTurnover                                          │
│                                                                 │
│  [4] Reporte Power BI publicado en el servicio                  │
│       └── Conexión: SQL Server endpoint de Fabric               │
│       └── Autenticación: OAuth 2.0 / Azure AD                   │
│       └── Refresco programado: Diario 8:30 a.m. UTC-6           │ 
└─────────────────────────────────────────────────────────────────┘
```

---

## Componentes implementados

### 1. Workspace — `People-Analytics-Lab`

Área de trabajo creada en Microsoft Fabric con capacidad Trial (64 CU).
Contiene todos los artefactos del laboratorio: Lakehouse, Dataflow Gen2, modelo semántico y reporte.

**Equivalente corporativo:** Workspace de Power BI Premium / Fabric F64 en producción, donde TI gestiona los permisos de acceso por rol (Admin, Member, Contributor, Viewer).

 

![📸 Screenshot:](/docs/azure-fabric/screenshots/01_workspace_fabric.png)

---

### 2. Lakehouse — `people_analytics_lh`

Almacén de datos en **OneLake** (equivalente a Azure Data Lake Storage Gen2).

**Estructura de capas:**

| Capa | Ruta | Contenido |
|------|------|-----------|
| Raw (Bronze) | `Files/raw/` | CSVs originales sin modificar |
| Tables (Silver) | `Tables/dbo/` | Tabla Delta `ibm_hr_raw` cargada desde CSV |

**Tabla Delta `ibm_hr_raw`:**
- Formato: Apache Parquet con Delta Lake (transaccional, versionado)
- Origen: `WA_Fn-UseC_-HR-Employee-Attrition.csv` — 1,470 filas × 35 columnas
- Exposición: SQL endpoint automático para consultas T-SQL y conexión desde Power BI

**Equivalente corporativo:** En producción, esta capa Bronze recibiría datos desde SAP HCM, Workday o SuccessFactors via Azure Data Factory o pipelines de Fabric. El analista no tiene acceso al sistema fuente — solo consume las tablas Delta del Lakehouse.

![📸 Screenshot:](/docs/azure-fabric/screenshots/02_lakehouse_files.png) 

![📸 Screenshot:](/docs/azure-fabric/screenshots/03_lakehouse_tablesDelta.png)

---

### 3. Dataflow Gen2 — `Dataflow_PeopleAnalytics_IBM`

Pipeline de transformación ETL ejecutado en la nube, sin depender de Power BI Desktop.

**Transformación aplicada:**
- Fuente: tabla `ibm_hr_raw` del Lakehouse
- Transformación: columna calculada `AttritionBin` (1 si Attrition = "Yes", 0 si No)
- Destino: Lakehouse `people_analytics_lh` (capa Silver)
- Estado: ✅ Completado exitosamente

**Equivalente corporativo:** Azure Data Factory (ADF) para orquestación de pipelines de datos. Dataflow Gen2 es la versión nativa de Fabric para transformaciones ligeras sin necesidad de Spark ni notebooks. Para transformaciones complejas (síntesis con Python, Kaplan-Meier) se usaría un Notebook de Fabric con PySpark.

![📸 Screenshot:](/docs/azure-fabric/screenshots/04_dataflow_gen2.png)

---

### 4. Conexión Power BI Desktop → Fabric

**Tipo de conexión utilizada: SQL Server endpoint de Fabric (Import mode)**

```
Base de datos: people_analytics_lh
Autenticación: OAuth 2.0 (Azure Active Directory)
Cifrado: SSL/TLS obligatorio
Modo: Import
```

**Tipos de conexión disponibles en Fabric para Power BI:**

| Tipo | Descripción | Cuándo usarlo |
|------|-------------|---------------|
| **DirectLake** | Lee archivos Delta directamente en OneLake — máximo rendimiento | Modelo semántico nativo de Fabric (sin PBIX local) |
| **Import** | Carga los datos en memoria del modelo | Datasets < 1GB, máximo rendimiento en reportes |
| **DirectQuery** | Consulta en tiempo real al SQL endpoint | Datos que cambian frecuentemente, datasets grandes |
| **SQL endpoint** | Conexión T-SQL al Warehouse/Lakehouse de Fabric | Compatible con herramientas SQL externas |

> **Nota sobre DirectLake:** Este modo está disponible únicamente cuando el modelo semántico se crea directamente en Fabric (sin Power BI Desktop). Para reportes desarrollados en Desktop y publicados al servicio, se usa Import o DirectQuery via SQL endpoint 

![📸 Screenshot:](/docs/azure-fabric/screenshots/05_directlake_connection.png)
![📸 Screenshot:](/docs/azure-fabric/screenshots/07_uso_compartido_nube.png)

---

### 5. Modelo Semántico publicado

**Nombre:** `People Analytics Dashboard`
**Ubicación:** Workspace `People-Analytics-Lab`


**Tablas del modelo (Constellation Schema):**

```
_Medidas (tabla de medidas DAX)
│
├── DimDepartment ←── FactEmpleados
├── DimGender     ←── FactEmpleados
├── DimJobLevel   ←── FactEmpleados ←── FactTTF
├── DimJobRole    ←── FactEmpleados
│
├── FactEmpleados   (tabla central — IBM HR raw, 1,470 filas)
├── FactTTF         (Time-to-Fill simulado, granularidad Dept+Level)
├── FactSurvival    (curva Kaplan-Meier exportada desde R)
└── FactTurnover    (turnover agregado por departamento)
```

> El modelo implementa un **Constellation Schema** (variante del modelo estrella con múltiples tablas de hechos compartiendo Conformed Dimensions), siguiendo la metodología Kimball — *The Data Warehouse Toolkit, 3rd Ed., Cap. 3*.

![📸 Screenshot:](/docs/azure-fabric/screenshots/09_semantic_model.png)

---

### 6. Reporte publicado en el servicio

**Dashboard: People Analytics — IBM HR Dataset**

KPIs activos en el reporte publicado:



![📸 Screenshot:](/docs/azure-fabric/screenshots/06_published_report.png)

---

### 7. Refresco programado automático

**Configuración:**

| Parámetro | Valor |
|-----------|-------|
| Conexión | SQL Server — `people_analytics_lh` (Fabric) |
| Autenticación | OAuth 2.0 — Azure Active Directory |
| Frecuencia | Diaria |
| Hora | 8:30 a.m. (UTC-6 Ciudad de México) |
| Notificaciones | Al propietario del modelo en caso de error |
| Cifrado | Obligatorio (SSL/TLS) |


![📸 Screenshot:](/docs/azure-fabric/screenshots/08_scheduled_refresh.png)
---

## Stack tecnológico — capa Fabric/Azure

| Componente | Herramienta | Equivalente Azure Enterprise |
|------------|-------------|------------------------------|
| Almacenamiento | OneLake + Lakehouse | Azure Data Lake Storage Gen2 |
| Formato de datos | Delta Lake (Parquet) | Delta Lake en Azure Databricks / Synapse |
| ETL ligero | Dataflow Gen2 | Azure Data Factory (Data Flows) |
| ETL complejo | (Notebook PySpark — próximo paso) | Azure Databricks / Synapse Notebooks |
| SQL engine | Lakehouse SQL endpoint | Azure Synapse Analytics / Azure SQL DB |
| Modelo semántico | Power BI Semantic Model en Fabric | Power BI Premium / Fabric F-SKU |
| Autenticación | OAuth 2.0 / Azure AD | Azure Active Directory (Entra ID) |
| Refresco | Scheduled Refresh (sin Gateway) | Sin gateway — datos 100% en nube |
| Publicación | Fabric Workspace App | Power BI Embedded / App Workspace |

---

## Relación con el laboratorio local

Este laboratorio es la **extensión cloud** del proyecto principal. Los mismos KPIs y el mismo modelo semántico ahora tienen dos implementaciones:

```
Laboratorio local (Power BI Desktop)          Laboratorio Fabric (nube)
─────────────────────────────────────   →    ─────────────────────────────
Fuente: CSV en /data/                         Fuente: Lakehouse en OneLake
ETL: Power Query (local)                      ETL: Dataflow Gen2 (nube)
Modelo: .pbix en /dashboard/                  Modelo: Semantic Model en Fabric
Conexión: Import local                        Conexión: SQL endpoint OAuth 2.0
Refresco: manual                              Refresco: automático 8:30am
Acceso: solo local                            Acceso: URL pública del servicio
```

---

## Próximos pasos

- [ ] Agregar KPI 4 (Pay Equity) al reporte publicado — ya implementado en BigQuery/Looker Studio
- [ ] Agregar KPI 5 (Headcount Forecast) al modelo semántico
- [ ] Crear Notebook de Fabric con PySpark para reemplazar el Dataflow Gen2 (capa de transformación más robusta)
- [ ] Implementar Row-Level Security (RLS) por departamento en el modelo semántico
- [ ] Configurar Data Pipeline para orquestación del flujo Bronze → Silver → Gold
- [ ] Preparar para certificación **DP-600 Fabric Analytics Engineer Associate**

---

## Recursos utilizados

- [Microsoft Learn — Microsoft Fabric](https://learn.microsoft.com/en-us/fabric/)
- [Documentación Lakehouse en Fabric](https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-overview)
- [Dataflow Gen2 en Fabric](https://learn.microsoft.com/en-us/fabric/data-factory/dataflows-gen2-overview)
- [Conexión Power BI a Fabric Lakehouse](https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-power-bi-reporting)
- Dataset: [IBM HR Analytics — Kaggle](https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset)

---

*Autor: Ing. Luis Alberto Ceja de León*
*Fecha: Abril 2026*
*[LinkedIn](https://www.linkedin.com/in/lceja21) · [GitHub](https://github.com/LuisCeja1286/DataInsightsPortfolio)*