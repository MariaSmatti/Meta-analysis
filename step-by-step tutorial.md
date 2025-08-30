# 🧬 GWAS Meta-Analysis Tutorial

This tutorial walks you through performing a **meta-analysis of GWAS summary statistics**.  
We will cover: preparation & QC, harmonization, running meta-analysis (with [METAL](https://genome.sph.umich.edu/wiki/METAL_Documentation)), diagnostics, and downstream analyses.

We cover:  
1. Preparing input files  
2. Quality control (QC)  
3. Harmonization across studies  
4. Running meta-analysis in METAL  
5. Preparing and visualizing results  
---
A typical workflow of meta-analysis

![A typical workflow of meta-analysis](https://user-images.githubusercontent.com/40289485/218293217-d6a50f73-98f7-4957-82a3-d10a85bed8dc.png)

## 1. 📦 Requirements

### Software
- [PLINK](https://www.cog-genomics.org/plink/1.9/) — for QC, clumping, and LD.
- [METAL](https://genome.sph.umich.edu/wiki/METAL_Documentation) — main meta-analysis tool.
- [R](https://www.r-project.org/) with `tidyverse`, `qqman`, `metafor` — for data wrangling, plots, heterogeneity tests.
- (Optional) [METASOFT](http://genetics.cs.ucla.edu/meta/) — random-effects meta-analysis.
- (Optional) [LDSC](https://github.com/bulik/ldsc) — check for sample overlap.

---

## 2. 📂 Input Data

Each study should provide summary statistics with consistent columns. The minimum required are:  


| Column       | Description                                           |
|--------------|-------------------------------------------------------|
| SNP          | rsID                                                  |
| CHR          | Chromosome                                            |
| BP           | Base-pair position                                    |
| A1           | Effect allele                                         |
| A2           | Other allele                                          |
| BETA / OR    | Effect size (log-odds for binary traits)              |
| SE           | Standard error of effect size                         |
| P            | P-value                                               |
| N            | Sample size                                           |
| EAF (opt.)   | Effect allele frequency                               |
| INFO (opt.)  | Imputation quality score                              | 

---

## 3. 🔍 Quality Control (QC)

Each dataset should be QC’d before meta-analysis:  

1. **Genome build alignment**  
   - Convert all datasets to the same reference genome build (e.g., GRCh37 or GRCh38).  

2. **Variant-level filters**  
   - Remove SNPs with low imputation quality (INFO < 0.8).  
   - Remove rare SNPs (MAF < 0.01).  
   - Exclude multiallelic SNPs and indels if uncertain.  

3. **Consistency checks**  
   - Confirm alleles are A, C, G, or T only.  
   - Ensure effect allele (A1) matches the effect direction.  
   - Remove ambiguous SNPs (A/T or C/G) if strand cannot be determined.  

---

## 4. 🔄 Harmonization

After QC, ensure datasets are harmonized:  

- Rename columns to a consistent format for METAL.  
- Standardize effect allele naming (A1, A2).  
- Align allele orientation across studies.  
- Prepare files in plain text, tab-delimited format.  

---

## 5. 🏃 Running Meta-Analysis in METAL

To run METAL:  

1. Write a control script that specifies:  
   - The **effect size and SE scheme** (`SCHEME STDERR`).  
   - Which columns contain marker, alleles, effect size, SE, p-value, and sample size.  
   - A list of study files to process.  

2. Run METAL with the script.  
   - METAL produces `.tbl` files containing meta-analysis results.  

---

## 6. 📊 Preparing Results

METAL’s output usually contains SNP, effect size, SE, p-value, and weight.  

- It may not include chromosome and position, so merge results with a reference file containing `CHR` and `BP`.  
- Clean the data by ensuring `CHR`, `BP`, and `P` are numeric, and remove missing values.  

---

## 7. 🌆 Visualization

After preparing results, visualization includes:  

- **Manhattan plots** — to show genome-wide significance across chromosomes.  
- **QQ plots** — to assess inflation of test statistics.  
- **Heterogeneity tests** (optional) — to check for inconsistent effects across studies.  

---




