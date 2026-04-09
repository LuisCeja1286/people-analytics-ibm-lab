#scripts/04_kpi4_pay_equity.R
#Análisis de equidad salarial pay gay y compa - ratio

library(tidyverse)

#Crear carpetas de Output
dir.create("outputs/graficos/04_kpi4_pay_equity", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tablas/04_kpi4_pay_equity", recursive = TRUE, showWarnings = FALSE)

#Cargar datos

df <- read.csv("data/WA_Fn-UseC_-HR-Employee-Attrition.csv")

# pay gap por genero no ajustado

pay_gender <- df %>%
  group_by(Gender)%>%
  summarise(
    mean_income = mean(MonthlyIncome),
    median_income = median(MonthlyIncome),
    conteo = n()
  )

no_aju <- (pay_gender$mean_income[pay_gender$Gender == "Male"] -
           pay_gender$mean_income[pay_gender$Gender == "Female"]) /
           pay_gender$mean_income[pay_gender$Gender == "Male"]*100

cat(sprintf("Pay Gap no ajustado (Hombre - Mujer) %.2f%%\n", no_aju))

#pay gap ajustado: Usando regresion controlando JobLevel, TotalWorkingYear, PerformancceRating
modelo <- lm(MonthlyIncome ~ JobLevel + TotalWorkingYears + PerformanceRating + Gender, data = df)

summary(modelo) # coeficiente de GenderMale es el adjusted gap

#Extraer coeficiente
adj_gap <- coef(modelo)["GenderMale"]
cat(sprintf("Gap Ajustado (controlado por nivel, exp, desempeño): $%.2f\n", adj_gap))

resultados_gap <- data.frame(
  tipo = c("No ajustado (%)", "Ajustado ($)"),
  valor = c(round(no_aju,2), round(adj_gap,2))
)

write.csv(resultados_gap,"outputs/tablas/04_kpi4_pay_equity/pay_gap_summary_R.csv")




#compa-- ratio (salario / punto medio de la banda de JobLevel)

puntos_med <- df %>%
  group_by(JobLevel) %>%
  summarise( punto_med = median(MonthlyIncome))

print(puntos_med)

df <- df %>%
  left_join(puntos_med, by = "JobLevel")%>%
  mutate(compa_ratio = MonthlyIncome / punto_med)

compa_genero <- df %>%
  group_by(Gender, JobLevel)%>%
  summarise(avg = mean(compa_ratio),.groups = "drop") %>%
  arrange(JobLevel,Gender)


print(compa_genero)

#guardar tabla de compa-ratio por nivel

write.csv(compa_genero,"outputs/tablas/04_kpi4_pay_equity/compa_ratio_by_gender_level_R.csv")

#Visualización 1: Violin plot por nivel y género
violin_plot <-ggplot(df, aes(x = factor(JobLevel), y = MonthlyIncome, fill = Gender)) +
  geom_violin(alpha = 0.6, position = position_dodge(0.8)) +
  geom_boxplot(width = 0.1, position = position_dodge(0.8), alpha = 0.8) +
  scale_fill_manual(values = c("Female" = "#C0392B", "Male" = "#1F3C6E")) +
  labs(
    title = "Distribución salarial por nivel jerárquico y género",
    x = "Nivel de puesto (1=entry, 5=director)",
    y = "Ingreso mensual (USD)"
  ) +
  theme_minimal()

ggsave("outputs/graficos/04_kpi4_pay_equity/violin_plot_pay_equity.png", width = 10, height = 6, dpi = 150)