#!/bin/csh

set mountdir = `pwd`
set scriptdir = /mnt/projects/RAS-CompChem/static/Stanley/decoy_gen/scripts
set workdir = ${mountdir}/assign_pmd
#set ligand_file = $1

if !(-e ${mountdir}/ligands.smi) then
  echo "Error, cannot find ligands.smi ..."
  exit
endif

if (-e $workdir) then
  echo "Error, $workdir exists ..."
  exit
endif

mkdir $workdir
cd $workdir

ls ${mountdir}/ligands.smi
cp ${mountdir}/ligands.smi .

ls ${mountdir}/self_sim/decoys.self_dissim.all.smi
cp ${mountdir}/self_sim/decoys.self_dissim.all.smi .

cat << EOF > assign_decoys.csh
#!/bin/csh
python ${scriptdir}/assign_decoys_to_ligands.py ligands.smi decoys.self_dissim.all.smi ${mountdir} decoys > assign_decoys.log
EOF

sbatch assign_decoys.csh

