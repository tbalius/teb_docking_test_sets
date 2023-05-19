#!/bin/csh
# script by Stanley Tan and Trent Balius, 2023/05/16
# This is a modification of already existing scripts. 
# This script calls chimera's dockprep function and addh function.   

set mountdir = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts

setenv DOCKBASE "/home/baliuste/zzz.github/DOCK"

set lig =  ${mountdir}/lig.pdb

set workdir = ${mountdir}/chimera_lig

if -e $workdir then
  echo "$workdir exists, skipping ... "
  continue
endif
mkdir -p $workdir
cd $workdir

set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.13.1/bin/

#cat $protein $ions > rec.pdb
cat $lig > lig.pdb


touch chimera.log

$chimerapath/chimera --nogui --script "${scriptdir}/chimera_dockprep.py lig.pdb lig_complete  "         >> chimera.log

echo " Check the protonation state for the cofactor is correct.  "

