variable "bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
  default     = "flocorp_eventos_raw"
}

variable "table_name" {
  type    = string
  default = "flocorp_sesiones"
}