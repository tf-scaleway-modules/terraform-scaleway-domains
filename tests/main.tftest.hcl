mock_provider "scaleway" {}

variables {
  domain = "example.com"
}

run "defaults_plan_nothing" {
  command = plan

  assert {
    condition     = length(scaleway_domain_zone.this) == 0 && length(scaleway_domain_registration.this) == 0 && length(scaleway_domain_record.this) == 0
    error_message = "Nothing must be planned with only a domain"
  }

  assert {
    condition     = output.dns_zone == "example.com" && output.registration_id == null && output.zone_id == null && length(output.records) == 0
    error_message = "Outputs must be null or empty when every feature is disabled, dns_zone set from the inputs"
  }
}

run "project_id_applied" {
  command = plan

  variables {
    create_zone = true
    project_id  = "22222222-2222-2222-2222-222222222222"
  }

  assert {
    condition     = scaleway_domain_zone.this[0].project_id == "22222222-2222-2222-2222-222222222222"
    error_message = "The zone must carry project_id"
  }
}

run "project_id_null_accepted" {
  command = plan

  variables {
    create_zone = true
  }

  assert {
    condition     = length(scaleway_domain_zone.this) == 1
    error_message = "The zone must be planned without project_id"
  }
}

run "project_id_invalid_rejected" {
  command = plan

  variables {
    project_id = "my-project"
  }

  expect_failures = [var.project_id]
}

run "registration_planned" {
  command = plan

  variables {
    registration = {
      owner_contact_id = "contact-id"
    }
  }

  assert {
    condition     = length(scaleway_domain_registration.this) == 1
    error_message = "One registration expected when registration is set"
  }

  assert {
    condition     = scaleway_domain_registration.this[0].duration_in_years == 1
    error_message = "Duration must default to one year"
  }
}

run "registration_absent_when_null" {
  command = plan

  variables {
    registration = null
  }

  assert {
    condition     = length(scaleway_domain_registration.this) == 0 && output.registration_id == null
    error_message = "No registration expected when registration is null"
  }
}

run "registration_project_id_applied" {
  command = plan

  variables {
    project_id = "22222222-2222-2222-2222-222222222222"
    registration = {
      owner_contact_id = "contact-id"
    }
  }

  assert {
    condition     = scaleway_domain_registration.this[0].project_id == "22222222-2222-2222-2222-222222222222"
    error_message = "The registration must carry project_id"
  }
}

run "registration_without_owner_rejected" {
  command = plan

  variables {
    registration = {}
  }

  expect_failures = [var.registration]
}

run "registration_options_default_false" {
  command = plan

  variables {
    registration = {
      owner_contact_id = "contact-id"
    }
  }

  assert {
    condition     = scaleway_domain_registration.this[0].auto_renew == false && scaleway_domain_registration.this[0].dnssec == false
    error_message = "auto_renew and dnssec must default to false"
  }
}

run "registration_options_enabled" {
  command = plan

  variables {
    registration = {
      owner_contact_id = "contact-id"
      auto_renew       = true
      dnssec           = true
    }
  }

  assert {
    condition     = scaleway_domain_registration.this[0].auto_renew == true && scaleway_domain_registration.this[0].dnssec == true
    error_message = "auto_renew and dnssec must be forwarded when set"
  }
}

run "registration_ds_record_null_when_disabled" {
  command = plan

  assert {
    condition     = output.registration_ds_record == null
    error_message = "registration_ds_record must be null when registration is null"
  }
}

run "registration_ds_record_set_when_enabled" {
  command = apply

  variables {
    registration = {
      owner_contact_id = "contact-id"
    }
  }

  assert {
    condition     = output.registration_ds_record != null
    error_message = "registration_ds_record must carry the registration value when registration is set"
  }
}

run "extension_fr_duns_info_rendered" {
  command = plan

  variables {
    registration = {
      owner_contact = {
        legal_form   = "corporate"
        firstname    = "A"
        lastname     = "B"
        email        = "a.b@example.com"
        phone_number = "+33111111111"

        address_line_1 = "1 Rue X"
        zip            = "75001"
        city           = "Paris"
        country        = "FR"

        extension_fr = {
          mode      = "duns"
          duns_info = { duns_id = "123456789" }
        }
      }
    }
  }

  assert {
    condition = (
      length(scaleway_domain_registration.this[0].owner_contact[0].extension_fr) == 1 &&
      length(scaleway_domain_registration.this[0].owner_contact[0].extension_fr[0].duns_info) == 1 &&
      scaleway_domain_registration.this[0].owner_contact[0].extension_fr[0].duns_info[0].duns_id == "123456789" &&
      length(scaleway_domain_registration.this[0].owner_contact[0].extension_fr[0].association_info) == 0 &&
      length(scaleway_domain_registration.this[0].owner_contact[0].extension_fr[0].individual_info) == 0 &&
      length(scaleway_domain_registration.this[0].owner_contact[0].extension_fr[0].trademark_info) == 0
    )
    error_message = "extension_fr must carry exactly the duns_info block"
  }
}

run "extension_fr_mode_only_has_no_nested_block" {
  command = plan

  variables {
    registration = {
      owner_contact = {
        legal_form   = "individual"
        firstname    = "A"
        lastname     = "B"
        email        = "a.b@example.com"
        phone_number = "+33111111111"

        address_line_1 = "1 Rue X"
        zip            = "75001"
        city           = "Paris"
        country        = "FR"

        extension_fr = { mode = "individual" }
      }
    }
  }

  assert {
    condition = (
      length(scaleway_domain_registration.this[0].owner_contact[0].extension_fr) == 1 &&
      length(scaleway_domain_registration.this[0].owner_contact[0].extension_fr[0].duns_info) == 0 &&
      length(scaleway_domain_registration.this[0].owner_contact[0].extension_fr[0].association_info) == 0 &&
      length(scaleway_domain_registration.this[0].owner_contact[0].extension_fr[0].individual_info) == 0 &&
      length(scaleway_domain_registration.this[0].owner_contact[0].extension_fr[0].trademark_info) == 0
    )
    error_message = "extension_fr with only a mode must carry no nested block"
  }
}

# Provider >= 2.93.0 rejects these values; the module rejects them on every version.
run "legal_form_rejects_unknown_value" {
  command = plan

  variables {
    registration = {
      owner_contact = {
        legal_form   = "company"
        firstname    = "A"
        lastname     = "B"
        email        = "a.b@example.com"
        phone_number = "+33111111111"

        address_line_1 = "1 Rue X"
        zip            = "75001"
        city           = "Paris"
        country        = "FR"
      }
    }
  }

  expect_failures = [var.registration]
}

run "extension_fr_mode_rejects_unknown_value" {
  command = plan

  variables {
    registration = {
      owner_contact = {
        legal_form   = "corporate"
        firstname    = "A"
        lastname     = "B"
        email        = "a.b@example.com"
        phone_number = "+33111111111"

        address_line_1 = "1 Rue X"
        zip            = "75001"
        city           = "Paris"
        country        = "FR"

        extension_fr = { mode = "company" }
      }
    }
  }

  expect_failures = [var.registration]
}

run "records_keys_are_addresses" {
  command = plan

  variables {
    create_zone = true
    records = {
      root = { type = "A", data = "93.184.216.34" }
      www  = { name = "www", type = "CNAME", data = "example.com." }
    }
  }

  assert {
    condition     = toset(keys(scaleway_domain_record.this)) == toset(["root", "www"])
    error_message = "Record keys must be the keys of the records map"
  }

  assert {
    condition     = scaleway_domain_record.this["root"].name == "" && scaleway_domain_record.this["root"].ttl == 3600
    error_message = "name must default to the zone root and ttl to 3600"
  }
}

run "records_order_independent" {
  command = plan

  variables {
    records = {
      www  = { name = "www", type = "CNAME", data = "example.com." }
      root = { type = "A", data = "93.184.216.34" }
    }
  }

  assert {
    condition     = toset(keys(scaleway_domain_record.this)) == toset(["root", "www"])
    error_message = "Keys must not depend on the order of the entries"
  }
}

run "records_custom_ttl_and_priority" {
  command = plan

  variables {
    records = {
      mx = { type = "MX", data = "mail.example.com.", priority = 10, ttl = 300 }
    }
  }

  assert {
    condition     = scaleway_domain_record.this["mx"].ttl == 300 && scaleway_domain_record.this["mx"].priority == 10
    error_message = "ttl and priority must be forwarded"
  }
}

run "records_invalid_type_rejected" {
  command = plan

  variables {
    records = {
      bad = { type = "SOA", data = "x" }
    }
  }

  expect_failures = [var.records]
}

run "records_ttl_out_of_range_rejected" {
  command = plan

  variables {
    records = {
      low = { type = "A", data = "10.0.0.1", ttl = 30 }
    }
  }

  expect_failures = [var.records]
}

run "records_mx_without_priority_rejected" {
  command = plan

  variables {
    records = {
      mx = { type = "MX", data = "mail.example.com." }
    }
  }

  expect_failures = [var.records]
}

run "records_http_service_strategy_rejected" {
  command = plan

  variables {
    records = {
      api = {
        type = "A"
        data = "10.0.0.1"
        http_service = {
          ips          = ["10.0.0.1"]
          must_contain = "ok"
          url          = "http://example.com/health"
          strategy     = "first"
        }
      }
    }
  }

  expect_failures = [var.records]
}

run "records_geo_ip_list_renders_matches" {
  command = plan

  variables {
    records = {
      cdn = {
        name = "cdn"
        type = "A"
        data = "10.0.0.1"
        geo_ip = [
          { data = "10.0.1.1", continents = ["EU"] },
          { data = "10.0.3.1", countries = ["FR"] },
        ]
      }
    }
  }

  assert {
    condition     = length(scaleway_domain_record.this["cdn"].geo_ip) == 1 && length(scaleway_domain_record.this["cdn"].geo_ip[0].matches) == 2
    error_message = "One geo_ip block with one matches block per element expected"
  }
}

run "records_view_renders_blocks" {
  command = plan

  variables {
    records = {
      db = {
        name = "db"
        type = "A"
        data = "203.0.113.10"
        view = [
          { subnet = "10.0.0.0/8", data = "10.100.0.10" },
          { subnet = "192.168.0.0/16", data = "10.100.0.11" },
        ]
      }
    }
  }

  assert {
    condition     = length(scaleway_domain_record.this["db"].view) == 2
    error_message = "One view block per entry expected"
  }
}

run "records_view_subnet_not_cidr_rejected" {
  command = plan

  variables {
    records = {
      db = {
        type = "A"
        data = "203.0.113.10"
        view = [{ subnet = "10.0.0.0", data = "10.100.0.10" }]
      }
    }
  }

  expect_failures = [var.records]
}

run "records_output_keys" {
  command = apply

  variables {
    create_zone = true
    records = {
      root = { type = "A", data = "93.184.216.34" }
      www  = { name = "www", type = "CNAME", data = "example.com." }
    }
  }

  assert {
    condition     = toset(keys(output.records)) == toset(["root", "www"]) && output.records["root"].id != null && output.records["www"].fqdn != null
    error_message = "records must be keyed like the input and carry id and fqdn"
  }
}
