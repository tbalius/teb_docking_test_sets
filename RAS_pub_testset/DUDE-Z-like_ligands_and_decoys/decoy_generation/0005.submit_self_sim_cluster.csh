#!/bin/csh

set mountdir = `pwd`
set ChemInfTools = /home/baliuste/zzz.github/ChemInfTools
set scriptdir = /mnt/projects/RAS-CompChem/static/Stanley/decoy_gen/scripts
set workdir = ${mountdir}/self_sim

if (-e $workdir) then
  echo "Error, $workdir exists ..."
  exit
endif

mkdir $workdir
cd $workdir

cat ${mountdir}/lig_*_dir/decoys.lig_dissim.smi > decoys.lig_dissim.all.smi

#set tc_coeff_threshold = $1						  # Tanimoto coefficient threshold, smaller threshold results in larger clusters, recommended 0.5-0.8
set tc_coeff_threshold = 0.5						  # Tanimoto coefficient threshold, smaller threshold results in larger clusters, recommended 0.5-0.8
set max_clusters = `wc -l decoys.lig_dissim.all.smi | awk '{print $1}'`   # Maximum number of clusters, set to length of smiles file to process all molecules

touch self_sim.log

cat << EOF > self_sim.csh
#!/bin/csh
python ${scriptdir}/make_smiles_file_names_different.py decoys.lig_dissim.all.smi decoys.lig_dissim.all.smi
python ${ChemInfTools}/utils/teb_chemaxon_cheminf_tools/generate_rdkit_fingerprints.py decoys.lig_dissim.all.smi decoys.fp				>> self_sim.log
${ChemInfTools}/utils/Tc_c_tool/best_first_clustering/best_first_clustering decoys.fp decoys.lig_dissim.all.smi ${tc_coeff_threshold} ${max_clusters}	>> self_sim.log
python ${scriptdir}/write_cluster_heads_smiles.py cluster_head.list decoys.lig_dissim.all.smi decoys							>> self_sim.log
EOF

sbatch self_sim.csh

