setwd("/usr/home/guests/pkimu/Meta_analysis/")

library(data.table)
library(dplyr)
library(stringr)

# === Step 1. Allele alignment helper ===
align_alleles <- function(df, ref) {
  # Merge with reference by SNP
  merged <- merge(ref[,.(SNP, REF_A1=A1, REF_A2=A2)], df, by="SNP")
  
  # --- Case 1: Alleles match (same orientation)
  same <- (merged$A1 == merged$REF_A1 & merged$A2 == merged$REF_A2)
  
  # --- Case 2: Alleles flipped (A1/A2 swapped) → flip BETA
  flipped <- (merged$A1 == merged$REF_A2 & merged$A2 == merged$REF_A1)
  merged$BETA[flipped] <- -merged$BETA[flipped]
  tmp <- merged$A1[flipped]
  merged$A1[flipped] <- merged$A2[flipped]
  merged$A2[flipped] <- tmp
  
  # --- Case 3: Strand flips (A↔T, C↔G)
  strand_flip <- ( (merged$A1=="A" & merged$REF_A1=="T") |
                     (merged$A1=="T" & merged$REF_A1=="A") |
                     (merged$A1=="C" & merged$REF_A1=="G") |
                     (merged$A1=="G" & merged$REF_A1=="C") )
  if(any(strand_flip)) {
    merged$A1[strand_flip] <- ifelse(merged$A1[strand_flip]=="A","T",
                                     ifelse(merged$A1[strand_flip]=="T","A",
                                            ifelse(merged$A1[strand_flip]=="C","G","C")))
    merged$A2[strand_flip] <- ifelse(merged$A2[strand_flip]=="A","T",
                                     ifelse(merged$A2[strand_flip]=="T","A",
                                            ifelse(merged$A2[strand_flip]=="C","G","C")))
  }
  
  # --- Case 4: Palindromic SNPs (A/T or C/G) → drop
  ambiguous <- ( (merged$A1 %in% c("A","T") & merged$A2 %in% c("A","T")) |
                   (merged$A1 %in% c("C","G") & merged$A2 %in% c("C","G")) )
  merged <- merged[!ambiguous, ]
  
  return(merged)
}

# === Step 2. Harmonize function ===
harmonize_gwas <- function(file, ref=NULL) {
  message("Processing: ", file)
  
  df <- fread(file, nThread=4)
  
  essentials <- c("SNP","A1","A2","BETA","SE","P")
  missing <- setdiff(essentials, names(df))
  if(length(missing) > 0) {
    warning("File ", file, " is missing essentials: ", paste(missing, collapse=", "))
    return(NULL)
  }
  
  # If reference provided → align alleles
  if(!is.null(ref)) {
    df <- align_alleles(df, ref)
  }
  
  out_name <- str_replace(basename(file), "\\.txt.*|\\.gz$", "_harmonized.txt.gz")
  fwrite(df, out_name, sep="\t")
  message("✅ Saved: ", out_name)
  
  return(df)
}

# === Step 3. Run on all files ===
files <- list.files(pattern="_QC\\.txt\\.gz$", full.names=TRUE)


# Choose first study as reference
ref <- fread(files[1], nThread=4)

# Harmonize all files
all_data <- list()
for(f in files) {
  tryCatch({
    dat <- harmonize_gwas(f, ref=ref)
    if(!is.null(dat)) all_data[[basename(f)]] <- dat
  }, error=function(e) {
    message("❌ Skipped ", f, " (", e$message, ")")
  })
}
