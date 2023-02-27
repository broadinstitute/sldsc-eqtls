version 1.0
# Calculate s-ldsc regression

task regression {
  input {
    Array[File] annot_files
    File annot_file=select_first(annot_files)

    Array[File] ldscore_files
    Array[File] m_files
    Array[File] m_5_50_files

    File frq_tar="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/1000G_Phase3_frq.tgz"
    File weights_tar="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/1000G_Phase3_weights_hm3_no_MHC.tgz"
    File baseline_tar="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/1000G_Phase3_baselineLD_v2.2_ldscores.tgz"

    String gwas_name
    File gwas_sumstats_file = gwas_name + ".sumstats.gz"

    String docker_image='docker.io/lifebitai/ldsc-pipe:latest'
    String ldsc_path='/ldsc'

    Int memory=128
    Int disk_space=128
    Int num_threads=8
    Int num_preempt=0

  }
  command {
    set -e
    source activate ldsc
    tar -zxvf ${frq_tar}
    tar -zxvf ${weights_tar}
    tar -zxvf ${baseline_tar}
    annot_base=$(echo "${annot_file}" | rev | cut -f 4- -d '.' | rev)

    python ${ldsc_path}/ldsc.py\
      --h2 ${gwas_sumstats_file}\
      --ref-ld-chr $annot_base.,baselineLD.\
      --overlap-annot\
      --frqfile-chr 1000G_Phase3_frq/1000G.EUR.QC.\
      --w-ld-chr 1000G_Phase3_weights_hm3_no_MHC/weights.hm3_noMHC.\
      --out ${gwas_name}\
      --print-coefficients\
  }

  runtime {
    docker: docker_image
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }

  output {
    File regression_file="${gwas_name}.results"
    File log_file="${gwas_name}.log"
  }
}