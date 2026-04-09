# scripts/04_kpi4_pay_equity.py
# Analisis de quidad salarial por nivel (pay gap) y compa-ratio

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import statsmodels.api as sm
from statsmodels.formula.api import ols

os.makedirs("../outputs/tablas/04_kpi4_pay_equity", exist_ok= True)
os.makedirs("../outputs/graficos/04_kpi4_pay_equity", exist_ok= True)

#cargar datos

df = pd.read_csv("../data/WA_Fn-UseC_-HR-Employee-Attrition.csv")

# Pay-gap no ajustado

pay_gender = df.groupby('Gender')['MonthlyIncome'].agg([
    ('promedio','mean'),
    ('mediana','median'),
    ('n_empleados','count')]).round(2)
print("Pay-gap no ajustado:\n",pay_gender)
print("="*50)

promedio_hombre = pay_gender.loc['Male','promedio']
promedio_mujer = pay_gender.loc['Female','promedio']
gap_noajustado = (promedio_hombre-promedio_mujer)/promedio_hombre*100
print(f"Pay-Gap No ajustado (hombre-Mujer),{gap_noajustado:.2f}%")

# Pay gap ajustado por regresion (jobLevel, TotalWorkingYears, PerformanceRating)
#Convertir Gender a dummy (Male = 1, Female = 0)
df['Gender_Male']= (df['Gender'] == 'Male').astype(int)

model = ols('MonthlyIncome ~ JobLevel + TotalWorkingYears + PerformanceRating + Gender_Male',data=df).fit()
ajustado_gap = model.params['Gender_Male']
print(f"Gap-Ajustado (controlado por nivel, exp, desempeño): ${ajustado_gap:.2f}" )

#generar compa-ratio (salario/punto medio de la banda de jobLevel)

puntomedio = df.groupby('JobLevel')['MonthlyIncome'].median().reset_index()
puntomedio.columns = ['JobLevel','BandaMedia']
df=df.merge(puntomedio, on = 'JobLevel', how= 'left')
df['compa_ratio']=df['MonthlyIncome']/df['BandaMedia']
print("="*50)
print(puntomedio)
print("="*50)
compa_gender = df.groupby(['Gender','JobLevel'])['compa_ratio'].mean().round(3).reset_index()
print(f"\nCompa-ratio promedio por género y nivel:\n", compa_gender)

#Exportar tablas

pay_gender.to_csv("../outputs/tablas/04_kpi4_pay_equity/pay_gender_summary_Py.csv")
pd.DataFrame({
    'tipo':['No ajustado (%)', 'Ajustado ($)'],
    'valor':[round(gap_noajustado,2), round(ajustado_gap,2)]
}).to_csv("../outputs/tablas/04_kpi4_pay_equity/pay_gap_summary_Py.csv", index=False)
compa_gender.to_csv("../outputs/tablas/04_kpi4_pay_equity/compa_ratio_by_gender_level_Py.csv", index=False)

#Grafica de violin plot + boxplot
plt.figure(figsize=(10,6))
sns.violinplot(data=df, x='JobLevel', y='MonthlyIncome', hue = 'Gender', split=True, palette={'Female':'#C0392B','Male': '#1F3C6E'}, alpha =0.6)
sns.boxplot(data=df, x='JobLevel', y='MonthlyIncome', hue='Gender', palette={'Female':'#C0392B','Male': '#1F3C6E'}, width=0.1, linewidth=1)
plt.title('Distribucion salarial por nivel jerárquico y género')
plt.xlabel('Nivel de puesto (1=entry 5=director)')
plt.ylabel('Ingreso mensual (USD)')
plt.legend(title = 'Género')
plt.tight_layout()
plt.savefig("../outputs/graficos/04_kpi4_pay_equity/violin_plot_pay_equity_Py.png", dpi=150)
plt.close()
print(f"Grafico guardado en /outputs/graficos/04_kpi4_pay_equity/violin_plot_pay_equity_Py.png")