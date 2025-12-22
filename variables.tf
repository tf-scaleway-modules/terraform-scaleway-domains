variable "dns_zone" {
  description = "The domain zone"
  type        = string
}

variable "records" {
  description = "List of DNS records to create"
  type = list(object({
    record_name = string
    record_type = string
    record_data = string
    record_ttl  = optional(number, 3600)
  }))
}
