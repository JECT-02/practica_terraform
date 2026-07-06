# Ejercicios de Terraform + Floci: Fase 1

Bienvenido a tu entrenamiento como Cloud Engineer en **Flocorp**, una startup que esta migrando su infraestructura a la nube. Tu jefa te asigna tareas progresivas para construir los cimientos del data lake.

---

## Como funciona todo

```
Tu PC                  Floci (contenedor Docker)
┌─────────┐            ┌──────────────────────┐
│ Terraform│──API────▶│  Emula AWS:           │
│ AWS CLI  │           │  S3, Lambda, DynamoDB │
│          │◀──resp──│  IAM, ECS, API Gateway │
└─────────┘           │  Puerto 4566          │
                       └──────────────────────┘
```

**Floci** es un emulador de AWS que corre en un contenedor Docker en tu maquina. Escucha en `http://localhost:4566` y responde exactamente como AWS real, pero sin costos ni cuenta en la nube.

**Terraform** se conecta a Floci como si fuera AWS real. Cuando escribes `resource "aws_s3_bucket"`, Terraform envia la peticion a `localhost:4566` y Floci crea un bucket simulado.

**AWS CLI** lo usas para verificar que los recursos se crearon correctamente, igual que hariamos en AWS real pero apuntando a Floci.

**Cada pieza tiene un motivo:**
| Herramienta | Para que sirve | Por que es importante |
|---|---|---|
| **Floci** | Emula AWS localmente | Sin costos, sin cuenta real, sin esperar despliegues |
| **Terraform** | Escribir infraestructura como codigo | Versionas, revisas planes, destruyes y recreas al instante |
| **AWS CLI** | Verificar los recursos | Confirmas que lo que creaste existe y funciona |

---

## Arrancar el entorno (hazlo antes de cada sesion)

### 1. Iniciar Floci

```powershell
floci start
```

Salida real al ejecutarlo:
```
Removing stopped container 'floci'...
Checking image floci/floci:latest (policy: missing)...
Starting Floci container...
Container started (c15f267928c9)
Waiting for Floci to be ready...
Waiting... (29s remaining)   Floci is ready (http://localhost:4566)
```

*Que hace:* Descarga (si es primera vez) y arranca un contenedor Docker con Floci en `localhost:4566`. Por defecto espera hasta que Floci este listo.

*Por que:* Sin Floci corriendo, Terraform no tiene a quien llamar. Todo falla con errores de conexion.

*Verificar que esta vivo:*
```powershell
floci status
```
Salida real:
```
Floci Status

  Container:  floci  running
  Image:      floci/floci:latest
  Ports:      4566->4566/tcp
  Endpoint:   http://localhost:4566
  Reachable:  yes
  Version:    1.5.30
  Edition:    floci-always-free
```

### 2. Configurar las variables de entorno

```powershell
floci env --shell powershell | Invoke-Expression
```

*Que hace:* Exporta estas variables en tu terminal:

| Variable | Valor | Por que |
|---|---|---|
| `AWS_ENDPOINT_URL` | `http://localhost:4566` | Le dice al AWS CLI y SDKs que hablen con Floci, no con AWS real |
| `AWS_ACCESS_KEY_ID` | `test` | Credenciales fake — Floci acepta cualquier valor no vacio |
| `AWS_SECRET_ACCESS_KEY` | `test` | Igual que arriba |
| `AWS_DEFAULT_REGION` | `us-east-1` | Region por defecto, en Floci da igual cual uses |

*Por que:* Sin estas variables, `aws s3 ls` intentaria conectarse a AWS real y pediria credenciales reales. Con `floci env`, todo apunta a Floci.

> **Importante:** `floci env --shell powershell | Invoke-Expression` solo afecta la terminal actual. Si abres otra terminal, tendras que ejecutarlo de nuevo.

### 3. Probar que todo funciona

```powershell
aws sts get-caller-identity
```

Debe devolver:
```json
{
  "UserId": "test",
  "Account": "000000000000",
  "Arn": "arn:aws:iam::000000000000:user/test"
}
```

Si ves esto, **Floci esta funcionando y el AWS CLI apunta a el**. Todo conecta.

---

## Flujo de trabajo en cada ejercicio

```
1. Creas carpeta:     mkdir ejercicioXX/ && cd ejercicioXX/
2. Escribes codigo:   main.tf, variables.tf, outputs.tf, etc.
3. Inicias Terraform: terraform init      (descarga providers, una vez por carpeta)
4. Vees el plan:      terraform plan       (que va a crear/modificar/destruir)
5. Aplicas:           terraform apply      (ejecuta el plan, crea recursos en Floci)
6. Verificas:         aws <comando>        (confirmas con AWS CLI que existe)
7. Limpias:           terraform destroy    (elimina todo, deja Floci limpio)
8. Repites:           pasas al siguiente ejercicio, carpeta nueva desde cero
```

**Por que cada paso importa:**

| Paso | Que enseña | Si lo saltas... |
|---|---|---|
| `init` | Descarga el provider de AWS | Terraform no sabe como hablar con Floci |
| `plan` | Muestra el diff sin ejecutar | Aplicas cambios ciegamente, riesgo de sorpresas |
| `apply` | Ejecuta la infraestructura | No creas nada |
| `verify` | Confirmas con AWS CLI | No sabes si realmente funciono |
| `destroy` | Limpia recursos | Acumulas basura y el siguiente ejercicio se contamina |

> **Regla de oro:** Cada ejercicio es independiente. Carpeta nueva, `terraform init`, al terminar `terraform destroy`, y pasas al siguiente. Asi nunca mezclas estados.

---

## Verde Nivel Basico (1 - 20)
*Objetivo: Familiarizarte con la sintaxis de Terraform y crear recursos Floci individuales. Un recurso a la vez.*

---

### 1. Hola Terraform: configurar el provider

Tu jefa te pide preparar el entorno de trabajo. Necesitas un archivo de Terraform que configure el provider de Floci apuntando a Floci.

Crea `main.tf` con:
- `required_providers` con `hashicorp/aws`
- Provider block con `endpoint = "http://localhost:4566"`, `region = "us-east-1"`, `access_key = "test"`, `secret_key = "test"`
- `skip_credentials_validation = true`, `skip_requesting_account_id = true`, `skip_metadata_api_check = true`, `s3_use_path_style = true`

Luego ejecuta `terraform init`. Debe descargar el provider y quedar listo.

**Verificacion:** `terraform init` debe terminar con "Terraform has been successfully initialized!"

**PISTA EJERCICIO 1**

PISTA: Configura `required_providers` con `hashicorp/aws` y un bloque `provider` con los endpoints de Floci.
---

### 2. Mi primer bucket S3

El equipo de data lake necesita un bucket para almacenar eventos crudos. Crea un bucket S3 con nombre `flocorp-eventos-raw`.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 s3 ls
```
Debe aparecer `flocorp-eventos-raw`.

**PISTA EJERCICIO 2**

PISTA: Usa el recurso `aws_s3_bucket` con el nombre del bucket.
---

### 3. Bucket con etiquetas

El equipo de FinOps necesita etiquetar todos los recursos para asignar costos. Agrega las siguientes etiquetas al bucket anterior:
- `Environment = "dev"`
- `Project = "clickstream"`
- `Owner = "data-engineering"`

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 s3api get-bucket-tagging --bucket flocorp-eventos-raw
```

**PISTA EJERCICIO 3**

PISTA: Las etiquetas se agregan como un mapa `tags` dentro del recurso.
---

### 4. Versionado en S3

El equipo de auditoria exige que los eventos no se pierdan ante sobrescrituras accidentales. Habilita el versionado en el bucket `flocorp-eventos-raw` usando el recurso `aws_s3_bucket_versioning`.

**Nota:** En Floci el versionado puede no comportarse exactamente igual que en Floci real, pero la configuracion de Terraform es la misma.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 s3api get-bucket-versioning --bucket flocorp-eventos-raw
```

**PISTA EJERCICIO 4**

PISTA: Terraform tiene un recurso separado `aws_s3_bucket_versioning`.
---

### 5. Tabla DynamoDB basica

El equipo de sesiones necesita una tabla para almacenar estado de sesion de usuarios. Crea una tabla DynamoDB llamada `flocorp-sesiones` con:
- Clave de particion (hash key): `session_id` (String)
- Modo de facturacion: `PAY_PER_REQUEST`

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 dynamodb describe-table --table-name flocorp-sesiones
```

**PISTA EJERCICIO 5**

PISTA: Define `hash_key` y un bloque `attribute` en `aws_dynamodb_table`.
---

### 6. Clave de ordenamiento en DynamoDB

El equipo de analisis necesita consultar eventos por sesion ordenados por timestamp. Modifica la tabla `flocorp-sesiones` para agregar una clave de ordenamiento (sort key) `event_timestamp` (String).

**Nota:** En Terraform, la clave de ordenamiento se define en `range_key`. Los atributos se listan dentro de `attribute`.

**Verificacion:** El comando `describe-table` debe mostrar `KeySchema` con dos elementos (HASH y RANGE).

**PISTA EJERCICIO 6**

PISTA: Agrega `range_key` y un segundo bloque `attribute`.
---

### 7. TTL en DynamoDB

Las sesiones deben expirar automaticamente tras 60 segundos. Habilita TTL en la tabla `flocorp-sesiones` sobre el atributo `ttl`.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 dynamodb describe-time-to-live --table-name flocorp-sesiones
```

**PISTA EJERCICIO 7**

PISTA: Usa `aws_dynamodb_table_ttl` para habilitar expiracion automatica.
---

### 8. Rol IAM para Lambda

Antes de crear funciones Lambda, necesitas un rol que Lambda asuma para ejecutarse. Crea un rol IAM llamado `flocorp-lambda-exec-role` que permita al servicio `lambda.amazonaws.com` asumirlo (trust policy).

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 iam get-role --role-name flocorp-lambda-exec-role
```

**PISTA EJERCICIO 8**

PISTA: El rol IAM necesita un `assume_role_policy` en formato JSON.
---

### 9. Politica IAM para S3

El equipo de ingestion necesita que Lambda pueda escribir objetos en S3. Crea una politica IAM llamada `flocorp-s3-write-policy` que permita `s3:PutObject` en el bucket `flocorp-eventos-raw` y todos sus objetos (`arn:aws:s3:::flocorp-eventos-raw/*`).

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 iam get-policy --policy-arn arn:aws:iam::000000000000:policy/flocorp-s3-write-policy
```

**PISTA EJERCICIO 9**

PISTA: Usa `jsonencode()` dentro de `aws_iam_policy` para definir permisos.
---

### 10. Adjuntar politica al rol

Una politica sin un rol no sirve. Adjunta la politica `flocorp-s3-write-policy` al rol `flocorp-lambda-exec-role` usando `aws_iam_role_policy_attachment`.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 iam list-attached-role-policies --role-name flocorp-lambda-exec-role
```

**PISTA EJERCICIO 10**

PISTA: `aws_iam_role_policy_attachment` conecta una politica a un rol.
---

### 11. Primera funcion Lambda

El equipo de backend necesita una funcion Lambda que procese eventos. Crea una funcion Lambda llamada `flocorp-processor` con:
- Runtime: Python 3.12
- Handler: `handler.lambda_handler`
- Rol: el que creaste en el ejercicio 8
- Codigo: crea un archivo `handler.py` con una funcion que recibe `event` y `context` y retorna `{"statusCode": 200, "body": "ok"}`

Empaqueta el codigo con `Compress-Archive` (PowerShell) o el `data.archive_file` de Terraform (lo veremos en el ejercicio 14). Por ahora, usa un zip manual.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 lambda invoke --function-name flocorp-processor output.txt
type output.txt
```

**PISTA EJERCICIO 11**

PISTA: Crea un zip con tu codigo Python y usalo en `aws_lambda_function`.
---

### 12. Variables de entorno en Lambda

La funcion Lambda necesita saber a que bucket y tabla DynamoDB debe escribir. Agrega variables de entorno:
- `BUCKET_NAME = "flocorp-eventos-raw"`
- `TABLE_NAME = "flocorp-sesiones"`

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 lambda get-function-configuration --function-name flocorp-processor
```
Debe mostrar `Environment` con las variables.

**PISTA EJERCICIO 12**

PISTA: Dentro de `aws_lambda_function` hay un bloque `environment` para variables.
---

### 13. Timeout y memoria

La funcion Lambda actual tiene timeout default de 3 segundos, pero el procesamiento de eventos puede demorar mas. Configura:
- `timeout = 30` (segundos)
- `memory_size = 256` (MB)

**Verificacion:** El comando `get-function-configuration` debe mostrar `Timeout: 30` y `MemorySize: 256`.

**PISTA EJERCICIO 13**

PISTA: `timeout` y `memory_size` son atributos directos del recurso Lambda.
---

### 14. Empaquetado automatico con archive_file

Tener que comprimir el zip a mano cada vez que cambias el codigo es tedioso. Usa el data source `archive_file` para que Terraform genere el zip automaticamente.

Requiere agregar `hashicorp/archive` en `required_providers`.

**Verificacion:** Al cambiar `handler.py` y ejecutar `terraform apply`, Terraform debe detectar el cambio y actualizar la Lambda.

**PISTA EJERCICIO 14**

PISTA: Agrega `hashicorp/archive` a `required_providers` y usa `data.archive_file`.
---

### 15. Repositorio ECR

El equipo de ML necesita un repositorio para las imagenes Docker del modelo. Crea un repositorio ECR llamado `flocorp-modelo-predict` con `force_delete = true` (para poder destruirlo aunque tenga imagenes).

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 ecr describe-repositories
```

**PISTA EJERCICIO 15**

PISTA: `aws_ecr_repository` crea un repositorio de imagenes Docker.
---

### 16. Cluster ECS

El equipo de infraestructura necesita un cluster ECS para orquestar los contenedores del modelo. Crea un cluster ECS llamado `flocorp-cluster-ml` con capacidad Fargate.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 ecs list-clusters
```

**PISTA EJERCICIO 16**

PISTA: `aws_ecs_cluster` es simple de configurar, solo necesitas el nombre.
---

### 17. Task definition ECS

Define como se ejecutara el contenedor del modelo. Crea una task definition `flocorp-predict-task` con:
- Tipo: FARGATE
- CPU: 256, Memory: 512
- Contenedor: `nginx:latest` (por ahora, como placeholder), puerto 80
- `execution_role_arn` y `task_role_arn` apuntando al rol del ejercicio 8

**Nota:** En Floci, ECS no ejecuta contenedores reales, pero la configuracion de Terraform es identica a AWS real.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 ecs describe-task-definition --task-definition flocorp-predict-task
```

**PISTA EJERCICIO 17**

PISTA: Usa `jsonencode()` para `container_definitions` en `aws_ecs_task_definition`.
---

### 18. Variables de entrada

Hasta ahora todos los nombres estan hardcodeados. Tu jefa te pide parametrizar el nombre del bucket como variable para poder cambiarlo facilmente.

Declara una variable `bucket_name` con valor por defecto `flocorp-eventos-raw` y usala en el recurso S3.

**Verificacion:** Al ejecutar `terraform plan -var="bucket_name=flocorp-dev-events"`, el plan debe mostrar el nombre cambiado.

**PISTA EJERCICIO 18**

PISTA: Declara `variable` blocks y referencialos con `var.nombre`.
---

### 19. Outputs

El equipo de frontend necesita saber el ARN del bucket y el nombre de la funcion Lambda para configurar sus aplicaciones. Expone esos valores como outputs de Terraform.

**Verificacion:** Al ejecutar `terraform apply`, los outputs deben aparecer al final. Luego `terraform output bucket_arn` debe mostrar solo el ARN.

**PISTA EJERCICIO 19**

PISTA: Los `output` blocks exponen valores al final de `terraform apply`.
---

### 20. Locals

Tu jefa quiere un naming estandar: todos los recursos deben tener el prefijo `flocorp-` seguido del nombre funcional. Usa `locals` para definir el prefijo y construye los nombres de los recursos a partir de ahi.

Ejemplo: en lugar de `flocorp-eventos-raw`, usa `local.prefijo` + `"eventos-raw"`.

**Verificacion:** `terraform apply` debe crear recursos con nombres que empiecen con `flocorp-`.

**PISTA EJERCICIO 20**

PISTA: Un bloque `locals` permite definir valores reutilizables.
---

## Amarillo Nivel Intermedio (21 - 35)
*Objetivo: Combinar dos o tres recursos, agregar configuracion mas compleja y entender las relaciones entre servicios.*

---

### 21. Bucket policy (acceso publico de lectura)

El equipo de frontend necesita que los assets estaticos sean accesibles publicamente. Crea un segundo bucket `flocorp-assets-publicos` y agregale una bucket policy que permita `s3:GetObject` a cualquier principal (`"Principal": "*"`).

**Verificacion:** Sube un archivo y accede via URL:
```
echo "hola" > test.txt
aws --endpoint-url http://localhost:4566 s3 cp test.txt s3://flocorp-assets-publicos/
curl http://localhost:4566/flocorp-assets-publicos/test.txt
```

**PISTA EJERCICIO 21**

PISTA: Ademas del bucket necesitas `aws_s3_bucket_public_access_block` y `aws_s3_bucket_policy`.
---

### 22. Autoescalado de DynamoDB

El equipo de produccion anticipa picos de trafico. Configura autoescalado para la tabla `flocorp-sesiones` con:
- RCU: minimo 1, maximo 10, target 70%
- WCU: minimo 1, maximo 10, target 70%

Necesitas recursos de `aws_appautoscaling_target` y `aws_appautoscaling_policy`.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 application-autoscaling describe-scalable-targets --service-namespace dynamodb
```

**PISTA EJERCICIO 22**

PISTA: Necesitas `aws_appautoscaling_target` y `aws_appautoscaling_policy` para DynamoDB.
---

### 23. Politica IAM con condicion

Seguridad requiere que el acceso a S3 solo sea posible desde la IP de la oficina (192.168.1.0/24). Crea una nueva politica `flocorp-s3-restricted-policy` que permita `s3:PutObject` pero con una condicion `IpAddress` que restrinja la IP de origen.

**Verificacion:** La politica debe existir. Probar con IP diferente daria acceso denegado (en Floci la validacion de IP puede no funcionar, pero la configuracion de Terraform es correcta).

**PISTA EJERCICIO 23**

PISTA: Agrega un bloque `Condition` con `IpAddress` en el JSON de la politica.
---

### 24. Lambda con politicas IAM completas

Necesitas que la funcion Lambda `flocorp-processor` pueda:
1. Escribir en S3 (`s3:PutObject`)
2. Leer y escribir en DynamoDB (`dynamodb:PutItem`, `dynamodb:Query`)

Crea una politica IAM combinada que permita ambas cosas y adjuntala al rol de ejecucion de Lambda.

**PISTA EJERCICIO 24**

PISTA: Un solo JSON puede tener multiples `Statement` para combinar permisos.
---

### 25. DLQ para Lambda (Dead Letter Queue)

Si la funcion Lambda falla repetidamente, los eventos se pierden. Configura una cola SQS como Dead Letter Queue para `flocorp-processor`.

Pasos:
1. Crea un recurso `aws_sqs_queue` llamado `flocorp-lambda-dlq`
2. Agrega `dead_letter_config` a la funcion Lambda apuntando al ARN de la cola
3. Agrega una politica IAM para que Lambda pueda enviar mensajes a SQS

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 sqs list-queues
```

**PISTA EJERCICIO 25**

PISTA: Crea `aws_sqs_queue` y configurala como `dead_letter_config` en la Lambda.
---

### 26. Reserved concurrency

El equipo de plataforma quiere limitar el consumo de recursos de Lambda. Configura `reserved_concurrent_executions = 1` para que solo una instancia de `flocorp-processor` se ejecute a la vez.

Si invocas la Lambda mientras ya esta corriendo, las invocaciones adicionales seran throttled (error 429).

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 lambda get-function-concurrency --function-name flocorp-processor
```

**PISTA EJERCICIO 26**

PISTA: `reserved_concurrent_executions = 1` limita la ejecucion a una instancia.
---

### 27. API Gateway HTTP API (solo recurso)

El equipo de frontend necesita un endpoint HTTP para enviar eventos. Crea una API Gateway HTTP API llamada `flocorp-api-eventos`. Solo la API, sin rutas ni integraciones aun.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 apigatewayv2 get-apis
```

**PISTA EJERCICIO 27**

PISTA: Define `protocol_type = "HTTP"` en `aws_apigatewayv2_api`.
---

### 28. API Gateway + Lambda (ruta e integracion)

Conecta la API Gateway con la funcion Lambda. Crea una ruta `POST /event` y una integracion de tipo `AWS_PROXY` que invoque `flocorp-processor`.

**Verificacion:**
```
curl -X POST http://localhost:4566/event -H "Content-Type: application/json" -d '{"test": true}'
```

**PISTA EJERCICIO 28**

PISTA: Necesitas integracion, ruta y `aws_lambda_permission` para conectar API con Lambda.
---

### 29. Stages de API Gateway

La API del ejercicio anterior no tiene stage, por lo que el endpoint no esta desplegado. Crea un stage `prod` con `auto_deploy = true`.

**Verificacion:** El comando `curl` del ejercicio anterior debe funcionar (necesitas la URL del stage).

**PISTA EJERCICIO 29**

PISTA: `aws_apigatewayv2_stage` con `auto_deploy = true` despliega la API.
---

### 30. Variables de entorno en ECS task definition

El contenedor del modelo necesita saber a que bucket S3 leer y a que endpoint de DynamoDB conectarse. Agrega variables de entorno al task definition:
- `BUCKET_NAME = "flocorp-eventos-raw"`
- `MODE = "inference"`

**Verificacion:** `describe-task-definition` debe mostrar `environment` en la definicion del contenedor.

**PISTA EJERCICIO 30**

PISTA: Agrega `environment` al JSON de `container_definitions`.
---

### 31. ECR + ECS combinados

Ahora que tienes un repositorio ECR (`flocorp-modelo-predict`) y un task definition, actualiza el task definition para usar la imagen de ECR en lugar de `nginx:latest`.

La URL de la imagen sigue el patron: `aws_account_id.dkr.ecr.region.amazonaws.com/repo:tag`. En Floci, usa el URI del repositorio.

**PISTA EJERCICIO 31**

PISTA: Usa `repository_url` del recurso ECR como imagen en el task definition.
---

### 32. Default tags en el provider

Tu jefa esta harta de ver recursos sin etiquetas. Configura `default_tags` en el provider para que todos los recursos tengan automaticamente `Environment = "dev"` y `ManagedBy = "terraform"`.

**Verificacion:** Crea un recurso nuevo (ej: un SQS queue) y verifica que herede las tags del provider.

**PISTA EJERCICIO 32**

PISTA: Configura `default_tags` dentro del bloque `provider`.
---

### 33. Count: crear multiples buckets

El equipo de data lake necesita buckets separados por tipo de evento: `clickstream`, `transactions`, `errors`. Usa `count` para crear 3 buckets S3 a partir de una lista de nombres.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 s3 ls
```
Deben aparecer los 3 buckets.

**PISTA EJERCICIO 33**

PISTA: `count` con `count.index` y `length()` crea N instancias de un recurso.
---

### 34. for_each: crear tablas DynamoDB desde mapa

Usa `for_each` para crear tablas DynamoDB a partir de un mapa de configuracion. Cada entrada tendra: nombre de tabla y atributo de hash key.

```hcl
variable "tablas_config" {
  default = {
    sesiones    = { hash_key = "session_id" }
    usuarios    = { hash_key = "user_id" }
    metricas    = { hash_key = "metric_name" }
  }
}
```

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 dynamodb list-tables
```

**PISTA EJERCICIO 34**

PISTA: `for_each` itera sobre un mapa en lugar de una lista.
---

### 35. Data sources: obtener informacion existente

Usa el data source `aws_caller_identity` para obtener el Account ID actual y usalo para construir nombres de recursos o ARNs. Tambien usa `aws_region` para obtener la region configurada.

Expone ambos valores como outputs.

**Verificacion:**
```
terraform output
```
Debe mostrar el account ID y la region.

**PISTA EJERCICIO 35**

PISTA: Los data sources `aws_caller_identity` y `aws_region` consultan info del proveedor.
---

## Rojo Nivel Avanzado (36 - 50)
*Objetivo: Funciones avanzadas de Terraform y configuraciones mas complejas de servicios Floci. Empiezas a pensar como ingeniero de infraestructura.*

---

### 36. Lambda Layers

La funcion Lambda necesita la libreria `requests` (o cualquier dependencia externa) pero no quieres incluirla en cada zip. Crea un Lambda Layer `flocorp-python-deps` que contenga las dependencias y asocialo a la funcion.

**Pasos:**
1. Crea una carpeta `python/` con un `requirements.txt`
2. Instala las dependencias ahi: `pip install requests -t python/`
3. Empaqueta como zip: `Compress-Archive -Path python -DestinationPath layer.zip`
4. Crea `aws_lambda_layer_version`
5. Agrega `layers` en la funcion Lambda

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 lambda list-layers
```

**PISTA EJERCICIO 36**

PISTA: Crea `aws_lambda_layer_version` y asocialo con `layers` en la funcion.
---

### 37. Lambda en VPC

El equipo de seguridad requiere que la funcion Lambda se ejecute dentro de una VPC privada. Crea:
- `aws_vpc` con CIDR `10.0.0.0/16`
- `aws_subnet` privada `10.0.1.0/24`
- `aws_security_group` que permita trafico HTTPS saliente
- Asigna la Lambda a la VPC usando `vpc_config`

**Nota:** En Floci, las VPCs se emulan pero el comportamiento de red puede ser limitado.

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 lambda get-function-configuration --function-name flocorp-processor
```
Debe mostrar `VpcConfig` con las subnets y security group.

**PISTA EJERCICIO 37**

PISTA: Agrega `vpc_config` con `subnet_ids` y `security_group_ids` a la Lambda.
---

### 38. S3 Lifecycle: expiracion y transicion

El bucket de eventos crudos acumula datos sin control. Configura un lifecycle que:
1. Transicione objetos a `GLACIER` despues de 7 dias
2. Expire (elimine) objetos despues de 30 dias

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 s3api get-bucket-lifecycle-configuration --bucket flocorp-eventos-raw
```

**PISTA EJERCICIO 38**

PISTA: `aws_s3_bucket_lifecycle_configuration` define reglas de ciclo de vida.
---

### 39. S3 CORS

El frontend (corriendo en `http://localhost:5500`) necesita poder leer objetos del bucket `flocorp-assets-publicos` mediante AJAX. Configura CORS en el bucket permitiendo:
- Origen: `http://localhost:5500`
- Metodos: GET, HEAD
- Headers: `*`

**Verificacion:**
```
aws --endpoint-url http://localhost:4566 s3api get-bucket-cors --bucket flocorp-assets-publicos
```

**PISTA EJERCICIO 39**

PISTA: Usa `aws_s3_bucket_cors_configuration` para configurar CORS en S3.
---

### 40. API Gateway CORS

El frontend necesita enviar eventos a la API Gateway desde el navegador. Sin CORS, el navegador bloquea las peticiones. Configura CORS en la ruta `POST /event` de la API.

Crea un recurso `aws_apigatewayv2_integration` de tipo `MOCK` para la ruta `OPTIONS` y una ruta `OPTIONS /event` que responda con los headers CORS adecuados.

**Verificacion:** `curl -X OPTIONS http://localhost:4566/event` debe devolver headers CORS.

**PISTA EJERCICIO 40**

PISTA: Las rutas OPTIONS con integracion MOCK habilitan CORS en API Gateway.
---

### 41. API Gateway con autorizador JWT

El equipo de seguridad quiere que solo usuarios autenticados puedan enviar eventos. Configura un autorizador JWT en la API Gateway que valide tokens contra un issuer externo (ej: `https://cognito-idp.us-east-1.amazonaws.com/us-east-1_test`).

**Nota:** En Floci el autorizador no valida realmente, pero la configuracion de Terraform es la misma.

**PISTA EJERCICIO 41**

PISTA: `aws_apigatewayv2_authorizer` de tipo JWT valida tokens.
---

### 42. ECS Service con Application Load Balancer

Ahora expondras el contenedor del modelo detras de un ALB para que Lambda pueda invocarlo via HTTP. Crea:

1. `aws_lb` (Application Load Balancer) - publico
2. `aws_lb_target_group` - apuntando al puerto 80
3. `aws_lb_listener` - escuchando en puerto 80, forwarding al target group
4. `aws_ecs_service` - usando el task definition, asociado al target group
5. Security group para el ALB permitiendo HTTP desde cualquier lugar

**Nota:** En Floci, ECS y ALB son emulados, pero la configuracion es identica a AWS real.

**PISTA EJERCICIO 42**

PISTA: Necesitas ALB, target group, listener y ECS service con load balancer.
---

### 43. Lifecycle: prevent_destroy

El bucket `flocorp-eventos-raw` contiene datos criticos. Protegelo contra eliminacion accidental con `prevent_destroy = true`.

**Verificacion:** Ejecuta `terraform destroy`. Debe fallar con un error indicando que el recurso esta protegido.

**PISTA EJERCICIO 43**

PISTA: `lifecycle { prevent_destroy = true }` protege el recurso contra eliminacion.
---

### 44. Lifecycle: create_before_destroy

Cuando actualizas una funcion Lambda (cambias su nombre o runtime), Terraform la destruye y recrea, lo que causa downtime. Usa `create_before_destroy` para que la nueva funcion se cree antes de destruir la anterior.

**Nota:** Esto requiere que el nombre de la funcion pueda cambiar (o usar un alias). En este ejercicio, enfocate en el concepto.

**PISTA EJERCICIO 44**

PISTA: `lifecycle { create_before_destroy = true }` evita downtime en actualizaciones.
---

### 45. Modulo local reutilizable

Tu jefa te pide estandarizar la creacion de buckets S3. Crea un modulo local en `./modules/s3-bucket/` que:
- Reciba `bucket_name` y `tags` como variables
- Cree el bucket con versioning, tags, y devuelva `bucket_arn` y `bucket_id` como outputs
- Usa el modulo en `main.tf` para crear 2 buckets

**PISTA EJERCICIO 45**

PISTA: Un modulo es una carpeta con `main.tf`, `variables.tf` y `outputs.tf`.
---

### 46. Workspaces: entornos dev y prod

El equipo necesita separar recursos de desarrollo y produccion. Crea dos workspaces de Terraform: `dev` y `prod`. Usa `terraform.workspace` para agregar el nombre del workspace a los nombres de los recursos.

**Pasos:**
1. `terraform workspace new dev`
2. `terraform workspace new prod`
3. En el codigo, usa `terraform.workspace` para diferenciar entornos

**Verificacion:** En cada workspace, los recursos deben tener el nombre del workspace en su nombre.

**PISTA EJERCICIO 46**

PISTA: `terraform.workspace` devuelve el nombre del workspace para diferenciar entornos.
---

### 47. Templatefile para JSON dinamico

El equipo de IAM necesita generar policies JSON con diferentes ARNs segun el entorno. Usa `templatefile()` para generar una politica IAM a partir de una plantilla.

Crea `templates/s3-policy.tpl`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["s3:PutObject"],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${bucket_name}/*"
    }
  ]
}
```

En `main.tf`, usa `templatefile()` para pasar `bucket_name`.

**PISTA EJERCICIO 47**

PISTA: `templatefile()` lee una plantilla y reemplaza las variables.
---

### 48. Outputs sensibles

La funcion Lambda tiene una variable de entorno `API_KEY` que no debe mostrarse en los logs de Terraform. Declara un output que exponga el valor pero marcado como `sensitive = true`.

**Verificacion:** `terraform output api_key` debe mostrar `<sensitive>`.

**PISTA EJERCICIO 48**

PISTA: Marca el output como `sensitive = true` para ocultar el valor.
---

### 49. Provisioner remoto (con advertencia)

Los provisioners son el ultimo recurso en Terraform, pero existen. Crea un bucket S3 y usa un `null_resource` con `local-exec` para subir un archivo de bienvenida al bucket inmediatamente despues de crearlo.

**Advertencia:** En produccion, evita provisioners. Prefiere data sources y resources nativos.

**Verificacion:** El archivo debe aparecer en el bucket inmediatamente despues del apply.

**PISTA EJERCICIO 49**

PISTA: Usa `null_resource` con `provisioner "local-exec"` para comandos locales.
---

### 50. Terraform graph: visualizar dependencias

Has creado decenas de recursos. Llego el momento de visualizar como se relacionan. Ejecuta `terraform graph` y genera un grafico DOT.

**Pasos:**
1. `terraform graph > graph.dot`
2. Convierte a imagen (necesitas Graphviz instalado): `dot -Tpng graph.dot -o graph.png`
3. Abre `graph.png` y observa las dependencias

**Verificacion:** El grafico debe mostrar flechas entre recursos que dependen entre si (S3 bucket -> versioning, Lambda -> rol IAM, etc.).

**PISTA EJERCICIO 50**

PISTA: Ejecuta `terraform graph > graph.dot` y visualiza con Graphviz.
---

## Referencia rapida de comandos AWS CLI para Floci

| Servicio | Comando de verificacion |
|---|---|
| S3 | `aws --endpoint-url http://localhost:4566 s3 ls` |
| DynamoDB | `aws --endpoint-url http://localhost:4566 dynamodb list-tables` |
| IAM | `aws --endpoint-url http://localhost:4566 iam list-roles` |
| Lambda | `aws --endpoint-url http://localhost:4566 lambda list-functions` |
| API Gateway | `aws --endpoint-url http://localhost:4566 apigatewayv2 get-apis` |
| ECS | `aws --endpoint-url http://localhost:4566 ecs list-clusters` |
| ECR | `aws --endpoint-url http://localhost:4566 ecr describe-repositories` |
| SQS | `aws --endpoint-url http://localhost:4566 sqs list-queues` |
| STS | `aws --endpoint-url http://localhost:4566 sts get-caller-identity` |

## Notas importantes

- Cada ejercicio asume que entiendes los anteriores. No los saltes.
- Usa `terraform destroy` al final de cada ejercicio para limpiar, a menos que el ejercicio especifico requiera mantener recursos.
- Si un `terraform apply` falla, lee el error. Terraform es explicito: dice exactamente que recurso fallo y por que.
- Floci no implementa todos los servicios al 100%. Si un comando de verificacion falla, confirma primero que Floci soporta ese recurso.
- No uses `prevent_destroy` a menos que el ejercicio lo pida. Te bloqueara el `terraform destroy`.
- Los nombres de recursos en Floci deben ser unicos globalmente (como en AWS real). Usa sufijos como tu nombre o iniciales si hay conflictos.


