# scripts/00_setup.py
import subprocess
import sys

required_packages = [
    'pandas', 'numpy', 'matplotlib', 'seaborn', 
    'plotly', 'scipy', 'lifelines', 'faker', 'scikit-learn'
]

for package in required_packages:
    try:
        __import__(package)
        print(f"✅ {package} ya está instalado.")
    except ImportError:
        print(f"📦 Instalando {package}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])

print("\n🎉 Entorno listo para trabajar.")