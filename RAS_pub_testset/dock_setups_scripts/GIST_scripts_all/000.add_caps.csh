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

set list = `cat $1 | sed 's/ /_/g'`
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )
echo $pdblig

set mountdir = ${pwd}/${pdblig}
set workdir = ${mountdir}/00.add_caps

# check if workdir exists
if ( -s $workdir ) then
   echo "$workdir exists"
   #exit
   continue
endif

mkdir -p ${workdir}
cd ${workdir}

cp ${filedir}/004.dock_setups/003.blastermaster_manualProt/${pdblig}/blastermaster_cof/working/rec.crg.pdb ${mountdir}
cp ${filedir}/004.dock_setups/003.blastermaster_manualProt/${pdblig}/blastermaster_cof/working/rec.pdb ${mountdir}
cp ${filedir}/004.dock_setups/003.blastermaster_manualProt/${pdblig}/blastermaster_cof/working/xtal-lig.pdb ${mountdir}

#cat ${filedir}/004.dock_setups/003.blastermaster_manualProt/${pdblig}/blastermaster_cof/working/rec.crg.pdb | grep -v OXT > rec_ori.pdb

#grep -v OXT ${mountdir}/rec.crg.pdb > rec_ori.pdb

grep -E "ATOM|HETATM" ${filedir}/003.files_for_docking/${pdblig}/rec_complete.pdb | grep -v OXT > rec_ori.pdb

#cat rec_ori.pdb | grep -v MG | grep -v CA | grep -v GNP | grep -v GCP | grep -v GSP | grep -v GTP | grep -v GDP > rec_no_cof.pdb
cat rec_ori.pdb | grep -v HETATM > rec_no_cof.pdb

python ${scriptdir}/add.ters.py rec_no_cof.pdb rec_no_cof.2.pdb
python ${scriptdir}/add_capping_group.py rec_no_cof.2.pdb rec_no_cof_capped

head -n-2 rec_no_cof_capped.pdb | tail -n+2 > rec_capped.pdb
#grep MG rec_ori.pdb >> rec_capped.pdb
grep "HETATM" rec_ori.pdb | grep -E "MG|CA" >> rec_capped.pdb
#grep -E "GNP|GCP|GSP|GTP|GDP" rec_ori.pdb >> rec_capped.pdb
grep -E "GNP|GCP|GSP|GTP|GDP" rec_ori.pdb | grep -v 'H$' >> rec_capped.pdb

cat rec_capped.pdb | sed -e 's/HIE/HIS/g' -e 's/HID/HIS/g' -e 's/HIP/HIS/g' > rec_capped_mod.pdb

python /mnt/projects/RAS-CompChem/static/Stanley/scripts/add_ter_before_cof.py rec_capped_mod.pdb rec_complete.pdb

end #pdb

