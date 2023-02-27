version 1.0

# import other WDLs
import "ld_scores.wdl" as wf_ld_scores
import "regression.wdl" as wf_regressions

# This workflow takes cellranger data to grouped pseudobulk
workflow full_sldsc {
  input {
    String annot_directory # annot_files should be called snps.${chrom}.annot.gz
    String plink_directory
    String regression_directory
    Array[File] gwas_sumstats_files
  }

  # Calculate LD scores
  call wf_ld_scores.calculate_ldscores as ldscores {
    input:
    annot_directory=annot_directory,
    plink_directory=plink_directory,
    output_gs_dir=annot_directory,
  }

  # Calculate regressions
  call wf_regressions.regressions as regressions {
    input:
    annot_files=ldscores.new_annot_file_paths,
    gwas_sumstats_files=gwas_sumstats_files,
    ldscore_files=ldscores.new_ldscore_file_paths,
    m_files=ldscores.new_m_file_paths,
    m_5_50_files=ldscores.new_m_5_50_file_paths,
    output_gs_dir=regression_directory,
  }



  output {
    Array[File] new_regression_files=regressions.new_regression_files
  }

}
