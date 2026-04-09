# scripts/03_kpi3_survival.py
# Kaplan-Meier Survival Analysis con lifeline

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
from lifelines import KaplanMeierFitter
from lifelines.statistics import logrank_test

#crear carpetas si se ejecuta primero este script

os.makedirs("../outputs/tablas/03_kpi3_survival", exist_ok= True)
os.makedirs("../outputs/graficos/03_kpi3_survival", exist_ok= True)

# semilla
np.random.seed(42)

# cargar datos

df = pd.read_csv("../data/WA_Fn-UseC_-HR-Employee-Attrition.csv")
print(f"Dimensiones:  {df.shape}")
print(f"Valores nulos:  {df.isnull().sum().sum()}")

# preparar datos para survival
#duracion: años en la empresa (YearsAtCompany)
# event: 1 si Attrition == "Yes", 0 si no

df_surv = df.copy()
df_surv['event'] = (df_surv['Attrition'] == 'Yes').astype(int)
df_surv['duration'] = (df_surv['YearsAtCompany'])

#print (df_surv)

#Kapln-Meier Global

kmf_global = KaplanMeierFitter()
kmf_global.fit(durations = df_surv['duration'], event_observed = df_surv['event'], label = 'Global')
median_gloal = kmf_global.median_survival_time_
print(f"\nMediana de supervivencia global: {median_gloal:.2f} años")

#Kaplan-Meier por departamento

departments = df_surv['Department'].unique()
kmf_dict = {}
medians = []

colores_depto = {
    'Human Resources': '#C0392B',
    'Research & Development': '#27AE60',
    'Sales': '#1F3C6E'
    }

plt.figure(figsize=(10,6))

for dept in departments:
    mask = df_surv['Department'] == dept
    kmf = KaplanMeierFitter()
    kmf.fit(durations = df_surv.loc[mask, 'duration'],
            event_observed = df_surv.loc[mask, 'event'],
            label = dept)
    kmf_dict[dept] = kmf

    # Extraer mediana
    med = kmf.median_survival_time_
    medians.append({'Department': dept, 'medians_years': round(med,2) if not np.isnan(med) else '>11'})

    #Dibujar curva y asignar color
    color = colores_depto.get(dept)
    kmf.plot_survival_function(ax=plt.gca(), color=color,linewidth = 2)

#configurar grafico

plt.title('Curva de Supervivencia por Depertamento (kaplan-Meier)')
plt.xlabel('Años en la empresa')
plt.ylabel('Probabilidad de Retención')
plt.legend(title='Departamento', loc = 'best')
plt.grid(alpha = 0.3)
plt.tight_layout()
plt.savefig("../outputs/graficos/03_kpi3_survival/kpi3_survival_curves_Py.png", dpi = 150)
plt.close()
print("Grafico guardado en outputs/graficos/03_kpi3_survival/kpi3_survival_curves_Py.png")

# Tabla de medianas

df_medians = pd.DataFrame(medians)
print("\nMedianas de supervivencia por Depertamento:")
print(df_medians)
df_medians.to_csv("../outputs/tablas/03_kpi3_survival/survival_medians_Py.csv", index = False)

# Como se realizo en R se necesita extraer la funcion de supervivencia y sus intervalos de confianza
#lifetimes no exporta directamente el intervalo de confianza, pero podemos obtenerlo mediante la tabla de eventos por el metodo confidence_interval de cada KM

survival_curves = []

for dept, kmf in kmf_dict.items():
    surv_df = kmf.survival_function_.reset_index() # kmf.survival_funtion_ ya incluye indice (tiempo)
    surv_df.columns = ['time', 'survival']
    ci = kmf.confidence_interval_ #DataFrame con columnas 'KM_estimate_lower_0.95' an upper
    surv_df['lower'] = ci.iloc[:,0].values
    surv_df['upper'] = ci.iloc[:,1].values
    survival_curves.append(surv_df)

df_suvival_curves = pd.concat(survival_curves, ignore_index=True)
df_suvival_curves.to_csv("../outputs/tablas/survival_curves_py.csv", index = False)
print(f"Tabla de curvas exportada: {df_suvival_curves.shape[0]} filas")

#LOG-RANK para comparar departamentos

if len(departments) >= 2:
    dept1 = 'Sales'
    dept2 = 'Research & Development'
    mask1 = df_surv['Department'] == dept1
    mask2 = df_surv['Department'] == dept2
    result = logrank_test(
        durations_A=df_surv.loc[mask1,'duration'],
        durations_B=df_surv.loc[mask2,'duration'],
        event_observed_A=df_surv.loc[mask1,'event'],
        event_observed_B=df_surv.loc[mask2,'event']
    )
    print(f"\n Log-rank test {dept1} vs {dept2}: p-value = {result.p_value:.4f}")