# Calcular turnover por departamento y clasificar riesgo

library(tidyverse)

#Cargar datos
df <- read_csv("data/WA_Fn-UseC_-HR-Employee-Attrition.csv")

#verificacion rapida

cat("Dimensiones:", dim(df), "\n")
cat("Valores Nulos: ", sum(is.na(df)),"\n" )

#Turnover rate en general

turnover_rate <- mean(df$Attrition == 'Yes')*100
cat(sprintf('Turnover Rate: %.1f%%\n', turnover_rate))




#Calcular turnover por departamento
turnover_dept <- df %>%
  group_by(Department) %>%
  summarise(
    total_empleados = n(),
    rotaciones = sum(Attrition == "Yes", na.rm = TRUE),
    tasa_turnover = (rotaciones / total_empleados) * 100
  ) %>%
  mutate(
    riesgo = case_when(
      tasa_turnover > 20 ~ "Alto",
      tasa_turnover > 10 ~ "Medio",
      TRUE ~ "Bajo"
    )
  ) %>%
  arrange(desc(tasa_turnover))

#Mostrar resultados
print(turnover_dept)

#Exportar a CSV

write_csv(turnover_dept,"outputs/tablas/turnover_dept_R.csv")

#grafico de barras

ggplot(turnover_dept, aes(x = reorder(Department, tasa_turnover), y = tasa_turnover, fill = riesgo))+
  geom_col() +
  geom_text(aes(label = paste0(round(tasa_turnover,1),"%")), hjust = -0.1) +
  coord_flip() +
  scale_fill_manual(values = c("Alto"="#C0392B","Medio" = "#F39c12","Bajo"= "#27ae60"))+
  labs(
    title = "Turnover Rate por Departamento",
    x = "",
    y = "Tasa de rotación (%)",
    fill = "Riesgo"
    ) +
  theme_minimal() +
  theme(legend.position = "bottom")

#guardar grafico
ggsave("outputs/graficos/turnover_dept_R.png", width = 8, height = 5, dpi = 300)

#Estadisticas globales
Turnover_Global <- df %>%
  summarise(
    total_empleados = n(),
    rotaciones = sum(Attrition == "Yes"),
    tasa_turnover = (rotaciones / total_empleados) * 100
  ) %>%
  mutate(riesgo = ifelse(tasa_turnover > 20, "Alto", ifelse(tasa_turnover > 10, "Medio", "Bajo")))

cat("\n📊 Turnover Global:\n")
print(Turnover_Global)

write_csv(Turnover_Global,"outputs/tablas/turnover_global_R.csv")
