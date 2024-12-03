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

set list = `cat ../systems.txt | sed -e 's/ /./g'`
foreach pdbsys ( $list )

set pdb    = ${pdbsys:r}
set system = ${pdbsys:e}

echo $pdb $system

set filedir = ${pwd}/0000.tleap_renum_add_caps/${system}
set workdir = ${pwd}/0001.tleap_reduce_min/${system}

# check if workdir exists
if (-e $workdir) then
   echo "$workdir exists ... "
   continue
endif

mkdir -p ${workdir}
cd ${workdir}

#cp /mnt/projects/RAS-CompChem/static/work/DUDEZ/dudez_dockprep/${system}_dock6prep/blastermaster/working/rec.crg.pdb .
#cp /mnt/projects/RAS-CompChem/static/work/DUDEZ/dudez_dockprep/${system}_dock6prep/blastermaster/working/xtal-lig.pdb .

cp ${filedir}/rec_complete.pdb ./rec.1.pdb
cp ${filedir}/xtal-lig.pdb .

$DOCKBASE/proteins/Reduce/reduce -Trim rec.1.pdb > rec.2.pdb  # this step should remove Hydrogens
$DOCKBASE/proteins/Reduce/reduce -HIS -FLIPs rec.2.pdb >! rec.3.pdb  # this step should add Hydrogens

cat rec.3.pdb | grep "^ATOM" > rec.nowat.1his.pdb

#python3 $scriptdir/replace_his_with_hie_hid_hip.py rec.nowat.reduce_clean.pdb rec.nowat.1his.pdb
python3 $scriptdir/replace_cys_to_cyx.py rec.nowat.1his.pdb rec.nowat.2cys.pdb
python3 $scriptdir/add.ters.py rec.nowat.2cys.pdb rec.nowat.3ter.pdb

cp rec.nowat.3ter.pdb rec_premin.pdb

# produces tleap input file -- renumbers rec
cat << EOF >! tleap.rec.in
set default PBradii mbondi2
# load the protein force field
source leaprc.protein.ff14SB
source leaprc.water.tip3p
# load ions
loadAmberParams frcmod.ions234lm_1264_tip3p

REC = loadpdb rec_premin.pdb

saveamberparm REC rec_premin.leap.prm7 rec_premin.leap.rst7
quit
EOF

$AMBERHOME/bin/tleap -s -f tleap.rec.in > ! tleap.rec.out
$AMBERHOME/bin/ambpdb -p rec_premin.leap.prm7 < rec_premin.leap.rst7 >! rec_premin.leap.pdb 

set restraint_mask = "!:NME & !:ACE"

if ($system == "ACES") then
   set restraint_mask = "!:NME & !:ACE & !(:86,466 & !@CA,C,O,N)"
endif

cat << EOF1 > ! 01mi.in
01mi.in: minimization with GAS
&cntrl
 imin = 1, maxcyc = 1000000, ntmin = 2, drms=1e-3,
 igb=6,
 ntx = 1, ntc = 1, ntf = 1,
 ntb = 0, ntp = 0,
 ntxo=1, ntwx = 1000, ntwe = 0, ntpr = 1000,
 cut = 999.9,
 ntr = 1,
 restraintmask = '!@H= & ${restraint_mask}',
 restraint_wt = 10.0,
/
EOF1

# produces tleap input file -- renumbers rec
cat << EOF >! tleap.rec2.in
set default PBradii mbondi2
# load the protein force field
source leaprc.protein.ff14SB
source leaprc.water.tip3p
# load ions
loadAmberParams frcmod.ions234lm_1264_tip3p

REC = loadpdb rec_min.pdb

EOF

if (-e rec.nowat.2cys.pdb.for.leap ) then
  cat rec.nowat.2cys.pdb.for.leap >> tleap.rec.in
endif

cat << EOF >>! tleap.rec2.in
saveamberparm REC rec.leap.prm7 rec.leap.rst7
solvateBox REC TIP3PBOX 10.0
saveamberparm REC rec.watbox.leap.prm7 rec.watbox.leap.rst7
quit
EOF

cat << EOF > ! submit.csh
#!/bin/tcsh
#SBATCH -t 48:00:00
#SBATCH -p gpu
#SBATCH --gres=gpu:1
#SBATCH --output=stdout

  set CUDA_VISIBLE_DEVICES = 0

  $AMBERHOME/bin/pmemd.cuda -O -i 01mi.in -o 01mi.out -p rec_premin.leap.prm7 -c rec_premin.leap.rst7 -ref rec_premin.leap.rst7 -x 01mi.mdcrd -inf 01mi.info -r 01mi.rst7

  $AMBERHOME/bin/ambpdb -p rec_premin.leap.prm7 < 01mi.rst7 >! rec_min.pdb 

  # runs tleap and converts parameter and coordinate restart file back into pdb file
  $AMBERHOME/bin/tleap -s -f tleap.rec2.in > ! tleap.rec2.out
  $AMBERHOME/bin/ambpdb -p rec.leap.prm7 < rec.leap.rst7 >! rec.leap.pdb 

EOF

  #sbatch qsub.sander.csh
  sbatch submit.csh

echo "Look at rec.leap.pdb in pymol. May have to delete last column in pdb file for pymol. "
# may have to remove element column so pymol does not get confused
# inspect tleap.rec.out and the leap.log file
# visually inspect (VMD) rec.10wat.leap.prm7, rec.10wat.leap.rst7 and rec.watbox.leap.prm7, rec.watbox.leap.rst7

end # system
