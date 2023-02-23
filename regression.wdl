version 1.0
# Calculate s-ldsc regression

workflow regressions {
  input {
    Array[File] annot_files # annot_files should be called snps.${chrom}.annot.gz
    Array[File] gwas_sumstats_files
  } 

  scatter (gwas_sumstats_file in gwas_sumstats_files){
    String gwas_name = sub(basename(gwas_sumstats_file), ".sumstats.gz", "")
    # File gwas_name = gwas_path + gwas_name + ".sumstats.gz"
    call regression {
      input:
      annot_files=annot_files,
      gwas_sumstats_file=gwas_sumstats_file,
      gwas_name=gwas_name,
    }
  }
  output {
    Array[File] regression_files = regression.regression_file
    Array[File] log_files = regression.log_file

  }
}


task regression {
  input {
    Array[File] annot_files
    File annot_file=select_first(annot_files)

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
    annot_base=$(echo "${annot_file}" | rev | cut -f 2- -d '.' | rev)

    python ${ldsc_path}/ldsc.py\
      --h2 ${gwas_sumstats_file}\
      --ref-ld-chr $annot_base,baseline/baselineLD.\
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