#!/bin/csh
# This script uses first reduce and then tleap to prepare a receptor for amber.
# The outputs are: parameter topology file (prm7) and a coordinate file (rst7) 
#
# Written by Trent balius
# TEB/ MF comments Feb2017

echo "source /home/baliuste/.bashrc.python2"
echo "source /home/baliuste/zzz.programs/amber/amber22_ambertools23/amber22/amber.sh"

#setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber18
setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber22_ambertools23/amber22
setenv DOCKBASE "/home/baliuste/zzz.github/DOCK"

# CUDA for GPU
#setenv LD_LIBRARY_PATH ""
#setenv LD_LIBRARY_PATH "/usr/local/cuda-6.0/lib64/:$LD_LIBRARY_PATH"

set pwd = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts 
set filedir = ${pwd}/00.process_prepare_pdb_file
set workdir = ${pwd}/01.tleap_reduce

# check if workdir exists
if ( -s $workdir ) then
   echo "$workdir exists"
   exit
endif

mkdir -p ${workdir}
cd ${workdir}

cp ${filedir}/rec_cof_complete.new_num.pdb ./rec.pdb
cp ${filedir}/xtal-lig_addh.pdb ./xtal-lig.pdb

#rm -f leap.log tleap.rec.out tleap.rec.in

## uncomment the next line to include xtal waters into simulation
#cp $filedir/nearby_waters_aligned.pdb water.pdb

# 1st: run leap to renumber residues.

# produces tleap input file -- renumbers rec
cat << EOF >! tleap.rec.1.in
set default PBradii mbondi2
# load the protein force field
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2
# load ions
loadAmberParams frcmod.ions234lm_1264_tip3p
# load cof
loadamberparams ${filedir}/amber_cof_parm/cof.ante.charge.frcmod
loadamberprep ${filedir}/amber_cof_parm/cof.ante.charge.prep

REC = loadpdb rec.pdb
saveamberparm REC rec.1.leap.prm7 rec.1.leap.rst7
quit
EOF

# runs tleap and converts parameter and coordinate restart file back into pdb file
$AMBERHOME/bin/tleap -s -f tleap.rec.1.in > ! tleap.rec.1.out
$AMBERHOME/bin/ambpdb -p rec.1.leap.prm7 < rec.1.leap.rst7 >! rec.1.leap.ori.pdb 

# Remove hydrogens before running leap.
grep -v ' H$' rec.1.leap.ori.pdb >! rec.1.leap.pdb

# nomenclature clean-up
$DOCKBASE/proteins/Reduce/reduce -HIS -FLIPs rec.1.leap.pdb >! rec.nowat.reduce.pdb
sed -i 's/HETATM/ATOM  /g' rec.nowat.reduce.pdb
grep "^ATOM  " rec.nowat.reduce.pdb | sed -e 's/   new//g' | sed 's/   flip//g' | sed 's/   std//g' | grep -v "OXT" | grep -v " 0......HEM" >! rec.nowat.reduce_clean.pdb


#curl docking.org/~tbalius/code/waterpaper2017/scripts/replace_his_with_hie_hid_hip.py > replace_his_with_hie_hid_hip.py
#curl docking.org/~tbalius/code/waterpaper2017/scripts/replace_cys_to_cyx.py > replace_cys_to_cyx.py
#curl docking.org/~tbalius/code/waterpaper2017/scripts/add.ters.py > add.ters.py


# python scripts do these three things: 1) checks his to give protonation specific names; 2) checks for disulphide bonds; 3) checks for missing residues and adds TER flag
python3 $scriptdir/replace_his_with_hie_hid_hip.py rec.nowat.reduce_clean.pdb rec.nowat.1his.pdb
python3 $scriptdir/replace_cys_to_cyx.py rec.nowat.1his.pdb rec.nowat.2cys.pdb
python3 $scriptdir/add.ters.py rec.nowat.2cys.pdb rec.nowat.3ter.pdb

cp rec.nowat.3ter.pdb rec.nowat.final.pdb

cat << EOF >! tleap.rec.in 
set default PBradii mbondi2
# load the protein force field
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2
# load ions
loadAmberParams frcmod.ions234lm_1264_tip3p
# load cof
loadamberparams ${filedir}/amber_cof_parm/cof.ante.charge.frcmod
loadamberprep ${filedir}/amber_cof_parm/cof.ante.charge.prep

EOF

if (-e rec.nowat.2cys.pdb.for.leap ) then
  cat rec.nowat.2cys.pdb.for.leap >> tleap.rec.in
endif

cat << EOF >> tleap.rec.in
REC = loadpdb rec.nowat.final.pdb

saveamberparm REC rec.leap.prm7 rec.leap.rst7
solvateBox REC TIP3PBOX 10.0
saveamberparm REC rec.watbox.leap.prm7 rec.watbox.leap.rst7
quit
EOF

$AMBERHOME/bin/tleap -s -f tleap.rec.in > ! tleap.rec.out

# for ease of visualization in pymol 
$AMBERHOME/bin/ambpdb -p rec.leap.prm7 < rec.leap.rst7 > rec.leap.pdb

echo "Look at rec.leap.pdb in pymol. May have to delete last column in pdb file for pymol. "
# may have to remove element column so pymol does not get confused
# inspect tleap.rec.out and the leap.log file
# visually inspect (VMD) rec.10wat.leap.prm7, rec.10wat.leap.rst7 and rec.watbox.leap.prm7, rec.watbox.leap.rst7
