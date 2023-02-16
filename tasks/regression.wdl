version 1.0
# Calculate LD Scores
# TODO add annot_prefix to be variable. add plink_prefix to be flexible

workflow regressions {
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


task regression {
  input {
    
    File annot_file 
    String chrom="1" #=sub(annot_basename, "snps.", "")

    String plink_path="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/1000G_EUR_Phase3_plink/"
    String plink_prefix=plink_path + '1000G.EUR.QC.'
    File plink_bed="~{plink_prefix + chrom + '.bed'}"
    File plink_bim="~{plink_prefix + chrom + '.bim'}"
    File plink_fam="~{plink_prefix + chrom + '.fam'}"
    File snps_file="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/snplist.hm3.txt"

    File frq_tar=
    File weights_tar=
    File baseline_tar=

    String docker_image='docker.io/lifebitai/ldsc-pipe:latest'
    String ldsc_path='/ldsc'
  }
  command {
    set -euo pipefail
    source activate ldsc
    python ${ldsc_path}/ldsc.py\
      --h2 ${sumstats_path}/${i}.sumstats.gz\
      --ref-ld-chr ${annot_path}/snps.,${baseline_path}\
      --overlap-annot\
      --frqfile-chr ${frq_path}\
      --w-ld-chr ${weight_path}\
      --out ${reg_path}/${i}\
      --print-coefficients\
      & # parallelize
  }

  runtime {
    docker: docker_image
  }

  output {
    File regression_file="${gwas_name}.results"
    File log_file="${gwas_name}.log"
  }
}