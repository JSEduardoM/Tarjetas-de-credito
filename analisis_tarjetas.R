# CASO DE ESTUDIO: REGRESIÓN LOGÍSTICA - TARJETAS DE CRÉDITO
# Curso: Ciencia de Datos II
# Docente: M.Sc. Alcides RAMOS CALCINA
# Estudiante: Julio Segundo EEduardo Maquera

# OBJETIVOS:
# 1) Construir un modelo predictivo (Aceptación de Tarjeta).
# 2) Evaluar capacidad predictiva (Matriz de Confusión y Precisión).

# 1. Carga de Librerías y Datos 

library(ggplot2)
library(dplyr)
library(caret)
library(pROC)
library(corrplot)

# Definir ruta del archivo
ruta_csv <- "c:/Users/User/Documents/SEMESTRE IX/CIENCIA DE DATOS II/TARJETAS DE CREDITO/DatosAERcreditcarddataxlsx.csv"

# Cargar datos
data <- read.csv(ruta_csv)

# Vista preliminar
print("Primeras filas del dataset:")
head(data)
str(data)

# 2. Preprocesamiento y Limpieza ----------------------------------------------

# Convertir variables categóricas a factores
# La variable objetivo parece ser 'card' (yes/no)
data$card <- as.factor(data$card)
data$owner <- as.factor(data$owner)
data$selfemp <- as.factor(data$selfemp)

# Verificar valores nulos
print("Valores nulos por columna:")
colSums(is.na(data))

# Resumen estadístico
summary(data)

# 3. Análisis Exploratorio de Datos (EDA) -------------------------------------

# Crear carpeta para gráficos si no existe
if(!dir.exists("graficos")) dir.create("graficos")

# Distribución de la variable objetivo
g1 <- ggplot(data, aes(x = card, fill = card)) +
  geom_bar() +
  labs(title = "Distribución de la Variable Objetivo (Card)", x = "Aprobación de Tarjeta", y = "Conteo") +
  theme_minimal()
print(g1)
ggsave("graficos/01_distribucion_card.png", g1, width = 8, height = 6)

# Relación Income vs Card
g2 <- ggplot(data, aes(x = card, y = income, fill = card)) +
  geom_boxplot() +
  labs(title = "Ingresos (Income) según Aprobación de Tarjeta", x = "Tarjeta", y = "Ingresos") +
  theme_minimal()
print(g2)
ggsave("graficos/02_income_vs_card.png", g2, width = 8, height = 6)

# Relación Age vs Card
g3 <- ggplot(data, aes(x = card, y = age, fill = card)) +
  geom_boxplot() +
  labs(title = "Edad (Age) según Aprobación de Tarjeta", x = "Tarjeta", y = "Edad") +
  theme_minimal()
print(g3)
ggsave("graficos/03_edad_vs_card.png", g3, width = 8, height = 6)

# Correlaciones numéricas
numeric_vars <- data %>% select_if(is.numeric)
cor_matrix <- cor(numeric_vars)
png("graficos/04_matriz_correlacion.png", width = 800, height = 600)
# Ajustar márgenes para el título en corrplot
par(mar = c(2, 2, 4, 2))
corrplot(cor_matrix, method = "color", type = "upper", addCoef.col = "black", tl.col = "black", tl.srt = 45, title = "Matriz de Correlación", number.cex = 0.7)
dev.off()
# Volver a imprimir en consola
corrplot(cor_matrix, method = "color", type = "upper", addCoef.col = "black", tl.col = "black", tl.srt = 45, title = "Matriz de Correlación", number.cex = 0.7)


# 4. Modelado: Regresión Logística --------------------------------------------

# Dividir en entrenamiento y prueba (70% - 30%)
set.seed(123)
trainIndex <- createDataPartition(data$card, p = .7, 
                                  list = FALSE, 
                                  times = 1)
dataTrain <- data[ trainIndex,]
dataTest  <- data[-trainIndex,]

# 4. Modelado: Regresión Logística --------------------------------------------

# Dividir en entrenamiento y prueba (70% - 30%)
set.seed(123)
trainIndex <- createDataPartition(data$card, p = .7, 
                                  list = FALSE, 
                                  times = 1)
dataTrain <- data[ trainIndex,]
dataTest  <- data[-trainIndex,]


# --- MODELO 1: REGRESIÓN LOGÍSTICA SIMPLE ---
# Variable Independiente determinante elegida: 'reports'
# Se elije 'reports' porque el historial negativo es usualmente determinante.

print("-----------------------------------------------------------------------")
print("MODELO 1: Regresión Logística SIMPLE (Variable: reports)")
print("-----------------------------------------------------------------------")

model_simple <- glm(card ~ reports, family = binomial(link = "logit"), data = dataTrain)
print(summary(model_simple))

# Evaluación Modelo Simple
prob_simple <- predict(model_simple, newdata = dataTest, type = "response")
pred_simple <- ifelse(prob_simple > 0.5, "1", "0")
pred_simple <- factor(pred_simple, levels = c("0", "1"))

cm_simple <- confusionMatrix(pred_simple, dataTest$card, positive = "1", mode = "prec_recall") 
print("Matriz de Confusión - Modelo Simple:")
print(cm_simple)
print(paste("Precisión (Positive Predictive Value) - Modelo Simple:", round(cm_simple$byClass['Precision'], 4)))


# --- MODELO 2: REGRESIÓN LOGÍSTICA MÚLTIPLE ---
# Considera TODAS las variables independientes

print("-----------------------------------------------------------------------")
print("MODELO 2: Regresión Logística MÚLTIPLE (Todas las variables)")
print("-----------------------------------------------------------------------")

model_multiple <- glm(card ~ ., family = binomial(link = "logit"), data = dataTrain)
print(summary(model_multiple))

# Evaluación Modelo Múltiple
prob_multiple <- predict(model_multiple, newdata = dataTest, type = "response")
pred_multiple <- ifelse(prob_multiple > 0.5, "1", "0")
pred_multiple <- factor(pred_multiple, levels = c("0", "1"))

cm_multiple <- confusionMatrix(pred_multiple, dataTest$card, positive = "1", mode = "prec_recall")
print("Matriz de Confusión - Modelo Múltiple:")
print(cm_multiple)
print(paste("Precisión (Positive Predictive Value) - Modelo Múltiple:", round(cm_multiple$byClass['Precision'], 4)))
# 5. Comparación Visual de Modelos --------------------------------------------

# Calcular curvas ROC
roc_simple <- roc(dataTest$card, prob_simple)
roc_multiple <- roc(dataTest$card, prob_multiple)

# Recopilar métricas en un Data Frame
metrics_simple <- c(
  Accuracy = cm_simple$overall['Accuracy'],
  Precision = cm_simple$byClass['Precision'],
  AUC = as.numeric(auc(roc_simple))
)

metrics_multiple <- c(
  Accuracy = cm_multiple$overall['Accuracy'],
  Precision = cm_multiple$byClass['Precision'],
  AUC = as.numeric(auc(roc_multiple))
)

comparison_df <- data.frame(
  Metric = rep(c("Accuracy", "Precision", "AUC"), 2),
  Model = c(rep("Simple (Reports)", 3), rep("Multiple (All)", 3)),
  Value = c(metrics_simple, metrics_multiple)
)

# Gráfico de Barras Comparativo
g_compare <- ggplot(comparison_df, aes(x = Metric, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_text(aes(label = round(Value, 3)), vjust = -0.5, position = position_dodge(0.9), size = 3) +
  labs(title = "Comparación de Modelos: Simple vs Múltiple", 
       subtitle = "Accuracy, Precision y AUC",
       y = "Valor de la Métrica") +
  theme_minimal() +
  scale_fill_brewer(palette = "Paired")

print(g_compare)
ggsave("graficos/05_comparacion_metricas.png", g_compare, width = 8, height = 6)

# 6. Importancia de Variables (Modelo Múltiple) -------------------------------

# 6. Importancia de Variables (Modelo Múltiple) -------------------------------

# Calcular Cambio Porcentual en las Odds: (OR - 1) * 100
# Esto indica cuánto aumenta o disminuye la probabilidad (en odds) por unidad de cambio
coeficientes <- coef(model_multiple)
odds_ratios <- exp(coeficientes)
percent_change <- (odds_ratios - 1) * 100

imp_df <- data.frame(
  Variable = names(percent_change),
  Porcentaje = percent_change
)
imp_df <- imp_df[imp_df$Variable != "(Intercept)", ] # Quitar intercepto

# Clasificar efecto para colores
imp_df$Efecto <- ifelse(imp_df$Porcentaje > 0, "Aumenta Prob.", "Disminuye Prob.")

# Gráfico de Barras con Porcentajes
g_imp <- ggplot(imp_df, aes(x = reorder(Variable, Porcentaje), y = Porcentaje, fill = Efecto)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = paste0(round(Porcentaje, 1), "%")), 
            hjust = ifelse(imp_df$Porcentaje > 0, -0.1, 1.1), 
            size = 3.5, fontface = "bold") +
  coord_flip() +
  labs(title = "Importancia de Variables (Cambio % en Odds)",
       subtitle = "Porcentaje en que aumenta/disminuye la probabilidad de aceptación",
       x = "Variable",
       y = "Cambio Porcentual (%)") +
  scale_fill_manual(values = c("Aumenta Prob." = "#2E8B57", "Disminuye Prob." = "#CD5C5C")) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(g_imp)
ggsave("graficos/06_importancia_variables.png", g_imp, width = 8, height = 6)

# 7. Comparación ROC (Estético) -----------------------------------------------

# Crear dataframe para ggplot ROC
roc_simple_df <- data.frame(Specificity = roc_simple$specificities, Sensitivity = roc_simple$sensitivities, Model = "Simple")
roc_multiple_df <- data.frame(Specificity = roc_multiple$specificities, Sensitivity = roc_multiple$sensitivities, Model = "Multiple")

roc_combined <- rbind(roc_simple_df, roc_multiple_df)

g_roc <- ggplot(roc_combined, aes(x = 1 - Specificity, y = Sensitivity, color = Model, linetype = Model)) +
  geom_line(size = 1) +
  geom_abline(linetype = "dashed", color = "gray") +
  labs(title = "Curvas ROC Comparativas (2 Modelos)",
       subtitle = paste("AUC Simple:", round(metrics_simple['AUC'], 3), 
                        "| Full:", round(metrics_multiple['AUC'], 3))) +
  theme_minimal() +
  scale_color_brewer(palette = "Set1")

print(g_roc)
ggsave("graficos/07_curvas_roc.png", g_roc, width = 8, height = 6)

# 8. RESUMEN DE INTERPRETACIÓN DE DATOS (Insights) ----------------------------

print("-----------------------------------------------------------------------")
print("RESUMEN DE INTERPRETACIÓN PARA EL NEGOCIO (CASO DE ESTUDIO)")
print("-----------------------------------------------------------------------")

# Ordenar por impacto absoluto para identificar los drivers principales
imp_df_sorted <- imp_df[order(abs(imp_df$Porcentaje), decreasing = TRUE), ]

# Función para formatear el mensaje
imprimir_insight <- function(row) {
  var <- row['Variable']
  per <- round(as.numeric(row['Porcentaje']), 1)
  if (per < 0) {
    cat(sprintf("- La variable '%s' disminuye las probabilidades en un %s%% (Factor de Riesgo).\n", var, abs(per)))
  } else {
    cat(sprintf("- La variable '%s' aumenta las probabilidades en un %s%% (Factor de Solvencia).\n", var, per))
  }
}

cat("Hallazgos Principales:\n")
apply(head(imp_df_sorted, 5), 1, imprimir_insight)

cat("\nConclusión del Caso:\n")
cat("El modelo múltiple revela que, aunque los informes negativos (reports) son el mayor impedimento,
la solvencia medida por los ingresos (income) y la experiencia previa (active accounts) son los 
motores principales para la aceptación. El banco debería priorizar estos factores para una 
decisión equilibrada.\n")
cat("-----------------------------------------------------------------------\n")

