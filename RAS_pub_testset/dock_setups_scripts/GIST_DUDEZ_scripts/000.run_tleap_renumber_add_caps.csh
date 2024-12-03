#!/bin/csh
# This script uses first reduce and then tleap to prepare a receptor for amber.
# The outputs are: parameter topology file (prm7) and a coordinate file (rst7) 
#
# Written by Trent balius
# TEB/ MF comments Feb2017

echo "source /home/baliuste/.bashrc.python3"

set pwd = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts 
set filedir = /mnt/projects/RAS-CompChem/static/Stanley/RAS_pub_testset/KRAS ## modify this line!

set list = `cat ../systems.txt | sed -e 's/ /./g'`
foreach pdbsys ( $list )

set pdb    = ${pdbsys:r}
set system = ${pdbsys:e}

echo $pdb $system

set workdir = ${pwd}/0000.tleap_renum_add_caps/${system}

# check if workdir exists
if ( -s $workdir ) then
   echo "$workdir exists ... "
   continue
endif

mkdir -p ${workdir}
cd ${workdir}

#cp /mnt/projects/RAS-CompChem/static/work/DUDEZ/dudez_dockprep/${system}_dock6prep/blastermaster/working/rec.pdb .
cp /mnt/projects/RAS-CompChem/static/work/DUDEZ/dudez_dockprep/${system}_dock6prep/blastermaster/working/rec.crg.pdb .
cp /mnt/projects/RAS-CompChem/static/work/DUDEZ/dudez_dockprep/${system}_dock6prep/blastermaster/working/xtal-lig.pdb .

mv rec.crg.pdb rec.crg.pdb_ori
cat rec.crg.pdb_ori | grep -v OXT > rec.crg.pdb

# produces tleap input file -- renumbers rec
cat << EOF >! tleap.rec.in
set default PBradii mbondi2
# load the protein force field
source leaprc.protein.ff14SB
source leaprc.water.tip3p
# load ions
loadAmberParams frcmod.ions234lm_1264_tip3p

REC = loadpdb rec.crg.pdb

saveamberparm REC rec.leap.prm7 rec.leap.rst7
quit
EOF

$AMBERHOME/bin/tleap -s -f tleap.rec.in > ! tleap.rec.out
$AMBERHOME/bin/ambpdb -p rec.leap.prm7 < rec.leap.rst7 >! rec.leap.pdb 

#cp rec.leap.pdb rec.pdb
cat rec.leap.pdb | grep -v OXT > rec.pdb

# remove extra atom
if ($system == "TRYB1") then
   mv rec.pdb rec.pdb_ori
   cat rec.pdb_ori | grep -v "LYS . 258" > rec.pdb
endif

# remove extra atom
if ($system == "GLCM") then
   mv rec.pdb rec.pdb_ori
   cat rec.pdb_ori | grep -v "LEU A 498" > rec.pdb
endif

cat rec.pdb | grep -v 'H$' | grep -v 'H $' | grep -v 'H  $' > rec_noH.pdb

#grep -E "Mg|Ca|Zn" rec_noH.pdb > ion.pdb
#cat rec_noH.pdb | grep -v -E "Mg|Ca|Zn" > rec.1.pdb
grep -E 'MG  $|CA  $|ZN  $' rec_noH.pdb > ion.pdb
cat rec_noH.pdb | grep -v -E 'MG  $|CA  $|ZN  $' > rec.1.pdb

python ${scriptdir}/add.ters.py rec.1.pdb rec.2.pdb           >> add_caps.log
python ${scriptdir}/add_capping_group.py rec.2.pdb rec_capped >> add_caps.log

cp rec_capped.pdb rec_complete.pdb
cat ion.pdb >> rec_complete.pdb

end # system

