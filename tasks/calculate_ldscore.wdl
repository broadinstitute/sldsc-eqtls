version 1.0
# Calculate LD Scores
# TODO add annot_prefix to be variable. add plink_prefix to be flexible

task calculate_ldscore {
  input {
    
    File annot_file 
    String chrom="1" #=sub(annot_basename, "snps.", "")

    String plink_path="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/1000G_EUR_Phase3_plink/"
    File plink_bed=plink_path + "1000G.EUR.QC." + chrom + ".bed"
    File plink_bim=plink_path + "1000G.EUR.QC." + chrom + ".bim"
    File plink_fam=plink_path + "1000G.EUR.QC." + chrom + ".fam"

    File snps_file="gs://landerlab-20220124-ssong-village-eqtls/2023_02_16_ldsc/snplist.hm3.txt"

    String docker_image='docker.io/lifebitai/ldsc-pipe:latest'
    String ldsc_path='/ldsc'
  }
  command {
    set -euo pipefail
    source activate ldsc
    plink_base=$(echo "${plink_bed}" | rev | cut -f 2- -d '.' | rev)
    python ${ldsc_path}/ldsc.py\
          --l2\
          --bfile $plink_base\
          --ld-wind-cm 1\
          --annot ${annot_file}\
          --out snps.${chrom}\
          --print-snps ${snps_file}\
          --thin-annot
  }

  runtime {
    docker: docker_image
  }

  output {
    File annot_file_out=annot_file # hacky way to get annot files to list as array in scatter
    File ldscore_file="snps.${chrom}.l2.ldscore.gz"
    File m_file="snps.${chrom}.l2.M"
    File m_5_50_file="snps.${chrom}.l2.M_5_50"
    File log_file="snps.${chrom}.log"
  }
}