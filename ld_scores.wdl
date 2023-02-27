version 1.0
# Calculate LD Scores
import "tasks/calculate_ldscore.wdl" as task_calculate_ldscore
import "tasks/copy_to_google_bucket.wdl" as copy2bucket

workflow calculate_ldscores {
  input {
    String annot_directory # annot_files should be called snps.${chrom}.annot.gz
    String plink_directory
    
    Array[String] chroms = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22"]

    String output_gs_dir
    String dir_name = ""

  } 

  scatter (chrom in chroms){
    # add slash if needed
    String annot_path = sub(annot_directory, "[/\\s]+$", "") + "/" 
    String plink_path = sub(plink_directory, "[/\\s]+$", "") + "/" 
    # annot file per chrom
    String annot_file="~{annot_path + 'snps.' + chrom + '.annot.gz'}"
    call task_calculate_ldscore.calculate_ldscore {
        input:
        annot_file=annot_file,
        chrom=chrom,
        plink_path=plink_path,
    }
  }
  call copy2bucket.CopyFiles2Directory as copy_0 {
    input: 
      files_2_copy=calculate_ldscore.annot_file_out,
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }
  call copy2bucket.CopyFiles2Directory as copy_1 {
    input: 
      files_2_copy=calculate_ldscore.ldscore_file,
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }
  call copy2bucket.CopyFiles2Directory as copy_2 {
    input: 
      files_2_copy=calculate_ldscore.m_file,
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }
  call copy2bucket.CopyFiles2Directory as copy_3 {
    input: 
      files_2_copy=calculate_ldscore.m_5_50_file,
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }
  call copy2bucket.CopyFiles2Directory as copy_4 {
    input: 
      files_2_copy=calculate_ldscore.log_file,
      output_gs_dir=output_gs_dir,
      dir_name=dir_name,
  }

  output {
    Array[File] annot_files=calculate_ldscore.annot_file_out
    Array[File] ldscore_files = calculate_ldscore.ldscore_file
    Array[File] m_files = calculate_ldscore.m_file
    Array[File] m_5_50_files = calculate_ldscore.m_5_50_file
    Array[File] log_files = calculate_ldscore.log_file

    Array[File] new_annot_file_paths = copy_0.new_file_paths
    Array[File] new_ldscore_file_paths = copy_1.new_file_paths
    Array[File] new_m_file_paths = copy_2.new_file_paths
    Array[File] new_m_5_50_file_paths = copy_3.new_file_paths
  }
}
