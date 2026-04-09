# # 3. ¿Cuál es la distribución de la antigüedad (YearsAtCompany) de los empleados que se fueron (Attrition="Yes") vs. los que se quedaron?
# 
# Pseudocódigo:
#   
# Filtrar por Attrition (dos grupos).
# 
# Para cada grupo, calcular: media, mediana, percentiles (25, 75) de YearsAtCompany.
# 
# Comparar visualmente (histogramas superpuestos o boxplots).
# 
# Identificar si hay un punto crítico (ej. a los 2 años) donde las salidas se concentran.

library(tidyverse)
library(ggplot2)

#crear carpetas de Output

dir.create("outputs/graficos/11_Distribucion_antiguedad" , recursive = TRUE, showWarnings = FALSE )
dir.create("outputs/tablas/11_Distribucion_antiguedad" , recursive = TRUE, showWarnings = FALSE )

# cargar datos

df <- read.csv("data/WA_Fn-UseC_-HR-Employee-Attrition.csv")

#tabla de estadisticas

stads_table <- df %>%
  group_by(Attrition) %>%
  summarise(
    media = mean(YearsAtCompany, na.rm = TRUE),
    mediana = median(YearsAtCompany, na.rm = TRUE),
    pc25 = quantile(YearsAtCompany, 0.25, na.rm = TRUE),
    pc75 = quantile(YearsAtCompany, 0.75, na.rm = TRUE)
  ) %>%
  tidyr::pivot_wider(
    names_from = Attrition,
    values_from = c(media, mediana, pc25, pc75),
    names_sep = "_"
  )

print(stads_table)

#Guardar tabla

write.csv(stads_table, "outputs/tablas/11_Distribucion_antiguedad/stads_antiguedad.csv")

#Grafico boxplot comparativo

p <- ggplot(df, aes(x = Attrition, y = YearsAtCompany, fill = Attrition))+
  geom_boxplot()+
  labs(title = "Distribución de antigüedad por tipo de Abandono",
       x = "Abandono", y = "Años en la empresa")+
  theme_classic()+
  scale_fill_manual(values = c("Yes" = "#C0392B", "No" = "#1F3C6E"))

ggsave("outputs/graficos/11_Distribucion_antiguedad/boxplot_antiguedad.png", p , width = 8, height = 6, dpi = 150)

cat("Tabla y grafico guardados. \n")