#scripts/05_kpi5_forecast.R
# Headcount Forecast a 12 meses por departamento.

library(tidyverse)
library(ggplot2)

#Crear las carpetas de output

dir.create("outputs/tablas/05_kpi5_forecast", recursive = TRUE,showWarnings = FALSE)
dir.create("outputs/graficos//05_kpi5_forecast", recursive = TRUE,showWarnings = FALSE)

#cargar datos

df <- read.csv("data/WA_Fn-UseC_-HR-Employee-Attrition.csv")
cat("Dimensiones:", dim(df),"\n")

#Calcular turnover anual por departamento

turnover_dep <- df %>%
  group_by(Department) %>%
  summarise(
    hc_actual = n(),
    rotaciones = sum(Attrition == 'Yes'),
    turnover_anual = rotaciones / hc_actual,
    .groups = 'drop'
)%>%
mutate(tasa_mensual = turnover_anual / 12)
  
cat("\n Turnover por departamento:\n")
print(turnover_dep)

#Parámetros de Simulación

fill_rate <- 0.80 #No tenemos datos de Tasa de cobertura por lo que asumimos un 80% de de capacidad de reclutamiento
meses <- 12

forecast_list <- list()

for (i in 1:nrow(turnover_dep)) {
  depto <- turnover_dep$Department[i]
  hc <- turnover_dep$hc_actual[i]
  tasa_mensual <- turnover_dep$tasa_mensual[i]

#Vector par almacenar headcount mes a mes (mes = 0 Actual)

hc_series <- numeric(meses + 1)
hc_series[1] <- hc

for (m in 1:meses){
  bajas <- round(hc_series[m]* tasa_mensual)
  contrataciones <- round(bajas * fill_rate)
  hc_series[m + 1] <- hc_series[m]-bajas+contrataciones
}

#crear data frame por departamento

df_dept <- tibble(
  Department = depto,
  mes = 0:meses,
  headcount = hc_series
)
  forecast_list[[i]] <- df_dept
}

df_forecast <- bind_rows(forecast_list)

#Exportar tabla de datos

write_csv(df_forecast,"outputs/tablas/05_kpi5_forecast/forecast_headcount_R.csv")
cat("Tabla de proyección guardada en outputs/tablas/05_kpi5_forecast/forecast_headcount_R.csv\n")

# Grafico de lineas

p <- ggplot(df_forecast, aes(x = mes, y = headcount, color = Department, group = Department))+
  geom_line(size = 1.2)+
  geom_point(size = 2)+
  scale_color_manual(values = c("Human Resources" = "#C0392B",
                                "Research & Development" = "#27AE60",
                                "Sales" = "#1F3C6E"))+
  labs(
    title = "Proyección de headcount a  12 meses por Departamento",
    subtitle = paste("Tasa de cobertura (fill rate) =", fill_rate*100,"%"),
    x = "Mes",
    y = "Número de empleados",
    color = "Departamento"
  )+
  theme_minimal()+
  
  theme(legend.position = "botton", legend.box   = "horizontal")

ggsave("outputs/graficos/05_kpi5_forecast/forecast_lines_R.png",p, width = 10, height = 6, dpi = 150)
cat("Gráfico guardado en outputs/graficos/05_kpi5_forecast/forecast_lines_R.png\n")

#Resumen (headcount estimado a 12 meses)

resumen_final <- df_forecast %>%
  filter(mes == meses) %>%
  select(Department, headcount_12m = headcount) %>%
  left_join(turnover_dep %>% select(Department, hc_actual), by = "Department")%>%
  mutate(cambio = headcount_12m - hc_actual)
cat(
  "\n Resumen final a 12 meses"
)
print(resumen_final)

write.csv(resumen_final, "outputs/tablas/05_kpi5_forecast/forecast_summary_R.csv")
cat("Resumen Guardado \n")
