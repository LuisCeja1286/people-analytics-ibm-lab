import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Cargar dataset
df = pd.read_csv("../data/WA_Fn-UseC_-HR-Employee-Attrition.csv")

# Verificación rápida
print(df.shape)
print(df['Attrition'].value_counts())
print(df.isnull().sum().sum())  
