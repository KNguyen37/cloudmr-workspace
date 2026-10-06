# CloudMR Workspace — Agentic MRI Synthesis (NYU Langone)

Virtual monorepo: five independent git repos from github.com/KNguyen37 (private copies of the cloudmrhub originals, fully detached) live under `repos/`.
Each is its own git repo with its own branches, history, and CI. This root folder is NOT
part of any of them. Always `cd` into (or use `git -C`) the specific repo before git commands.

## Repos

| Path | Package / import | Language | Role |
|---|---|---|---|
| `repos/cloudmr-tools` | `cmtools` | Python | Base multi-coil recon library: RSS, B1, SENSE, GRAPPA, g-factor, ESPIRiT, AWS helpers |
| `repos/mroptimum-tools` | `mrotools` | Python | SNR estimation (AC, MR, PMR, CR), Siemens/NumPy/MATLAB k-space loaders, FA normalization. CLI: `python -m mrotools.snr` |
| `repos/mroptimum-app` | — | Python, AWS SAM, Docker | MR Optimum backend: Step Functions → Lambda/Fargate running `mrotools`. Mode 1 (CloudMRHub account) / Mode 2 (user account) |
| `repos/camrie-tools` | `camrie_tools` | Python + Julia | CAMRIE MRI simulation pipeline via KomaMRI (`KomaInterface.jl`). CLIs: `camrie-koma-pipeline`, `camrie-install-julia`, ... |
| `repos/CAMRIE-app` | — | Python, AWS SAM, Docker | CAMRIE backend: AWS wrapper that installs `camrie-tools` into Fargate/GPU images |

## Dependency graph

```
cloudmr-tools (cmtools) ──► mroptimum-tools (mrotools) ──► mroptimum-app
        │                                                  ▲
        └──────────────────────────────────────────────────┘ (direct dep too)
        └──► CAMRIE-app ◄── camrie-tools ◄── KomaInterface.jl (external, Julia)
```

## Cross-repo rules

- **Apps consume libraries by git ref, not local path.** Pins live in:
  - `mroptimum-app/calculation/src/requirements*.txt`, `mroptimum-app/worker/requirements.txt` (`mrotools@v3.1.0`, `cmtools@main` unpinned)
  - `CAMRIE-app/.github/workflows/*.yml` (`CAMRIE_TOOLS_REF`), Dockerfiles default to `main`
  - `CAMRIE-app/calculation/src/requirements.txt` (`cmtools@main`)
  A change in a tools repo only reaches an app after it's pushed/tagged AND the pin is bumped.
  When changing a library API, grep the downstream repos for usages before and after.
- **For local cross-repo development**, install libraries editable into one env, downstream-first last:
  `pip install -e repos/cloudmr-tools -e repos/mroptimum-tools -e repos/camrie-tools`
- `cmtools` is consumed unpinned (`@main`) by three repos — a push to cloudmr-tools `main` affects all of them immediately on next build. Treat it as a breaking-change hotspot.

## Safety

- **Pushing to `main` in `mroptimum-app` or `CAMRIE-app` triggers GitHub Actions that build images and deploy to AWS** (mroptimum-app also deploys from `dev`). Never push to those branches without explicit confirmation; work on feature branches.
- Don't run `sam deploy`, `aws` mutating commands, or `scripts/register-computing-unit.sh` / `submit-job.sh` without asking.
- `.aws-sam/` is build output — don't edit it.

## Working across repos

- One logical change spanning repos = one branch per repo with the same name, and one PR per repo. Mention the sibling PRs in each description.
- When asked about "the project" or MRI synthesis generally, the simulation path is camrie-tools → CAMRIE-app; the SNR/reconstruction path is cloudmr-tools → mroptimum-tools → mroptimum-app.
- Each repo has its own `CLAUDE.md` with build/test specifics; read it before working in that repo.
- `./bootstrap.sh` clones any missing repos and pulls existing ones.
