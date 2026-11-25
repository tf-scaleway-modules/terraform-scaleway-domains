## 1. Configuration

- [x] 1.1 `openspec/config.yaml`: `terraform` store `ref: v2.1.0`; context "required_version >= 1.11.0"
- [x] 1.2 `versions.tf`: `required_version = ">= 1.11.0"` and fix the trailing comment ("OpenTofu or Terraform 1.11.0+")
- [x] 1.3 `examples/{minimal,complete,registration}/versions.tf`: `required_version = ">= 1.11.0"`, scaleway `version = "~> 2.89"`
- [x] 1.4 `mise.toml`: `opentofu = '1.13.10'`, add `terraform = '1.17.2'`; run `mise install`
- [x] 1.5 `.gitlab/release.yml`: `validate:opentofu` image `ghcr.io/opentofu/opentofu:1.13.10`; add `validate:terraform` (`hashicorp/terraform:1.17.2`) after it; add it to `create:release` `needs:` after `validate:opentofu`
- [x] 1.7 `.github/workflows/{ci,release}.yml`: `tofu_version: "1.13.10"`; no new job
- [x] 1.6 `.pre-commit-config.yaml`: `args: [--hook-config=--tf-path=tofu]` on `terraform_fmt`, `terraform_docs`, `terraform_tflint`

## 2. Docs and spec

- [x] 2.1 `README.md` (outside `BEGIN_TF_DOCS`/`END_TF_DOCS`): prerequisite "OpenTofu >= 1.11.0 or Terraform >= 1.11.0" and badge `%3E%3D1.11`
- [x] 2.2 `AGENTS.md`: name OpenTofu >= 1.11.0 and Terraform >= 1.11.0; add `terraform init -backend=false && terraform validate` to the Commands format/validate line
- [x] 2.3 Grep for stale `1.10.0`, `1.10.7`, `1.11.6`, `v1.2.6` outside `CHANGELOG.md` and archived changes; fix prose
- [x] 2.4 Unit tests and `examples/complete`: no behaviour change, nothing to add (state why in the summary)

## 3. Verification

- [x] 3.1 `mise exec -- tofu fmt -recursive -check`
- [x] 3.2 `tofu init -backend=false -upgrade && tofu validate` in root and each `examples/*`
- [x] 3.3 `tflint --init && tflint --recursive`
- [x] 3.4 `tofu test`
- [x] 3.5 Terraform check in a scratch copy (rsync excluding `.terraform`, lock file, `.git`, `mise*.toml`; `terraform` from `mise which terraform`): init and validate in root and each example
- [x] 3.6 `mise exec -- openspec validate --all --strict`
- [x] 3.7 `pre-commit run -a` with every `.terraform.lock.hcl` moved outside the repo, restored afterwards

## 4. Commit

- [x] 4.1 One signed commit, subject such as "Require OpenTofu or Terraform 1.11.0 and validate with both in CI"; body: `BREAKING:` consumers need OpenTofu or Terraform >= 1.11.0. Do not edit `CHANGELOG.md`.
