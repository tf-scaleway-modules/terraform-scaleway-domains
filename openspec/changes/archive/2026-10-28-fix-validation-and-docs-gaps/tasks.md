## 1. Code fixes

- [x] 1.1 `locals.tf`: resolve `project_id` with a conditional that yields `null` when nothing resolves; fix the record key comment
- [x] 1.2 `variables.tf`: tighten the `project_name` regex; add the `register_domain` validation; mark `administrative_contact_id` and `technical_contact_id` deprecated and ignored; document the record key in `records`
- [x] 1.3 `main.tf`: remove the unreachable precondition; add `check "registration_contact_ids_ignored"`; rename the weighted wording

## 2. Tests and docs

- [x] 2.1 Create `tests/main.tftest.hcl` with `mock_provider "scaleway"`: happy path, no project resolved, project lookup by name, `register_domain` without `registration`, single-character `project_name` (rejected and accepted), ignored contact IDs check, record keys
- [x] 2.2 README: wording "Weighted DNS routing" and record key note; `examples/complete/main.tf` wording

## 3. Verification

- [x] 3.1 `tofu fmt -recursive`, `tofu validate`, `tofu test`
- [x] 3.2 `tflint --recursive`, `pre-commit run -a` (terraform-docs README regeneration)
- [x] 3.3 `openspec validate --all --strict`, archive the change, validate again
- [x] 3.4 Commit subject reads as a CHANGELOG line (patch release); no CHANGELOG edit
