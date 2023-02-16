version 1.0
# Calculate LD Scores
# TODO add annot_prefix to be variable. add tar_prefix to be flexible

workflow regressions {
  input {
    String annot_directory # annot_files should be called snps.${chrom}.annot.gz
    Array[String] gwas_names
  } 

  scatter (gwas_name in gwas_names){
    call regression {
      input:
      annot_directory=annot_directory,
      gwas_name=gwas_name,
    }
  }
}


task regression {
  input {
    String annot_directory # annot_files should be called snps.${chrom}.annot.gz
    String annot_path = sub(annot_directory, "[/\\s]+$", "") + "/"
    # Array[File] annot_files = glob

    File frq_tar="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/1000G_Phase3_frq.tgz"
    File weights_tar="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/1000G_Phase3_weights_hm3_no_MHC.tgz"
    File baseline_tar="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/1000G_Phase3_baselineLD_v2.2_ldscores.tgz"

    String gwas_name
    File gwas_sumstats_file = gwas_name + ".sumstats.gz"

    String docker_image='docker.io/lifebitai/ldsc-pipe:latest'
    String ldsc_path='/ldsc'
  }
  command {
    set -euo pipefail
    source activate ldsc
    mkdir frq weights baseline
    tar -zxvf ${frq_tar} > frq
    tar -zxvf ${weights_tar} > weights
    tar -zxvf ${baseline_tar} > baseline
    python ${ldsc_path}/ldsc.py\
      --h2 ${gwas_sumstats_file}\
      --ref-ld-chr ${annot_path}/snps.,baseline/baselineLD.\
      --overlap-annot\
      --frqfile-chr frq/1000G.EUR.QC.\
      --w-ld-chr weights/weights.hm3_noMHC.\
      --out ${gwas_name}\
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