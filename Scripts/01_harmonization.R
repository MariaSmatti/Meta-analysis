setwd("/usr/home/guests/pkimu/Meta_analysis")

library(data.table)
library(dplyr)
library(stringr)

# Define a dictionary of possible names → standard names
col_dict <- list(
  SNP   = c("SNP", "RSID", "MarkerName", "rsid", "SNPID"),
  CHR   = c("CHR", "Chromosome", "chrom", "chr"),
  BP    = c("BP", "Position", "POS", "bp"),
  A1    = c("A1", "Effect_allele", "Allele1", "EA", "EFFECT_ALLELE"),
  A2    = c("A2", "Other_allele", "Allele2", "OA", "NEA", "OTHER_ALLELE"),
  BETA  = c("BETA", "Effect", "b", "beta", "Effect_Size"),
  SE    = c("SE", "StdErr", "se"),
  P     = c("P", "pval", "PVAL", "p"),
  N     = c("N", "n_total", "Samplesize", "N_samples"),
  FRQ   = c("FRQ", "EAF", "Freq1", "Freq.Allele1.HapMapCEU", "EFFECT_ALLELE_FREQ"),
  INFO  =c("INFO","IMPUTE_INFO","RSQR","R2")
)


# Helper to rename columns
rename_columns <- function(df) {
  new_names <- names(df)
  for(std in names(col_dict)) {
    match <- intersect(col_dict[[std]], names(df))
    if(length(match) > 0) {
      new_names[which(names(df) == match[1])] <- std
    }
  }
  setnames(df, new_names)
  return(df)
}

# Harmonize one file
harmonize_gwas <- function(file) {
  message("Processing: ", file)
  
  df <- fread(file, nThread = 4)
  df <- rename_columns(df)
  
  # Keep only recognized columns
  keep <- c("SNP","CHR","BP","A1","A2","BETA","SE","P","N","FRQ")
  df <- df %>% select(any_of(keep))
  
  # Report missing essentials
  essentials <- c("SNP", "A1", "A2", "BETA", "SE", "P")
  missing <- setdiff(essentials, names(df))
  if(length(missing) > 0) {
    warning("File ", file, " is missing essential columns: ", paste(missing, collapse=", "))
  }
  
  # Save harmonized version
  out_name <- str_replace(basename(file), "\\.txt.*|\\.gz$", "_harmonized.txt.gz")
  fwrite(df, out_name, sep="\t")
  message("Saved: ", out_name)
}

# === Run on all files in folder ===
files <- list.files(pattern = "\\.gz$", full.names = TRUE)


for(f in files) {
  tryCatch({
    harmonize_gwas(f)
  }, error = function(e) {
    message("❌ Skipped ", f, " (reason: ", e$message, ")")
  })
}
