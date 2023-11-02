#!/bin/csh
# script by Stanley Tan and Trent Balius, 2023/05/16
# This is a modification of already existing scripts. 
# This script calls chimera's dockprep function and addh function.   

set mountdir = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts

setenv DOCKBASE "/home/baliuste/zzz.github/DOCK"

set protein = ${mountdir}/rec.pdb
set cof1 =  ${mountdir}/cof.pdb

set workdir = ${mountdir}/chimera

if -e $workdir then
  echo "$workdir exists, skipping ... "
  continue
endif
mkdir -p $workdir
cd $workdir

#set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.13.1/bin/ # CHANGE ME.  Replace this with your chimera location.
set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.17.3_oel8/bin/ # CHANGE ME.  Replace this with your chimera location.

#cat $protein $ions > rec.pdb
cat $protein > rec.pdb
cat $cof1 > cof.pdb


touch chimera.log

$chimerapath/chimera --nogui --script "${scriptdir}/chimera_dockprep.py rec.pdb rec_complete  "         >> chimera.log
$chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py cof.pdb cof_addh ' ' "                 >> chimera.log

echo " Check the protonation state for the cofactor is correct.  Sometimes the wrong N is protonated. "
echo " If the protonation state is wrong then modify and run 0002p5.fix_broken_h.csh. "

