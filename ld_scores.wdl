version 1.0
# Calculate LD Scores
# TODO add annot_prefix to be variable. add plink_prefix to be flexible

workflow calculate_ldscores {
  input {
    String annot_directory # annot_files should be called snps.${chrom}.annot.gz
    String annot_path = sub(annot_directory, "[/\\s]+$", "") + "/"

    String plink_directory
    String plink_path = sub(plink_directory, "[/\\s]+$", "") + "/"

    Array[Int] chroms = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]

    # Array[File] annot_files # ex. snps.${i}.annot.gz 
    # String annot_prefix="snps"
  } 

  scatter (chrom in chroms){
    String annot_file="~{annot_path + 'snps.' + chrom + '.annot.gz'}"
    call calculate_ldscore {
        input:
        annot_file=annot_file,
        annot_basename="snps.", 
        chrom='~{chrom}',
        plink_path=plink_path,
    }
  }
}
  # output {
  #   Array[File] ldscore_files=glob("${prefix}.*.l2.ldscore.gz")
  #   Array[File] m_files=glob("${prefix}.*.l2.M")
  #   Array[File] m_5_50_files=glob("${prefix}.*.l2.M_5_50")
  #   Array[File] log_files=glob("${prefix}.*.log")
  # }


task calculate_ldscore {
  input {
    
    File annot_file 
    String annot_basename #=basename(annot_file, ".annot.gz")
    String chrom #=sub(annot_basename, "snps.", "")

    File plink_path
    String plink_prefix=plink_path + '1000G.EUR.QC.'
    File plink_bed="~{plink_prefix + chrom + '.bed'}"
    File plink_bim="~{plink_prefix + chrom + '.bim'}"
    File plink_fam="~{plink_prefix + chrom + '.fam'}"
    File snps_file="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/snplist.hm3.txt"

    String docker_image='docker.io/lifebitai/ldsc-pipe:latest'
    String ldsc_path='/ldsc'

    # Int memory=128
    # Int disk_space=128
    # Int num_threads=24
    # Int num_preempt=0
  }
  command {
    set -euo pipefail
    source activate ldsc
    python ${ldsc_path}/ldsc.py\
          --l2 \
          --bfile ${plink_prefix}${chrom}\
          --ld-wind-cm 1\
          --annot ${annot_file}\
          --out snps.${chrom}\
          --print-snps ${snps_file}\
          --thin-annot\
          & # parallelize
  }

  runtime {
    docker: docker_image
    # memory: "${memory}GB"
    # disks: "local-disk ${disk_space} HDD"
    # cpu: "${num_threads}"
    # preemptible: "${num_preempt}"
  }

  output {
    File ldscore_file="snps.${chrom}.l2.ldscore.gz"
    File m_file="snps.${chrom}.l2.M"
    File m_5_50_file="snps.${chrom}.l2.M_5_50"
    File log_file="snps.${chrom}.log"
  }

}