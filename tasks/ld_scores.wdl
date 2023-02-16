version 1.0
# Calculate LD Scores

workflow calculate_ldscores {
    input {
        Array[File] unaligned_bams
    }
    call ParseUnalignedBamFilenames {
        input:
            unaligned_bams = unaligned_bams
    }
    scatter (unaligned_sample in ParseUnalignedBamFilenames.unaligned_samples_list){
        call Print {
            input:
                in = unaligned_sample.id
        }
    }
}


task calculate_ldscore {
  input {
    Array[File] annot_files # ex. snps.${i}.annot.gz 
    File run_name # ex. 20230209_${group_name}_fm_eQTLs_pip_${pip}

    File plink_zip="https://storage.googleapis.com/broad-alkesgroup-public/LDSCORE/1000G_Phase3_plinkfiles.tgz"
    String plink_path='1000G_EUR_Phase3_plink'
    File snps_file="from Yi"

    String docker_image='docker.io/lifebitai/ldsc-pipe:latest'
    String ldsc_path='/ldsc'

    Int memory=128
    Int disk_space=128
    Int num_threads=24
    Int num_preempt=0
  }
  command {
    set -euo pipefail
    source activate ldsc
    tar -xvzf ${plink_zip}
    for i in {1..22}
    do
    python ${ldsc_path}/ldsc.py\
          --l2 \
          --bfile ${plink_path}/1000G.EUR.QC.${i}\
          --ld-wind-cm 1\
          --annot ${annot_path}/snps.${i}.annot.gz\
          --out ${ld_path}/snps.${i}\
          --print-snps ${snps_file}\
          --thin-annot\
          & # parallelize
    done
  }

  runtime {
    docker: docker_image
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }

  output {
    Array[File] ldscore_files=glob("${prefix}.*.l2.ldscore.gz")
    Array[File] m_files=glob("${prefix}.*.l2.M")
    Array[File] m_5_50_files=glob("${prefix}.*.l2.M_5_50")
    Array[File] log_files=glob("${prefix}.*.log")
  }
}