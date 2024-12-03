#!/bin/csh

set mountdir = `pwd`
set ChemInfTools = /home/baliuste/zzz.github/ChemInfTools
set scriptdir = /mnt/projects/RAS-CompChem/static/Stanley/decoy_gen/scripts
#set ligand_file = $1

if !(-e ${mountdir}/ligands.smi) then
  echo "Error, cannot find ligands.smi ..."
  exit
endif

foreach file (`ls lig_?????`)

if !(-e ${mountdir}/${file}_dir) then
  echo "Error, ${file}_dir does not exist ..."
  continue
endif

cd ${mountdir}/${file}_dir
cp ${mountdir}/ligands.smi .

touch lig_sim.log

#cat << EOF > lig_sim.csh
##!/bin/csh
##SBATCH --partition=norm-oel8
#python ${scriptdir}/ligand_sim/ligand_sim.py ligands.smi decoys_matched.all.smi decoys >> lig_sim.log
#EOF

cat << EOF > lig_sim.csh
#!/bin/csh
python ${ChemInfTools}/utils/teb_chemaxon_cheminf_tools/generate_rdkit_fingerprints.py ligands.smi ligands.fp		>> lig_sim.log
python ${ChemInfTools}/utils/teb_chemaxon_cheminf_tools/generate_rdkit_fingerprints.py decoys_matched.all.smi decoys.fp	>> lig_sim.log
${ChemInfTools}/utils/Tc_c_tool/cal_Tc_matrix/cal_Tc_matrix decoys.fp decoys_matched.all.smi ligands.fp ligands.smi	>> lig_sim.log
python ${scriptdir}/ligand_sim/ligand_sim_Tc_c_tool.py Max_Tc_col decoys_matched.all.smi decoys				>> lig_sim.log
EOF

sbatch lig_sim.csh

end

