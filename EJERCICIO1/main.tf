terraform { # abre seccion para declarar que herramientas y traductores externos se usaran
  required_providers {
    # colocamos un alias a la herramienta en este caso aws
    aws = {
      source  = "hashicorp/aws", # origen oficial de internet de donde tf bajara el plugin
      version = "~> 5.0"         # fijamos la version para evitar que cambios rompan codigo
    }
  }
}

provider "aws" {
  region = "us-east-1" # region obligatorio que solicita el plugin

  access_key = "test" # el plugin si pide acceso aunque floci no, aun asi preferible como variable de entorno
  secret_key = "test" # ambas son credenciales que te da aws para tu usuario

  skip_credentials_validation = true # apagamos la validacion de laves en internet ya que floci trabaja en local
  skip_requesting_account_id  = true # evita que terraform busque un id en cuenta real de aws
  skip_metadata_api_check     = true # evita verificar que estas corriendo en servidores de aws

  s3_use_path_style = true #configura las rutas de s3 como carpetas locales localhost/buckets

  endpoints {
    sts = "http://localhost:4566" #desvia la validacion de identidad al endpoint local
    s3  = "http://localhost:4566" # desvia el almacenamiento de archivos a local
    ec2 = "http://localhost:4566" # desvia creacion de servidores virtuales a local
  }
}
