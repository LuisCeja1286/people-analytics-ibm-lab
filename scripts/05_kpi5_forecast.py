#scripts/05_kpi5_forecast.py
#eadcount forecasts a 12 meses por departamento

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os

#comfigurar carpetas si se ejecuta primero este Script
os.makedirs("../outputs/tablas/05_kpi5_forecast", exist_ok= True)
os.makedirs("../outputs/graficos/05_kpi5_forecast", exist_ok= True)

#cargar datos

df = pd.read_csv("../data/WA_Fn-UseC_-HR-Employee-Attrition.csv")
print(f"Dimensiones: {df.shape}")

# Calcular Turnover por departamento

turnover_dept = df.groupby('Department').agg(
    hc_actual = ('Attrition', 'count'),
    rotaciones =('Attrition', lambda x: (x=='Yes').sum())
).reset_index()
turnover_dept['turnover_anual'] = turnover_dept['rotaciones']/turnover_dept['hc_actual']
turnover_dept['tasa_mensual'] = turnover_dept['turnover_anual']/12

print("\n Turnover por departamento:")
#print(turnover_dept)
print(turnover_dept[['Department','hc_actual','rotaciones','turnover_anual']])

#Parametros de simulacion

fill_rate = 0.95
meses = 12

#proyeccion Mes a Mes

forecast_list = []
for _, row in turnover_dept.iterrows():
    dept = row['Department']
    hc = row['hc_actual']
    tasa_mensual = row['tasa_mensual']

    hc_series = [hc]
    for m in range(1, meses + 1):
        bajas = round(hc_series[-1] * tasa_mensual)
        contrataciones = round(bajas*fill_rate)
        hc_nuevo = hc_series[-1] - bajas + contrataciones
        hc_series.append(hc_nuevo)

        #crear DataFrame para este departemaneto

    df_dept = pd.DataFrame({
        'Department': dept,
        'mes': range(0, meses + 1),
        'headcount': hc_series
    })
    forecast_list.append(df_dept)

df_forecast = pd.concat(forecast_list, ignore_index=True)

df_forecast.to_csv("../outputs/tablas/05_kpi5_forecast/forecast_headcount_Py.csv")
print("\n Tabla de proyeccion guardada en ../outputs/tablas/05_kpi5_forecast/forecast_headcount_Py.csv")

# Grafico de Lineas

plt.figure(figsize = (10 , 6))
colores = {
        'Human Resources': '#C0392B',
        'Research & Development': '#27AE60',
        'Sales': '#1F3C6E'
}
for dept in df_forecast['Department'].unique():
    subset = df_forecast[df_forecast['Department'] == dept]
    plt.plot(subset['mes'], subset['headcount'], marker='o', linewidth=2, 
             label=dept, color=colores.get(dept, '#333333'))

plt.title('Proyección de Headcount a 12 meses por Departamento (fill rate 95%)', fontsize=14)
plt.xlabel('Mes')
plt.ylabel('Número de empleados')
plt.legend(title='Departamento', loc='upper left')
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig("../outputs/graficos/05_kpi5_forecast/forecast_lines_Py.png", dpi=150)
plt.close()
print("✅ Gráfico guardado en ../outputs/graficos/05_kpi5_forecast/forecast_lines_Py.png")

# Resumen Final (headcount a 12 meses)

resumen_final = df_forecast[df_forecast['mes'] == meses].copy()
resumen_final = resumen_final.merge(
    turnover_dept[['Department', 'hc_actual']], on = 'Department', how = 'left'
)
resumen_final['cambio'] = resumen_final['headcount']- resumen_final['hc_actual']

print(f"\n Resumen Final 12 meses:")
print(resumen_final[['Department','hc_actual', 'headcount','cambio']])

resumen_final.to_csv("../outputs/tablas/05_kpi5_forecast/forecast_summary_Py.csv", index = False)
print("Resumen Guardado")