version 1.0
# Calculate LD Scores
# TODO add annot_prefix to be variable. add plink_prefix to be flexible

workflow calculate_ldscores {
  input {
    String annot_directory 
    String annot_path = sub(annot_directory, "[/\\s]+$", "") + "/"
    Array[Int] chroms = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
    # Array[File] annot_files # ex. snps.${i}.annot.gz 
    # String annot_prefix="snps"
  } # String greeting2 = "~{salutation + ' ' + name2 + ', '}nice to meet you!"

  scatter (chrom in chroms){
    String annot_file="~{annot_path + 'snps.' + chrom}" + '.annot.gz'
    # File annot_file=annot_path+'.annot.gz'
    call calculate_ldscore {
        input:
        annot_file=annot_file,
        annot_basename="snps.", 
        chrom='~{chrom}'
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

    File plink_zip="https://storage.googleapis.com/broad-alkesgroup-public/LDSCORE/1000G_Phase3_plinkfiles.tgz"
    # String plink_path='1000G_EUR_Phase3_plink'
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
    tar -xvzf ${plink_zip} -C plink_dir
    python ${ldsc_path}/ldsc.py\
          --l2 \
          --bfile plink_dir/1000G.EUR.QC.${chrom}\
          --ld-wind-cm 1\
          --annot ${annot_file}\
          --out ${annot_basename}\
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

}