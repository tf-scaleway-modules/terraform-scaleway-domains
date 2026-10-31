mock_provider "scaleway" {}

override_data {
  target = data.scaleway_account_project.this
  values = {
    id = "11111111-1111-1111-1111-111111111111"
  }
}

variables {
  domain = "example.com"
}

run "no_project_resolved" {
  command = plan

  variables {
    create_zone = true
    records = [
      { name = "", type = "A", data = "93.184.216.34" },
      { name = "www", type = "CNAME", data = "example.com." },
    ]
  }

  assert {
    condition     = output.project_id == null
    error_message = "project_id must be null when nothing resolves a project"
  }

  assert {
    condition     = length(scaleway_domain_zone.this) == 1 && length(scaleway_domain_registration.this) == 0
    error_message = "Only the zone must be planned"
  }

  assert {
    condition     = toset(keys(scaleway_domain_record.this)) == toset(["A_@_0", "CNAME_www_1"])
    error_message = "Record keys must be <type>_<name>_<index>"
  }
}

run "project_id_given" {
  command = plan

  variables {
    project_id = "22222222-2222-2222-2222-222222222222"
  }

  assert {
    condition     = output.project_id == "22222222-2222-2222-2222-222222222222"
    error_message = "project_id output must equal the input"
  }

  assert {
    condition     = length(data.scaleway_account_project.this) == 0
    error_message = "No project lookup expected when project_id is set"
  }
}

run "project_lookup_by_name" {
  command = plan

  variables {
    organization_id = "33333333-3333-3333-3333-333333333333"
    project_name    = "my-project"
  }

  assert {
    condition     = output.project_id == "11111111-1111-1111-1111-111111111111"
    error_message = "project_id must come from the lookup"
  }
}

run "project_name_without_organization" {
  command = plan

  variables {
    project_name = "my-project"
  }

  assert {
    condition     = length(data.scaleway_account_project.this) == 0
    error_message = "No lookup expected without organization_id"
  }
}

run "project_name_single_letter_accepted" {
  command = plan

  variables {
    project_name = "a"
  }
}

run "project_name_single_uppercase_rejected" {
  command = plan

  variables {
    project_name = "A"
  }

  expect_failures = [var.project_name]
}

run "project_name_single_digit_rejected" {
  command = plan

  variables {
    project_name = "1"
  }

  expect_failures = [var.project_name]
}

run "project_name_invalid_rejected" {
  command = plan

  variables {
    project_name = "My_Project"
  }

  expect_failures = [var.project_name]
}

run "register_domain_without_registration_rejected" {
  command = plan

  variables {
    register_domain = true
  }

  expect_failures = [var.register_domain]
}

run "registration_planned" {
  command = plan

  variables {
    register_domain = true
    registration = {
      owner_contact_id = "contact-id"
    }
  }

  assert {
    condition     = length(scaleway_domain_registration.this) == 1
    error_message = "One registration expected"
  }

  assert {
    condition     = scaleway_domain_registration.this[0].duration_in_years == 1
    error_message = "Duration must default to one year"
  }
}

run "registration_contact_ids_ignored_warns" {
  command = plan

  variables {
    register_domain = true
    registration = {
      owner_contact_id          = "contact-id"
      administrative_contact_id = "admin-id"
    }
  }

  expect_failures = [check.registration_contact_ids_ignored]
}

run "registration_options_default_false" {
  command = plan

  variables {
    register_domain = true
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
    register_domain = true
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
    error_message = "registration_ds_record must be null when register_domain is false"
  }
}

run "registration_ds_record_set_when_enabled" {
  command = apply

  variables {
    register_domain = true
    registration = {
      owner_contact_id = "contact-id"
    }
  }

  assert {
    condition     = output.registration_ds_record != null
    error_message = "registration_ds_record must carry the registration value when register_domain is true"
  }
}
