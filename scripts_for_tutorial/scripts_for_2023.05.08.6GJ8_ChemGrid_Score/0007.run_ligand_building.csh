#!/bin/csh
# script by Stanley Tan and Trent Balius, 2023/05/16
# This is a modification of already existing scripts.
# This script calls chimera's dockprep function and addh function.

set mountdir = `pwd`

# CHANGE THIS.
#setenv DOCKBASE "/home/baliuste/zzz.github/DOCK"
#setenv DOCKBASE "/home/baliuste/zzz.github/dock6_10_merge/rizzo_branch/"
setenv DOCK6BASE "/home/baliuste/zzz.github/dock6_10_merge/rizzo_branch/"


set workdir = ${mountdir}/chimera_lig/db2_build/

if -e $workdir then
  echo "$workdir exists, skipping ... "
  exit
endif

mkdir -p $workdir
cd $workdir


cp ../lig_complete.mol2 .

source ~/zzz.programs/openbabel/env.csh

#bash $DOCKBASE/
bash $DOCK6BASE/template_pipeline/hdb_lig_gen/generate/build_ligand_charged_mol2_with_dock6.sh lig_complete.mol2

# this file can be used with rigid and flex sampling methods to do flex, rigid and fixed-anchor 
#   docking and single point and minimization on the xtal pose

 cat output.mol2 >> lig_solv.mol2
 echo "@<TRIPOS>SOLVATION" >> lig_solv.mol2
 cat output.solv >> lig_solv.mol2



