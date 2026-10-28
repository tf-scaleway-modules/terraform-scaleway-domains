## 1. Registration options and outputs

- [x] 1.1 `variables.tf`: add `auto_renew = optional(bool, false)` and `dnssec = optional(bool, false)` to `registration`, with inline comments and a `registration` description covering billing, the DNSSEC/Scaleway-DNS precondition and `registration_ds_record`. Verify: `tofu validate` passes and `registration = { owner_contact_id = "x" }` still plans
- [x] 1.2 `main.tf`: pass `auto_renew` and `dnssec` to `scaleway_domain_registration.this`. Verify: `tofu test` asserts the planned values (task 2.1)
- [x] 1.3 `outputs.tf`: add `registration_ds_record` after `registration_id`, `null` when `register_domain = false`, with a description, not sensitive, and no `epp_code`. Verify: `tofu test` output assertions (task 2.1)

## 2. Tests and examples

- [x] 2.1 `tests/main.tftest.hcl` (`mock_provider "scaleway"`): run `registration_options_default_false` (both false when omitted), run `registration_options_enabled` (both true when set), run `registration_ds_record_null_when_disabled` (`registration_ds_record` null) and `registration_ds_record_set_when_enabled`. Verify: `tofu test` passes
- [x] 2.2 `examples/registration/main.tf` and `outputs.tf`: set `auto_renew`/`dnssec` with explanatory comments, output `registration_ds_record`. Verify: `tofu init -backend=false && tofu validate` in the example
- [x] 2.3 `examples/complete`: no registration there; re-run `tofu init -backend=false && tofu validate` against provider 2.89.0 and keep `versions.tf` at `>= 2.86`. Verify: validate passes (examples/minimal likewise)

## 3. Docs and release

- [x] 3.1 `README.md` outside the terraform-docs block: document `auto_renew`, `dnssec` and the new output in the registration section; add the compatibility note "tested with scaleway provider 2.89.0 (constraint `~> 2.86`)". Verify: README renders the options and the pinned constraint still reads `~> 2.86`
- [x] 3.2 Run `tofu fmt -recursive`, `tofu init -backend=false && tofu validate`, `tflint --recursive`, `tofu test`. Verify: all exit 0
- [x] 3.3 Pitfall: a local `.terraform.lock.hcl` makes terraform-docs write the locked provider version (2.89.0) instead of the constraint (`~> 2.86`) in the README; move the lock file aside before `pre-commit run -a` and before pushing, then restore if needed. Run `pre-commit run -a`. Verify: exits 0 and the README provider table shows `~> 2.86`
- [x] 3.4 Run `openspec validate --all --strict`. Verify: passes
- [x] 3.5 Commit subject reads as the CHANGELOG line, e.g. `Add registration auto_renew and dnssec options and the DS record output`. Minor release, nothing breaking, so no upgrade note in the body beyond "provider constraint unchanged (~> 2.86)"; do not edit CHANGELOG.md. Verify: `git log -1 --format=%s` shows the subject

## Workflow follow-up

- Archive the change after merge; `mise run changelog` regenerates CHANGELOG.md at release.
