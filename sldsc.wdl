version 1.0

# import other WDLs
import "tasks/ld_scores.wdl" as ld_scores
import "tasks/regression.wdl" as regression

# This workflow takes cellranger data to grouped pseudobulk
workflow scEQTL_pseudobulk {
  input {

    ldsc_path="/mnt/DATA1/software/ldsc"

resources_path="/mnt/DATA1/ldsc_village/resources"
bim_path="${resources_path}/genotype/1000G_EUR_Phase3_plink"
sumstats_path="${resources_path}/gwas/munged"
snps_file="${resources_path}/snp_list/snplist.hm3.txt" 
baseline_path="${resources_path}/baseline_model/1000G_Phase3_baselineLD_v2.2_ldscores/baselineLD."
weight_path="${resources_path}/weights/1000G_Phase3_weights_hm3_no_MHC/weights.hm3_noMHC."
frq_path="${resources_path}/frq/1000G_Phase3_frq/1000G.EUR.QC."
    run_name="20230209_${group_name}_fm_eQTLs_pip_${pip}"
    results_path="/mnt/DATA1/ldsc_village/results/${run_name}"

    annot_path="${results_path}/annot_ld_score_files"
    reg_path="${results_path}/regression"    
    # which donors from VCF to include
    File donors_to_include

    # Thresholds
    Float singlet_threshold = 0.79  # in doublet assignment

    # Cellbender arguments
    Int cellbender_total_droplets
    Int cellbender_expected_cells
    Float? cellbender_fpr = 0.01

# # # https://storage.googleapis.com/broad-alkesgroup-public/LDSCORE/1000G_Phase3_plinkfiles.tgz
# # # https://storage.googleapis.com/broad-alkesgroup-public/LDSCORE/w_hm3.snplist.bz2
# # # https://storage.googleapis.com/broad-alkesgroup-public/LDSCORE/1000G_Phase3_baselineLD_v2.2_ldscores.tgz
# # # https://storage.googleapis.com/broad-alkesgroup-public/LDSCORE/1000G_Phase3_weights_hm3_no_MHC.tgz
# # # https://storage.googleapis.com/broad-alkesgroup-public/LDSCORE/1000G_Phase3_frq.tgz

  }

  # Task calls
 
  # add slash if needed
  String cellranger_path = sub(cellranger_directory, "[/\\s]+$", "") + "/"

  # Calculate LD scores
  call annotate.annotatecellranger as annotation {
    input:
    bam=cellranger_path + 'possorted_genome_bam.bam',
    gtf=GTF
  }

  # LDSC Regression
  File cbc_barcodes = cellranger_path + "filtered_feature_bc_matrix/barcodes.tsv.gz"
  call donorassign.donorassign as donorassignment {
    input:
    bam=annotation.annotatedbam,
    whitelist=cbc_barcodes,
    VCF=VCF,
    TBI=VCF_TBI,
    sample_names=donors_to_include,
    outname=sample_id
  }
  
  # Doublet detection
  call detectdoublets.detectdoublets as doublets {
    input:
    likelihood_file=donorassignment.assignments,
    whitelist=cbc_barcodes,
    bam=annotation.annotatedbam,
    VCF=donorassignment.outvcf,
    sample_names=donors_to_include,
    outname=sample_id
  }

  # Remove doublets
  call removedoublets.remove_doublets as doublet_removal {
    input:
    h5=cellranger_path + "raw_feature_bc_matrix.h5",
    doublets=doublets.doublets,
    threshold=singlet_threshold
  }

  # Remove background with cellbender 
  call cellbender.run_cellbender_remove_background_gpu as run_cellbender {
    input:
    input_10x_h5_file_or_mtx_directory=doublet_removal.h5ad_filtered,
    sample_name=sample_id,
    expected_cells=cellbender_expected_cells,
    fpr=cellbender_fpr,
    total_droplets_included=cellbender_total_droplets
  }

  # Filter to singlets 
  call removedoublets.filter_to_singlets as singlet_filter {
    input:
    h5=run_cellbender.h5_array,
    doublets=doublets.doublets,
    threshold=singlet_threshold
  }

  # modify CBC
  call cbc_modify.cbc_modify as run_cbc_modify {
    input:
    sample_id=sample_id, 
    group_name=group_name, 
    h5ad_filtered=singlet_filter.h5ad_filtered, 
    cell_donor_assignments=donorassignment.assignments, 
  }

  output {
    File cell_donor_map=run_cbc_modify.cell_donor_map
    File cell_group_map=run_cbc_modify.cell_group_map
    File h5ad=run_cbc_modify.h5ad_renamed
  }

}
