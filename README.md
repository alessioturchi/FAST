# FAST Automation Module

This repository contains the **automation module** of FAST (Forecast Automation System for
Telescopes): a bash/Python/Fortran pipeline that runs a single, once-per-night Meso-NH /
Astro-Meso-NH atmospheric and optical-turbulence forecast for a ground-based telescope site.

Given a working Meso-NH installation and a configured site (domain geometry, calibration
tables, delivery targets), the automation:

1. waits for and validates the day's initialization (forcing) files;
2. runs the Meso-NH mesoscale simulation (PREP_REAL → EXE → DIAG) over the configured
   nested domains;
3. post-processes the raw model output into astroclimatic parameters (optical turbulence
   C²_N, seeing, isoplanatic angle, coherence time, wind, temperature, relative humidity,
   precipitable water vapour, ...);
4. generates the delivered diagnostic plots;
5. uploads/backs up the results, and optionally hands off ground-parameter data to a
   separate, short-timescale (autoregressive/ML) correction component.

This is a **single-configuration** edition: one `bin/` tree, one set of
`bin/conf.d/*.var` configuration files, one nightly `run.sh`. There is no orchestration
layer here for coordinating several configurations or instances — a deployment that needs
that has to build it as a wrapper around this code.

Full documentation — configuration file reference, parameter-by-parameter tables,
installation steps, script-by-script behaviour, and the delivered output file format — is
in **[`manual/AUTOMATION_MANUAL.pdf`](manual/AUTOMATION_MANUAL.pdf)** (LaTeX source under
[`manual/`](manual/)). This README only covers the high-level picture and requirements;
everything about configuring or installing a deployment is in the manual.

## ⚠️ Meso-NH output format compatibility

This codebase reads and writes Meso-NH's legacy **`.lfi`** binary output format throughout
(PREP_REAL, EXE and DIAG outputs, the optional `bzip2` compression step, the
`conv2dia`/`diaprog` post-processing chain). It has **not** been adapted to the **`.nc4`**
(NetCDF-4) output format used by more recent Meso-NH versions. If your Meso-NH build only
produces `.nc4` output, the post-processing chain in `bin/postproc.sh` and the helper
programs under `bin/conf.d/utils/` will need to be adapted before this automation can be
used — that work is outside the scope of this repository.

The codebase is currently validated against **Meso-NH V5.2.1** built with **eccodes 2.30.0**.

## Requirements

- Meso-NH (V5.2.1; see the compatibility note above) and a matching OpenMPI build
- eccodes (incl. `grib_copy`)
- gfortran + `make` (to build the helper programs under `bin/conf.d/utils`)
- bash ≥ 4.x, Python 3 (+ a dedicated virtualenv)
- GNU `parallel`, ImageMagick (`convert`), `bc`
- OpenSSH client + `rsync`
- A Gmail API OAuth client (used for alert/completion e-mail; see the manual)

See **Section 3 (Dependencies and installation)** of the manual for exact versions, the
Python package list, and the full step-by-step installation procedure — including building
the Fortran helpers, setting up SSH keys, generating the PGD (orography) files, and the
cron entry for nightly operation.

## Repository layout

```
AUTOMATION/bin/            executable scripts (run.sh, postproc.sh, plot_python.sh, ...)
AUTOMATION/bin/conf.d/     configuration files (*.var), namelist templates, calibration
                           tables, compiled Fortran helpers
manual/                    the automation manual (LaTeX source + compiled PDF)
```

Configuration is entirely file-based under `AUTOMATION/bin/conf.d/*.var` — see the manual
for what each file and parameter does before editing anything.

## Status

This is research-support software developed and operated in-house; it is shared as-is,
without a support commitment. Issues and pull requests are welcome, but response times may
vary.
