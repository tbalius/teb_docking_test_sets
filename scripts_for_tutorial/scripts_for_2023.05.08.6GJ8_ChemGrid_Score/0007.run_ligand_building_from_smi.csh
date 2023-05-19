#!/bin/csh
# script by Stanley Tan and Trent Balius, 2023/05/16
# This is a modification of already existing scripts.
# This script calls chimera's dockprep function and addh function.

set mountdir = `pwd`

#setenv DOCKBASE "/home/baliuste/zzz.github/DOCK"
#setenv DOCKBASE "/home/baliuste/zzz.github/dock6_10_merge/rizzo_branch/"
setenv DOCK6BASE "/home/baliuste/zzz.github/dock6_10_merge/rizzo_branch/"



set workdir = ${mountdir}/db2_build_from_smi/

if -e $workdir then
  echo "$workdir exists, skipping ... "
  exit
endif

mkdir -p $workdir
cd $workdir

set ligname = "F0K"

curl https://files.rcsb.org/ligands/view/${ligname}_ideal.sdf | grep -A1 SMILES | tail -1 | awk '{print $0, "'${ligname}'"}' > ${ligname}.smi


csh $DOCK6BASE/template_pipeline/hdb_lig_gen/generate/build_ligand_simple_with_dock6.csh ${ligname}.smi 

# this file can be used with rigid and flex sampling methods to do flex, rigid and fixed-anchor 
#   docking and single point and minimization on the xtal pose

#exit

# #cat output.mol2 >> lig_solv.mol2
# cat db2_build_from_smi/db_build_working/${ligname}/${ligname}_0_output.mol2 >> lig_solv.mol2
# echo "@<TRIPOS>SOLVATION" >> lig_solv.mol2
# #cat output.solv >> lig_solv.mol2
# cat db2_build_from_smi/db_build_working/${ligname}/${ligname}_0_output.solv >> lig_solv.mol2

# we need to loop over all of the files. 
 cd ${workdir}/db_build_working/${ligname}/
 foreach file (`ls ${ligname}_*_output.mol2`)
     ls -l
     set fileroot = $file:r
     echo $fileroot
     cat ${fileroot}.mol2      >> ${fileroot}_lig_solv.mol2
     echo "@<TRIPOS>SOLVATION" >> ${fileroot}_lig_solv.mol2
     cat ${fileroot}.solv      >> ${fileroot}_lig_solv.mol2

