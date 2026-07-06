# Plan de Estudio: Terraform + AWS + Floci

Este documento registra las fases de aprendizaje acordadas para construir el pipeline completo de clickstream y ML. Sirve como guia en caso de retomar el proyecto en otra sesion.

---

## Fase 1: Fundamentos de Terraform y Recursos AWS (COMPLETAR PRIMERO)

**Objetivo:** Aprender la sintaxis de Terraform y cada servicio AWS por separado.

**Archivo:** `ejercicios.md` (50 ejercicios)

**Temas cubiertos:**
- Bloques `resource`, `data`, `variable`, `output`, `locals`
- Ciclo `terraform init / plan / apply / destroy`
- Dependencias implicitas entre recursos
- Backend local (archivo `terraform.tfstate`)
- Servicios: S3, DynamoDB, IAM, Lambda, API Gateway v2, ECS, ECR
- Provider de Floci apuntando a `localhost:4566`
- Verificacion con AWS CLI + Floci UI

**Progresion:**
| Nivel | Ejercicios | Que aprendes |
|---|---|---|
| Basico | 1 - 20 | Sintaxis pura, un recurso a la vez |
| Intermedio | 21 - 35 | Combinar 2-3 recursos, configuraciones mas complejas |
| Avanzado | 36 - 50 | Funciones avanzadas de Terraform y servicios |

**Salida:** Poder crear cualquier recurso AWS individual desde Terraform sin ayuda.

---

## Fase 2: Conexion entre Recursos

**Objetivo:** Aprender como los servicios se conectan y comunican entre si.

**Temas:**
- Lambda que escribe a DynamoDB (IAM policy + boto3 SDK)
- API Gateway que invoca Lambda (integracion AWS_PROXY)
- S3 que notifica a Lambda (bucket notification)
- ECS service con Application Load Balancer
- IAM roles complejas (execution role vs task role)
- Paso de variables de entorno entre servicios
- Outputs de Terraform para conectar frontend

**Progresion:**
- Ejercicios especificos con instrucciones paso a paso (no escenarios abiertos)

**Salida:** Poder conectar 3 servicios distintos en una sola configuracion de Terraform.

---

## Fase 3: Escenarios Abiertos (El Proyecto)

**Objetivo:** Resolver problemas reales de negocio disenando la arquitectura completa.

**Formato:** Situacion de negocio sin solucion unica. Tu decides la arquitectura, escribes el codigo, lo pruebas.

**Ejemplos:**
- "Flocorp necesita almacenar eventos de clickstream, procesarlos en tiempo real y guardar resultados en S3."
- "El equipo de ML quiere un endpoint de inferencia que no tenga cold start y soporte modelos de 5 GB."

**Salida:** Pipeline completo del proyecto: frontend -> API Gateway -> Lambda -> DynamoDB + S3 + ECS predict.

---

## Notas para el estudiante

- Cada ejercicio de la Fase 1 se verifica con comandos `aws --endpoint-url http://localhost:4566` contra Floci.
- Si un ejercicio falla, Terraform muestra el error exacto. Lees el error, corriges, vuelves a aplicar.
- No pasar a la siguiente fase sin completar la anterior. Los conceptos son acumulativos.
- Usa `terraform destroy` al final de cada ejercicio para limpiar recursos.
- El orden de los ejercicios importa. Cada uno asume que entiendes los anteriores.
