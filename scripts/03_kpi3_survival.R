# scripts/03_kpi3_survival.R
# Kaplan-Meier Survival Analysis por departamento

library(tidyverse)
library(survival)
library(survminer)

#Crear carpetas output

dir.create("outputs/graficos/03_kpi3_survival", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tablas/03_kpi3_survival", recursive = TRUE, showWarnings = FALSE)

#cargar datos
df <- read.csv("data/WA_Fn-UseC_-HR-Employee-Attrition.csv")
cat("Dimensiones: ",dim(df), "\n")
cat("Valores nulos: ", sum(is.na(df)), "\n")

#Preparar datos para survival
# - event:     1 si se fue, 0 si sigue
# - duration:  años en la empresa (col: YearsAtCompany)

df_surv <- df %>%
  mutate(
    event = if_else(Attrition == "Yes", 1, 0),
    duration = YearsAtCompany
  )

#objeto de supervivencia
surv_obj <- Surv(time = df_surv$duration, event =df_surv$event)

#Ajuste de Kaplan-Meir global 
km_global <- survfit(surv_obj ~ 1, data=df_surv)

#Ajuste por departamento
km_dept <- survfit(surv_obj ~ Department, data = df_surv)

#Extraer medianas de supervivencia por Departamento

medians <- km_dept %>%
  summary() %>%
  .$table %>%
  as.data.frame() %>%
  rownames_to_column("Department") %>%
  select(Department, median = median) %>%
  mutate(median_num = as.numeric(median), median_text = ifelse(is.na(median_num), " >10 años",paste0(median_num, " años"))) %>%
  select(Department, median = median_text)

cat("\n📊 Mediana de supervivencia por departamento:\n")
print(medians)

# Guardar medianas en CSV
write_csv(medians, "outputs/tablas/03_kpi3_survival/survival_medians_R.csv")
cat("✅ Tabla de medianas guardada en outputs/tablas/03_kpi3_survival/survival_medians._Rcsv\n")


df_surv$Department <- as.factor(df_surv$Department)
depts <- levels(df_surv$Department)

# Generar tabla plana para Power BI
survival_export <- map_dfr(depts, function(dept) {
  mask <- df_surv$Department == dept
  km <- survfit(Surv(duration, event) ~ 1, data = df_surv[mask, ])
  
  tibble(
    Time_Years = km$time,               # tiempo en años
    Survival = km$surv,                 # probabilidad de supervivencia
    CI_Lower = km$lower,                # límite inferior 95%
    CI_Upper = km$upper,                # límite superior 95%
    Department = dept
  )
}) 

# Guardar CSV
write_csv(survival_export, "outputs/tablas/03_kpi3_survival/survival_by_dept_R.csv")
cat("✅ Curva survival exportada para Power BI\n")
cat(sprintf("   Filas: %d | Departamentos: %s\n", 
            nrow(survival_export), paste(depts, collapse = ", ")))



p <-ggsurvplot(
  km_dept,
  data = df_surv,
  conf.int = TRUE,               # intervalos de confianza
  pval = TRUE,                   # p‑value del log‑rank test
  risk.table = TRUE,             # tabla de riesgo debajo del gráfico
  risk.table.col = "strata",
  legend.title = "Departamento",
  legend.labs = levels(factor(df_surv$Department)),
  xlab = "Años en la empresa",
  ylab = "Probabilidad de retención",
  title = "Curva de Supervivencia por Departamento (Kaplan‑Meier)",
  palette = c("#C0392B", "#27AE60", "#1F3C6E"),   # rojo, verde, azul
  ggtheme = theme_minimal()
)


# Guardar gráfico en PNG
png("outputs/graficos/03_kpi3_survival/kpi3_survival_curves_R.png",
  width = 10,
  height = 8,
  units = "in",
  res = 300
  
)
print(p)
dev.off()
cat("✅ Gráfico guardado en outputs/graficos/03_kpi3_survival/kpi3_survival_curves_R.png")