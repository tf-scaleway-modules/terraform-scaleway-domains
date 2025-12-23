resource "scaleway_domain_registration" "this" {

}

resource "scaleway_domain_zone" "this" {
}
resource "scaleway_domain_record" "this" {
  for_each = {
    for record in var.records : "${record.record_type}.${record.record_name}" => record
  }

  dns_zone = var.dns_zone

  name = each.value.record_name
  type = each.value.record_type
  data = each.value.record_data
  ttl  = each.value.record_ttl
}
