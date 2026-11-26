# Changelog

All notable changes to this project will be documented in this file.

## [3.0.1] - 2026-11-26
- Rewrite input and output descriptions as single-line prose so they render on the Terraform Registry

## [3.0.0] - 2026-11-25
- Require OpenTofu or Terraform 1.11.0 and validate with both in CI

BREAKING: required_version is raised from >= 1.10.7 to >= 1.11.0.
Upgrade note: consumers need OpenTofu or Terraform >= 1.11.0.

Pin opentofu 1.13.10 and terraform 1.17.2 in mise.toml, add the
validate:terraform job, align the examples on the root provider
constraint (~> 2.89), and force the tofu binary in the pre-commit
Terraform hooks.
- Reject owner contact legal forms and .fr modes the provider does not accept

Provider 2.93.0 validates legal_form (individual, corporate, association, other) and extension_fr.mode; the module now rejects other values at plan on every provider version, and the tests no longer use the invalid "company".
- Key DNS records by map, enable registration from the registration object and replace the project lookup with project_id

BREAKING: v2.0.0; provider ~> 2.89.

- organization_id and project_name are removed: pass project_id.
- register_domain is removed: a non-null registration enables it.
- registration administrative_contact_id and technical_contact_id are
  removed (the provider never accepted them).
- records is a map keyed by a caller-chosen key; add one root moved block
  per record from ["<type>_<name>_<index>"] to the new key (or state mv).
- record data is required, name defaults to "", geo_ip is the list of
  matches, view subnets must be CIDR blocks.
- Outputs project_id, record_ids and record_fqdns are removed (records
  carries id and fqdn).
- registration.owner_contact.extension_fr gains individual_info,
  association_info, duns_info and trademark_info.

See "Upgrading from v1 to v2" in the README.
- Add registration auto_renew and dnssec options and the DS record output

Provider constraint unchanged (~> 2.86); tested with scaleway provider 2.89.0. registration_status and registration_expired_at are not added: the provider schema does not expose them.
- Fix project resolution, registration validation and ignored contact IDs

- Resolve the project to null instead of failing when nothing resolves it.
- Reject register_domain without registration with a clear validation message.
- Reject single-character project_name values that are not a lowercase letter.
- Deprecate registration.administrative_contact_id and technical_contact_id (the provider cannot set them) and warn when they are set.
- Document the <type>_<name>_<index> record key and call weighted records "Weighted DNS routing".
- Add unit tests.
No upgrade action needed.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- Key the pre-commit cache on mise.toml and .pre-commit-config.yaml

The cache was keyed on the branch, so a branch kept tools installed by the previous mise, which the new one no longer puts on PATH (tofu not found). Keying it on the files that define the toolchain, as in scaleway-compute and scaleway-storage, starts a fresh cache whenever the toolchain changes and shares it across branches and tags.
- Install mise 2026.10.17 in CI to avoid the GitHub API rate limit

The pre-commit job installed an old mise that resolves every tool through api.github.com without a token, and failed with 403 rate-limit errors on the shared office runner whenever its cache was cold (new refs such as merge requests and tags). mise 2026.9.14 and later resolve releases through mise-versions.jdx.dev.
- Run validate:specs in merge request pipelines

A job without rules: only runs in branch and tag pipelines, so the merge request pipeline did not validate openspec/. rules: when: always matches the other validate jobs.
- Adopt OpenSpec and publish the baseline specs

Planning adopts OpenSpec, aligned with the other leminnov Terraform
modules: the engineering standards come from the quality, repository and
terraform OpenSpec stores. openspec/config.yaml follows the terraform-module profile
(stores pinned at quality v1.2.6, repository v4.1.0, terraform v1.2.6) and
AGENTS.md, imported by CLAUDE.md, routes to them. openspec/specs/ holds the
baseline specification of the module as released, produced by the archived
adopt-openspec change. The openspec-* skills are installed for Claude Code
and OpenCode, openspec 1.14.3 and node are pinned in mise.toml with the
spec-validate and spec-setup tasks, and the validate:specs CI job runs
openspec validate --all --strict. The module contract is unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- chore(deps): upgrade scaleway provider to ~> 2.86

- Bump the scaleway provider constraint to ~> 2.86 (module and examples).
- Pass owner contact vat/company identification codes through as-is:
  they are optional since provider 2.77, the "" fallback is not needed.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- Requires `data` attribute for all DNS records

Ensures all DNS records have a `data` attribute, which is now required as a default fallback IP address.

Updates the example configurations to reflect this requirement, providing default fallback IP addresses for various DNS record types.

Also, moves example outputs to separate files for better organization.

Fixes domain registration logic to handle empty values.
- Allows domain registration via the module

Updates the module to support domain registration directly.

This change allows users to register a domain via this module by setting `register_domain = true`. A precondition has been added to ensure that the 'registration' variable is provided when `register_domain` is true.
- Adds domain registration functionality

Extends the module to support domain registration with Scaleway, allowing users to register new domains directly through Terraform.

Includes configurable contact details and registration periods.
- wip Migrates to Scaleway DNS Terraform Module

Refactors the terraform module to manage Scaleway DNS zones and records.

Improves functionality with dynamic DNS features: geo IP routing, weighted load balancing, view-based routing, and HTTP health checks.

Adds comprehensive input validation and type safety.
Includes complete and minimal examples for easier adoption.
## [0.0.1] - 2025-04-28
- Create DNS record in scaleway
- Adds .gitignore and pre-commit configuration

Adds a comprehensive .gitignore file to prevent committing sensitive data and build artifacts.

Also introduces a pre-commit configuration to enforce code quality and consistency, including YAML checking, whitespace trimming, and OpenTofu formatting.
- Initial commit

