version 1.0
# Calculate s-ldsc regression
import "tasks/calculate_regression.wdl" as task_calculate_regression
import "tasks/copy_to_google_bucket.wdl" as copy2bucket

workflow regressions {
  input {
    Array[File] annot_files # annot_files should be called snps.${chrom}.annot.gz
    Array[File] gwas_sumstats_files

    Array[File] ldscore_files
    Array[File] m_files
    Array[File] m_5_50_files

    String output_gs_dir
    String dir_name = "regression"

  } 

  scatter (gwas_sumstats_file in gwas_sumstats_files){
    String gwas_name = sub(basename(gwas_sumstats_file), ".sumstats.gz", "")
    # File gwas_name = gwas_path + gwas_name + ".sumstats.gz"
    call task_calculate_regression.regression {
      input:
      annot_files=annot_files,
      gwas_sumstats_file=gwas_sumstats_file,
      gwas_name=gwas_name,
      ldscore_files=ldscore_files,
      m_files=m_files,
      m_5_50_files=m_5_50_files,
    }
  }
  call copy2bucket.CopyFiles2Directory as copy_0 {
    input: 
      files_2_copy=regression.regression_file,
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }
  output {
    Array[File] regression_files = regression.regression_file
    Array[File] log_files = regression.log_file

    Array[File] new_regression_files = copy_0.new_file_paths
  }
}
