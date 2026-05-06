# Build Method

This document describes how the Pakistan SARS-CoV-2 Nextstrain build is developed and updated.

## 1. Download Input Data

Download SARS-CoV-2 records from GISAID as two matching files:

- Metadata TSV.
- Sequence FASTA.

Recommended search filters:

- Virus: SARS-CoV-2 / hCoV-19.
- Location: Asia / Pakistan.
- Complete genome.
- High coverage when available.
- Exact collection date when available.

The metadata and FASTA must contain matching sequence names/accessions.

## 2. Prepare the Workflow

The build uses the official `nextstrain/ncov` workflow at release `v16`.

The setup script clones the workflow into:

```text
work/ncov
```

It then copies the Pakistan profile files into:

```text
work/ncov/my_profiles/pakistan
```

The setup script also downloads the small open reference files into:

```text
work/ncov/data/remote-open/reference/
```

These reference records are used for rooting and global context.

## 3. Configure Inputs

The run script generates:

```text
work/ncov/my_profiles/pakistan/builds.yaml
```

This generated file points to:

- The local GISAID metadata TSV.
- The local GISAID FASTA.
- The downloaded open reference metadata.
- The downloaded open reference aligned FASTA.

The build name is:

```text
Pakistan
```

This produces output filenames compatible with Nextstrain community hosting:

```text
ncov_Pakistan.json
ncov_Pakistan_root-sequence.json
ncov_Pakistan_tip-frequencies.json
```

## 4. Sanitize Metadata and Sequences

The workflow normalizes GISAID fields into standard Nextstrain/Augur fields.

Examples:

- `Virus name` becomes `strain`.
- `Accession ID` becomes `gisaid_epi_isl`.
- `Collection date` becomes `date`.
- `Location` is parsed into `region`, `country`, `division`, and `location`.
- `Lineage` becomes `pango_lineage`.
- `Clade` becomes `GISAID_clade`.

Sequence prefixes such as `hCoV-19/` are stripped internally for compatibility.

## 5. Alignment and QC

Nextclade aligns the genomes to the SARS-CoV-2 reference and assigns QC annotations.

The workflow joins Nextclade QC results back into the metadata. Problematic sequences can be excluded by the diagnostic step.

Typical filters include:

- Minimum genome length.
- Non-ambiguous sampling date.
- Diagnostic flags for clock outliers or potential contamination.

## 6. Tree Building

The filtered alignment is passed to IQ-TREE.

The Pakistan build uses the standard SARS-CoV-2 model settings from the `nextstrain/ncov` workflow:

```text
GTR model
IQ-TREE maximum-likelihood tree search
```

For several thousand genomes, this step is usually the longest part of the build.

## 7. Tree Refinement

TreeTime refines the raw tree into a time-resolved phylogeny.

The root is:

```text
Wuhan-Hu-1/2019
```

Clock settings follow the standard Nextstrain SARS-CoV-2 assumptions:

```text
clock rate: 0.0008 substitutions/site/year
clock standard deviation: 0.0004
```

## 8. Annotation

After refinement, the workflow infers:

- Nucleotide mutations.
- Amino-acid mutations.
- Nextstrain clades.
- Emerging lineage labels.
- Country and division ancestral traits.
- Tip frequencies.
- Epiweek annotations.

## 9. Auspice Export

The final export creates Auspice v2 JSON files.

The profile sets:

- Title: `Genomic epidemiology of SARS-CoV-2 in Pakistan`.
- Build URL: `https://github.com/adnanhaider81/pakistan-sars-cov-2-nextstrain-build/`.
- Maintainer: NIH Bioinformatics Group of Virology, Pakistan.
- Default color: `division`.
- Default geographic resolution: `division`.
- Panels: tree, map, entropy, frequencies.

## 10. Publish

The publish script copies final files into the community repository:

```text
auspice/ncov_Pakistan.json
auspice/ncov_Pakistan_root-sequence.json
auspice/ncov_Pakistan_tip-frequencies.json
```

After commit and push, Nextstrain serves the updated dataset from GitHub.

## 11. Quality Checks Before Publishing

Before pushing, check:

- The build completed without fatal errors.
- `auspice/ncov_Pakistan.json` is under 100 MB.
- The `meta.updated` field reflects the current build date.
- The number of final sequences is reasonable.
- The Nextstrain community URL returns HTTP 200 after push.

Useful commands:

```bash
stat -c '%n %s' work/ncov/auspice/ncov_Pakistan*.json
python3 -m json.tool work/ncov/auspice/ncov_Pakistan.json >/dev/null
curl -I -H 'Accept: application/vnd.nextstrain.dataset.main+json' \
  https://nextstrain.org/community/NIH-BIGVI-PAKISTAN/ncov/Pakistan
```
