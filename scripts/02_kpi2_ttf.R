#scripts/02_kpi2_ttf.R
#Time-to-Fill simulado 

library(tidyverse)

# Crear carpetas de output por KPI
dir.create("outputs/tablas/02_kpi2_ttf", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/graficos/02_kpi2_ttf", recursive = TRUE, showWarnings = FALSE)

#cargar datos

df<- read.csv("data/WA_Fn-UseC_-HR-Employee-Attrition.csv")
cat("Dimensiones: ", dim(df), "\n")

#filtar los empleados que se Abandonaron (Attrition == Yes)

salidas <- df %>%
  filter(Attrition == 'Yes') %>%
  select(Department, JobRole, JobLevel, MonthlyIncome)

cat("\nTotal de bajas:", nrow(salidas), "\n" )

#simular dias para cubrir las vacantes

set.seed(42)

salidas <- salidas %>%
  mutate(
    #Dias base según el nivel de puesto (benchmarks)
    dias_base = case_when(
    JobLevel == 1 ~ 20, #Recien ingreso
    JobLevel == 2 ~ 30, #Junior
    JobLevel == 3 ~ 45, #senior/supervisor
    JobLevel == 4 ~ 65, #gerente
    TRUE ~ 85           #director nivel 5
  ),
  days_to_fill = dias_base + sample(-10:20,n(),replace =TRUE), #añade variacion aleatoria entre -10 y +20 dias
  days_to_fill = ifelse(days_to_fill < 1, 1, days_to_fill),
  costo_vacante = days_to_fill * (mean(salidas$MonthlyIncome)*12/365)
  )

timetofill_summary <- salidas %>%
  group_by(Department, JobLevel) %>%
  summarise(
    avg_ttf = mean(days_to_fill),
    median_ttf = median(days_to_fill),
    n = n()
    )


ttf_resumen <- salidas %>%
  group_by(Department,JobLevel) %>%
  summarise(
    n_vacantes = n(),
    avg_ttf = mean(days_to_fill) %>% round(2),
    median_ttf = median(days_to_fill) %>% round(2),
    min_ttf = min(days_to_fill),
    max_ttf = max(days_to_fill),
    avg_costo = mean(costo_vacante) %>% round(0),
    .groups = "drop"
  )%>%
  arrange(Department,JobLevel)
cat("\n📋 Resumen de Time-to-Fill por Departamento y Nivel:\n")
print(timetofill_summary)
cat("\n")
print(ttf_resumen)

#guardar resumen en CSV

write_csv(ttf_resumen,"outputs/tablas/02_kpi2_ttf/ttf_resumen_R.csv")
cat("\n Tabla guardada en ../outputs/tablas/02_kpi2_ttf/ttf_resumen_R.csv\n")

#Visualizacion 1: Boxplot por nivel, coloreando por depto

p1 <- ggplot(salidas, aes(x = factor(JobLevel), y = days_to_fill, fill = Department))+
  geom_boxplot(alpha = 0.7)+
  scale_fill_manual(values = c("Human Resources" = "#c0392b",
                               "Research & Development" = "#27AE60",
                               "Sales" = "#1F3C6E"))+
  labs(
    title = "Time-to-Fill por Nivel de Puesto",
    subtitle = "Distribución de días para cubrir vacantes",
    x = "Nivel de Puesto (1=entrada, 5=directivo)",
    y = "Días",
    fill = "Departamento"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")


ggsave("outputs/graficos/02_kpi2_ttf/kpi2_ttf_boxplot_R.png", p1, width = 10, height = 6, dpi = 150)
cat("✅ Boxplot guardado en outputs/graficos/kpi2_ttf_boxplot_R.png\n")

#Visualizacion 2 : Barras con promedio por departamento y nivel

p2 <- ttf_resumen %>%
  ggplot(aes(x = interaction(Department, JobLevel, sep = " - "), y = avg_ttf, fill = Department)) +
  geom_col() +
  geom_text(aes(label = avg_ttf), vjust = -0.5, size = 3) +
  scale_fill_manual(values = c("Human Resources" = "#C0392B", 
                               "Research & Development" = "#27AE60", 
                               "Sales" = "#1F3C6E")) +
  labs(
    title = "Promedio de Time-to-Fill por Departamento y Nivel",
    x = "",
    y = "Días promedio",
    fill = "Departamento"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

ggsave("outputs/graficos/02_kpi2_ttf/kpi2_ttf_barras_R.png", p2, width = 10, height = 6, dpi = 150)
cat("✅ Boxplot guardado en outputs/graficos/kpi2_ttf_bbarras_R.png\n")


#Ultimo mostrar estadisticas globales 

costo_total <- sum(salidas$costo_vacante)
cat(sprintf("\n Costo total estimado de todas las vacantes: $%.s\n",format(costo_total, big.mark = ",",scientific = FALSE)))
cat(sprintf(" Costo promedio por vacantes: $%.s\n",format(mean(salidas$costo_vacante), big.mark = ",", scientific = FALSE)))

