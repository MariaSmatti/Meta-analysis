setwd("/Meta_analysis/")

library(dplyr)
library(qqman)

# read data
meta <- read.table("META_HEIGHT_withCHRBP.txt", header=FALSE)

# Assign column names manually (since file has no header after merge)
colnames(meta) <- c("SNP1","Allele1","Allele2","Effect","StdErr","P","Direction",
                    "SNP2","A1","A2","CHR","BP","A1_orig","A2_orig","BETA_orig",
                    "SE_orig","P_orig","N","FREQ")

# Keep only necessary columns
plot_data <- meta %>%
  select(SNP = SNP1, CHR, BP, P)

# Make sure types are correct
plot_data$CHR <- as.numeric(plot_data$CHR)
plot_data$BP <- as.numeric(plot_data$BP)
plot_data$P <- as.numeric(plot_data$P)

# Ensure numeric
plot_data$CHR <- as.numeric(plot_data$CHR)
plot_data$BP  <- as.numeric(plot_data$BP)

# Coerce P to numeric
plot_data$P   <- as.numeric(plot_data$P)

# Drop missing or invalid rows
plot_data <- plot_data %>%
  filter(!is.na(CHR), !is.na(BP), !is.na(P), P > 0, P <= 1)


# Manhattan plot
manhattan(plot_data,
          chr="CHR", bp="BP", snp="SNP", p="P",
          genomewideline = -log10(5e-8),
          suggestiveline = -log10(1e-5),
          main="Meta-analysis Manhattan Plot")

# QQ plot
qq(plot_data$P, main="QQ plot of Meta-analysis")
