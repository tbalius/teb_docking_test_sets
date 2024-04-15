#!/bin/csh
# script by Stanley Tan and Trent Balius, 2023/05/16
# This is a modification of already existing scripts. 
# This script calls chimera's dockprep function and addh function.   

set mountdir = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts # CHANGE ME.

setenv DOCKBASE "/home/baliuste/zzz.github/DOCK" # CHANGE ME.  Replace this with your DOCK 3 location.

set lig =  ${mountdir}/lig.pdb

set workdir = ${mountdir}/chimera_lig

if -e $workdir then
  echo "$workdir exists, skipping ... "
  continue
endif

mkdir -p $workdir
cd $workdir

#set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.13.1/bin/ # CHANGE ME.  Replace this with your chimera location.
set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.17.3_oel8/bin/ # CHANGE ME.  Replace this with your chimera location.

#cat $protein $ions > rec.pdb
cat $lig > lig.pdb


touch chimera.log

# this script is available in teb_scripts_programs repository
$chimerapath/chimera --nogui --script "${scriptdir}/chimera_dockprep.py lig.pdb lig_complete  "         >> chimera.log

echo " Check the protonation state for the cofactor is correct.  "

