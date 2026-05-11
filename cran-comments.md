## R CMD check --as-cran

- Checked with `R CMD check --as-cran` on macOS (aarch64). All suggested packages must be installed for a strict `--as-cran` run; this includes `pdftools` (optional PDF text path in `ccsr_changelog()`).
- If `pdftools` is not installed locally, set `_R_CHECK_FORCE_SUGGESTS_=false` or install `pdftools` (and system Poppler where required) before submitting.
- Vignettes: run `R CMD build` without `--no-build-vignettes` when Pandoc is available so the tarball includes built vignette outputs; CRAN will rebuild from source on their systems.

## Win-builder / rhub

- Please also verify on Win-builder (release and devel R) before publication, per CRAN guidance.
