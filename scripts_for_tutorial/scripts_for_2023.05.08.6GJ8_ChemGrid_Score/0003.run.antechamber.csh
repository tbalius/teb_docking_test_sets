#!/bin/csh

# This script is modified by Trent Balius. 
# This script runs Amber's AnteChamber.  

set mountdir = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts

set charge = -4  # MODIFY ME.  This is the formal charge of the cofactor.  For GTP and GTP analogs.

set workdir = ${mountdir}/chimera
cd $workdir


#setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber18  # CHANGE ME.  Replace this with your amber or ambertools location.  
setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber22_ambertools23/amber22  # CHANGE ME.  Replace this with your amber or ambertools location.  


#rm -r cof; 
mkdir cof; cd cof

grep HETATM $workdir/cof_GTP_addh.pdb > cof.pdb  # MODIFY ME.  This  is the name and path to the protonated cofactor. 

touch antechamber.log

$AMBERHOME/bin/antechamber -i cof.pdb -fi pdb -o cof.ante.mol2 -fo mol2 >> antechamber.log
$AMBERHOME/bin/antechamber -i cof.ante.mol2 -fi mol2 -o cof.ante.charge.mol2 -fo mol2 -c bcc -at sybyl -nc ${charge} -s 2 >> antechamber.log
$AMBERHOME/bin/antechamber -i cof.ante.mol2 -fi mol2  -o cof.ante.pdb  -fo pdb >> antechamber.log
$AMBERHOME/bin/antechamber -i cof.ante.charge.mol2 -fi mol2  -o cof.ante.charge.prep -fo prepi >> antechamber.log
$AMBERHOME/bin/parmchk2 -i cof.ante.charge.prep -f  prepi -o cof.ante.charge.frcmod >> antechamber.log

#end
