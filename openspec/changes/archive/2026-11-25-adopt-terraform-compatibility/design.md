## Context

Standards applied: `terraform-providers` (version constraints), `terraform-module-structure` (tooling), `terraform-repo-mise`, `terraform-repo-gitlab-ci`, `terraform-repo-precommit`, `terraform-versioning`; quality: simplicity (smallest change, no new option or abstraction).

## Decisions

- **One constraint.** `required_version = ">= 1.11.0"` in the root and every example; no `.tofu` file, no `language {}` block. Alternative (split OpenTofu/Terraform floors) rejected by `terraform-providers`.
- **Example provider constraint** `~> 2.89` equal to the root (was `>= 2.86`), so an example never resolves a provider the module is not tested with.
- **Exact pins** `opentofu = '1.13.10'`, `terraform = '1.17.2'` in `mise.toml`; CI image tags copy these (`terraform-repo-mise`, `terraform-repo-gitlab-ci`). `mise install` fetches both.
- **`validate:terraform`** copies the shape from the brief: `terraform init -backend=false`, `terraform validate`, then a loop over `examples/*/`. No `fmt` (owned by `validate:opentofu`).
- **Pre-commit** adds `--hook-config=--tf-path=tofu` to the three existing Terraform hooks so installing `terraform` does not change which binary runs. Every antonbabenko Terraform hook lacking the arg gets it. The missing `terraform_validate`, `terraform_checkov`, `terraform_trivy` hooks and the hook `rev` (`v1.103.0` vs `v1.109.1` in the store) are out of scope of this change.
- **GitHub mirror**: `tofu_version` in `ci.yml` and `release.yml` becomes the `mise.toml` pin `1.13.10` (`Hooks and CI use the pinned tools`). No Terraform step exists there and none is added.

## Risks / migration

- No resource, argument, address or provider version changes: no `moved` block, no state migration, and the second plan stays empty.
- Consumers on 1.10.x break at `init` (intended, major release).
- If `terraform validate` rejects a construct accepted by OpenTofu, stop and report; today none is used.
- `.terraform.lock.hcl` must not gain `registry.terraform.io` entries: the Terraform check runs in a scratch copy.
