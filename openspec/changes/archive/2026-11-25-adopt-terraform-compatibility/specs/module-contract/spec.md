## MODIFIED Requirements

### Requirement: Supported tooling and providers
The module SHALL declare a single `required_version = ">= 1.11.0"`, read by both OpenTofu and Terraform, and SHALL pin `scaleway/scaleway ~> 2.89` in `versions.tf`. The examples under `examples/` SHALL declare the same `required_version` and the same scaleway constraint as the root. It SHALL work on OpenTofu and Terraform. It SHALL NOT contain `provider {}` or `backend {}` blocks.

#### Scenario: Provider resolution
- **WHEN** the module is initialised
- **THEN** the scaleway provider resolves to a 2.x release at or above 2.89 and no provider or backend configuration comes from the module

#### Scenario: Older toolchain
- **WHEN** the module is used with a Terraform or OpenTofu release older than 1.11.0
- **THEN** initialisation fails on the `required_version` constraint

#### Scenario: Both tools validate
- **WHEN** `tofu validate` and `terraform validate` run in the root and in each example
- **THEN** both succeed
