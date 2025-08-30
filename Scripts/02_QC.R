setwd("/usr/home/guests/pkimu/Meta_analysis/")

library(data.table)
library(dplyr)
library(stringr)

# === QC Function ===
qc_gwas <- function(file) {
  message("QC on: ", file)
  
  df <- fread(file, nThread = 4)
  
  # ---- 1. Remove variants with MAF too low (e.g., < 0.01)
  if("FRQ" %in% names(df)) {
    df <- df %>% filter(FRQ >= 0.01 & FRQ <= 0.99)
  }
  
  # ---- 2. Remove multi-allelic variants (same SNP with >2 alleles)
  if(all(c("SNP","A1","A2") %in% names(df))) {
    df <- df %>%
      group_by(SNP) %>%
      filter(n_distinct(c(A1, A2)) == 2) %>%
      ungroup()
  }
  
  # ---- 3. Remove duplicated variants
  if("SNP" %in% names(df)) {
    df <- df %>% distinct(SNP, .keep_all = TRUE)
  }
  
  # ---- 4. Remove Copy Number Variants (CNVs)
  if("SNP" %in% names(df)) {
    df <- df %>% filter(!str_detect(SNP, "CNV|cnv|INS|DEL"))
  }
  
  # ---- 5. Normalize indels (represent consistently)
  if(all(c("A1","A2") %in% names(df))) {
    df$A1 <- toupper(df$A1)
    df$A2 <- toupper(df$A2)
    # Replace common representations
    df$A1[df$A1 %in% c("D","DEL","-")] <- "-"
    df$A2[df$A2 %in% c("D","DEL","-")] <- "-"
    df$A1[df$A1 %in% c("I","INS")] <- "+"
    df$A2[df$A2 %in% c("I","INS")] <- "+"
  }
  
  # ---- 6. Standardize notations (force alleles uppercase A/C/G/T/-/+)
  if(all(c("A1","A2") %in% names(df))) {
    df$A1 <- toupper(df$A1)
    df$A2 <- toupper(df$A2)
  }
  
  # ---- 7. Remove variants with extreme effect sizes
  if("BETA" %in% names(df)) {
    df <- df %>% filter(abs(BETA) < 10)  # threshold can be tuned
  }
  
  # ---- 8. Filter out variants with low imputation accuracy
  if("INFO" %in% names(df)) {
    df <- df %>% filter(INFO >= 0.8)
  }
  
  # Save QC’d file
  out_name <- str_replace(basename(file), "_harmonized.txt.gz$", "_QC.txt.gz")
  fwrite(df, out_name, sep = "\t")
  message("✅ Saved QC file: ", out_name)
}


# === Run QC on all harmonized files ===
files <- list.files(pattern = "_harmonized.txt.gz$", full.names = TRUE)

for(f in files) {
  tryCatch({
    qc_gwas(f)
  }, error = function(e) {
    message("❌ Skipped ", f, " (reason: ", e$message, ")")
  })
}
