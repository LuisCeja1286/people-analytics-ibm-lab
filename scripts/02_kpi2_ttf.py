# scripts/02_kpi2_ttf.py
# Time-to-fill simulado

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os

#crear carpetas de output si se ejecuta primero esta script

os.makedirs("../outputs/tablas/02_kpi2_ttf", exist_ok= True)
os.makedirs("../outputs/graficos/02_kpi2_ttf", exist_ok= True)

#random

np.random.seed(42)

#cargar datos

df = pd.read_csv("../data/WA_Fn-UseC_-HR-Employee-Attrition.csv")
print(f"Dimensiones: {df.shape}")
print(f"Valores nulos: {df.isnull().sum().sum()}")

#filtro de colaboradores que se fueron (Attition = Yes)

salidas = df[df['Attrition']== 'Yes'][['Department', 'JobRole', 'JobLevel', 'MonthlyIncome']].copy()
print(f"\nTotal de bajas:  {len(salidas)}")

#Simular Dias para cubrir vacantes 
#días base según nivel(bechmarks)
dias_base= {1:20,2:30,3:45,4:65,5:85}
salidas['dias_base'] = salidas['JobLevel'].map(dias_base)

#añade una columna con variacion aleatoria entre -10 y +20 dias

salidas['days_to_fill'] = salidas['dias_base'] + np.random.randint(-10, 21, size=len(salidas))
salidas['days_to_fill'] = salidas['days_to_fill'].clip(lower=1) #evita negativos

#calcula el costo por vacante

salidas['costo_vacante'] = salidas['days_to_fill'] * (salidas['MonthlyIncome'].mean() * 12/365)
print(salidas)
#Resumen por departamento y nivel

ttf_resumen = (
    salidas.groupby(['Department','JobLevel'])
    .agg(
        n_vacantes = ('days_to_fill', 'count'),
        avg_ttf = ('days_to_fill', 'mean'),
        median_ttf = ('days_to_fill', 'median'),
        min_ttf = ('days_to_fill', 'min'),
        max_ttf = ('days_to_fill', 'max'),
        avg_costo = ('costo_vacante', 'mean')
    )
    .round(2)
    .reset_index()
    .sort_values(['Department','JobLevel'])
    )

print("\n📋 Resumen de Time-to-Fill por Departamento y Nivel:")
print(ttf_resumen.to_string(index=False))

#Guardar en CSV

ttf_resumen.to_csv("../outputs/tablas/02_kpi2_ttf/ttf_resumen_Py.csv", index=False)
print(f"\n Tabla guardada en ../outputs/tablas/02_kpi2_ttf/ttf_resumen_Py.csv")

# visualizaciones
# Configurar estilo
sns.set_theme(style="whitegrid")
colores_depto = {
    'Human Resources': '#C0392B',
    'Research & Development': '#27AE60',
    'Sales': '#1F3C6E'
}

# Boxplot por nivel, coloreado por departamento
plt.figure(figsize=(12, 6))
ax = sns.boxplot(
    data=salidas,
    x='JobLevel',
    y='days_to_fill',
    hue='Department',
    palette=colores_depto,
    boxprops = {'alpha':0.7}
)
plt.title('Time-to-Fill por Nivel de Puesto\nDistribución de días para cubrir vacantes', fontsize=14)
plt.xlabel('Nivel de Puesto (1=entrada, 5=directivo)')
plt.ylabel('Días')
plt.legend(title='Departamento', bbox_to_anchor=(0.5,-0.15), loc='upper center', ncol = len(colores_depto), frameon = False)
plt.tight_layout()
plt.savefig("../outputs/graficos/02_kpi2_ttf/kpi2_ttf_boxplot_Py.png", dpi=150, bbox_inches='tight')
plt.close()
print(" Boxplot guardado en outputs/graficos/02_kpi2_ttf/kpi2_ttf_boxplot_Py.png")

# gráfico de barras con promedios por departamento y nivel
# Crear etiqueta combinada
ttf_resumen = ttf_resumen.sort_values('avg_ttf', ascending=True).copy()
ttf_resumen['dept_nivel'] = (ttf_resumen['Department'].astype(str) + ' - ' + ttf_resumen['JobLevel'].astype(str))

plt.figure(figsize=(14, 6))
bars = plt.bar(
    ttf_resumen['dept_nivel'],
    ttf_resumen['avg_ttf'],
    color=[colores_depto[d] for d in ttf_resumen['Department']],
    alpha=0.8
)

# Añadir etiquetas con el valor
for bar, val in zip(bars, ttf_resumen['avg_ttf']):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1, f'{val:.1f}',
             ha='center', va='bottom', fontsize=9)

plt.title('Promedio de Time-to-Fill por Departamento y Nivel', fontsize=14)
plt.xlabel('')
plt.ylabel('Días promedio')
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
plt.savefig("../outputs/graficos/02_kpi2_ttf/kpi2_ttf_barras_Py.png", dpi=150, bbox_inches='tight')
plt.close()
print("Gráfico de barras guardado en ../outputs/graficos/02_kpi2_ttf/kpi2_ttf_barras_Py.png")


# Estadisticas globales en formato Moneda Check
# ============================================================
costo_total = salidas['costo_vacante'].sum()
costo_promedio = salidas['costo_vacante'].mean()

print("\n ESTADÍSTICAS GLOBALES:")
print(f"  Costo total estimado de todas las vacantes: ${costo_total:,.0f}")
print(f"  Costo promedio por vacante: ${costo_promedio:,.0f}")
print("="*75)
print("\n KPI 2 completado en Python.")