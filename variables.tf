variable "datadog_external_id" {
  type = string
  description = "Datadog Role Delegation external ID generated when adding AWS integration."
}

variable "datadog_k8s_controller_api_key" {
  type = string
  description = "Datadog API key for kubernetes controller"
}
