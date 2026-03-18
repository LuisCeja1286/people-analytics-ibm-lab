#Ejecutar una sola vez
packages <- c(
  "tidyverse",  #Manipulación y graficos
  "survival",   #Análisis de supervivenvia
  "survminer",  #Visualizacion de curvas survival
  "ggplot2",    #Gráfricos
  "dplyr",      #Manipulacion
  "tidyr"      #Reordenamientro
  )

# Instala los que falten

installed <- rownames(installed.packages())
for (p in packages) {
  if(!(p %in% installed)){
      install.packages(p)
  }
  
}

lapply(packages, library, character.only = TRUE)

cat("Todos los paquetes instalados y cargados. \n")