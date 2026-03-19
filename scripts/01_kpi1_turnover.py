import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Cargar dataset
df = pd.read_csv("../data/WA_Fn-UseC_-HR-Employee-Attrition.csv")

# Verificación rápida
print(f"Dimensiones: {df.shape}")
print(df['Attrition'].value_counts())
print(f"Valores nulos: {df.isnull().sum().sum()}\n")  
print("=" * 75)


#Turnover rate global
total = len(df)
bajas = df['Attrition'].value_counts()['Yes']
turnover_rate_global = (bajas/total)*100
print(f"Turnover Rate Global: {turnover_rate_global:.2f}%")

#Turnover rate por departamento
"""
turnover_dept = (
    df.groupby('Department')['Attrition']
    .apply(lambda x: (x == 'Yes').sum() / len(x) *100)
    .round(2)
    .reset_index(name = 'turnover_pct')
    .sort_values(by='turnover_pct', ascending = False)
)
print("\nTurnover Rate por Departamento:")
print(turnover_dept) 
"""

turnover_dept = (
    df.groupby('Department')['Attrition']
    .agg([
        ('total_empleados','count'),
        ('rotaciones',lambda x: (x== 'Yes').sum())
    ])
    .reset_index()
)
turnover_dept['turnover_pct'] = (turnover_dept['rotaciones'] / turnover_dept['total_empleados']*100).round(2)


def clasificacion_riesgo(tasa):
    if tasa >= 20:
        return 'Alto'
    elif tasa >= 10:
        return 'Medio'
    else:
        return 'Bajo'

turnover_dept['Riesgo'] = turnover_dept['turnover_pct'].apply(clasificacion_riesgo).reset_index(drop=True)
# Ordenar por tasa

turnover_dept = turnover_dept.sort_values('turnover_pct', ascending = False)

print("\nTurnover Rate por Departamento:")
print(turnover_dept)
print("=" * 75)

# inferencia de Attrition Voluntario o Involuntario utilizando la columna de JobSatisfaction

df['attrition_bin'] = (df['Attrition'] == 'Yes').astype(int)
bajas_df = df[df['Attrition'] == 'Yes'].copy()
bajas_df['Tipo'] = np.where(bajas_df['JobSatisfaction'] <=2, 'Voluntario', 'Involuntario')
tipo_count = bajas_df['Tipo'].value_counts()


print("\n Inferencia de tipo de baja")
print(tipo_count)

# Visualizacion

fig, axes = plt.subplots(1,2, figsize =(8,5))

#grafico de barras horizontal

bars = axes[0].barh(turnover_dept['Department'], turnover_dept['turnover_pct'],
                    color =['#C0392B' if r == 'Alto' else '#F39C12' if r == 'Medio' else '#27AE60'
                    for r in turnover_dept['Riesgo']])
axes[0].set_title('Turn Over Rate por Departamento', fontsize = 14)
axes[0].set_xlabel('Tasa de rotación (%)')
axes[0].invert_yaxis()

#Etiquetas de valor

for i , (tasa,riesgo) in enumerate(zip(turnover_dept['turnover_pct'], turnover_dept['Riesgo'])):
    axes[0].text(tasa + 0.5,i,f'{tasa}%', va='center',fontsize=10)

colors = ['#C0392B' if t == 'Voluntario' else '#1F3C6E' for t in tipo_count.index]
axes[1].pie(tipo_count, labels=tipo_count.index, autopct='%1.1f%%', colors=colors, startangle=90)
axes[1].set_title('Voluntario vs Involuntario (inferido)', fontsize=14)

plt.tight_layout()
plt.savefig('../outputs/graficos/kpi1_turnover_Py.png', dpi=300, bbox_inches='tight')
print("\n✅ Gráfico guardado en outputs/graficos/kpi1_turnover_Py.png")

#guardar tabla resumen

turnover_dept.to_csv('../outputs/tablas/turnover_dept_Py.csv', index = False)
print(f"✅  Tabla guardada en ../outputs/tablas/turnover_dept_Py.csv")

global_stats = pd.DataFrame({
    'total_empleados': [total],
    'rotaciones': [bajas],
    'tasa_turnover': [round(turnover_rate_global, 2)],
    'riesgo': [clasificacion_riesgo(turnover_rate_global)]
})



print("\n🌍 Turnover Global:")
print(global_stats.to_string(index=False))

global_stats.to_csv('../outputs/tablas/turnover_global_Py.csv', index = False)
print(f"✅  Tabla guardada en ../outputs/tablas/turnover_global_Py.csv")