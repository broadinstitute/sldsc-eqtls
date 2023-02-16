version 1.0
# Calculate LD Scores
# TODO add annot_prefix to be variable. add plink_prefix to be flexible

workflow calculate_ldscores {
  input {
    String annot_directory # annot_files should be called snps.${chrom}.annot.gz
    String annot_path = sub(annot_directory, "[/\\s]+$", "") + "/"

    String plink_directory
    String plink_path = sub(plink_directory, "[/\\s]+$", "") + "/"

    Array[String] chroms = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22"]
  } 

  scatter (chrom in chroms){
    String annot_file="~{annot_path + 'snps.' + chrom + '.annot.gz'}"
    call calculate_ldscore {
        input:
        annot_file=annot_file,
        chrom=chrom,
        plink_path=plink_path,
    }
  }
}


task calculate_ldscore {
  input {
    
    File annot_file 
    String chrom="1" #=sub(annot_basename, "snps.", "")

    String plink_path="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/1000G_EUR_Phase3_plink/"
    String plink_prefix=plink_path + '1000G.EUR.QC.'
    File plink_bed=plink_path + "1000G.EUR.QC." + chrom + ".bed"
    File plink_bim=plink_path + "1000G.EUR.QC." + chrom + ".bim"
    File plink_fam=plink_path + "1000G.EUR.QC." + chrom + ".fam"
    String bfile = sub(plink_fam, ".fam", "")

    File snps_file="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/snplist.hm3.txt"

    String docker_image='docker.io/lifebitai/ldsc-pipe:latest'
    String ldsc_path='/ldsc'
  }
  command {
    set -euo pipefail
    source activate ldsc
    python ${ldsc_path}/ldsc.py\
          --l2 \
          --bfile ${bfile}\
          --ld-wind-cm 1\
          --annot ${annot_file}\
          --out snps.${chrom}\
          --print-snps ${snps_file}\
          --thin-annot\
          & # parallelize
  }

  runtime {
    docker: docker_image
  }

  output {
    File ldscore_file="snps.${chrom}.l2.ldscore.gz"
    File m_file="snps.${chrom}.l2.M"
    File m_5_50_file="snps.${chrom}.l2.M_5_50"
    File log_file="snps.${chrom}.log"
  }
}