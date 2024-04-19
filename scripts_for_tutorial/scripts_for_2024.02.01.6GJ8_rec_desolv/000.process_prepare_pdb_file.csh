#!/bin/csh

echo "source /home/baliuste/zzz.programs/amber/amber22_ambertools23/amber22/amber.sh"

setenv DOCK6BASE "/home/baliuste/zzz.github/dock6_10_merge/rizzo_branch"

set pwd = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts
set workdir = ${pwd}/00.process_prepare_pdb_file

# check if workdir exists
if ( -s $workdir ) then
   echo "$workdir exists"
   exit
endif

mkdir -p ${workdir}
cd ${workdir}

# download the file from the web.
wget https://files.rcsb.org/download/6GJ8.pdb --no-check-certificate

# put standard residues in the rec.pdb file.
grep "ATOM   " 6GJ8.pdb | sed '1d' > rec.pdb

# put non-standard residues (Mg ion) in the temp.pdb file.
grep "HETATM " 6GJ8.pdb | sed '1d' > temp.pdb

# change the "HETATM" line starter to "ATOM  ".
sed -i 's/HETATM/ATOM  /g' temp.pdb

# put the BI-2853 in the xtal-lig.pdb file.
grep "F0K" temp.pdb > xtal-lig.pdb

# put the GTP analog in the cof.pdb file.
grep "GCP" temp.pdb > cof.pdb

# change the name to GTP.
sed -i 's/GCP/GTP/g' cof.pdb

# put the magnesium ion in the rec.pdb file.
grep "MG" temp.pdb >> rec.pdb

# remove temp.pdb file. 
rm temp.pdb

# remove alternate sidechain conformations
cat << EOF > remove_pdb_alt_confs.py
import sys

filein  = sys.argv[1]
fileout = sys.argv[2]

with open(filein) as fi:
    filelines = fi.readlines()

with open(fileout,'w') as fo:
    for line in filelines:
        if line[16] == ' ' or line[16] == 'A':
            newline = line[:16] + ' ' + line[17:]
            fo.write(newline)
EOF

python remove_pdb_alt_confs.py rec.pdb temp.pdb
mv rec.pdb rec.pdb.old
mv temp.pdb rec.pdb

# Reduce is used to protonate the receptor
set reduce = /home/baliuste/zzz.programs/DOCK/proteins/Reduce/reduce

$reduce -HIS -FLIPs rec.pdb | grep "^ATOM" | cut -c 1-78 >> rec_complete.pdb

# Chimera AddH is used to protonate the cofactor and ligand
set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.17.3_oel8/bin/ # CHANGE ME.

touch chimera.log
$chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py cof.pdb cof_addh ' ' "             >> chimera.log
$chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py xtal-lig.pdb xtal-lig_addh ' ' "   >> chimera.log
# chimera_addh.py script is available in the teb_scripts_programs repository

# fix cofactor broken h
foreach file (`ls cof_addh.pdb`)
  echo $file
  grep "^HETATM" $file > temp.pdb
  sed -i 's/H3  GTP A 203      13.546  31.611   0.432  1.00  0.00           H/HN1 GTP A 203      16.813  29.728   2.042  1.00  0.00           H/g' temp.pdb
  mv temp.pdb $file
end

# combine protonated receptor and cofactor
grep "ATOM  " rec_complete.pdb                           >  rec_cof_complete.pdb
grep "HETATM" rec_complete.pdb | sed 's/HETATM/ATOM  /g' >> rec_cof_complete.pdb
echo "TER"                                               >> rec_cof_complete.pdb
grep "HETATM" cof_addh.pdb | sed 's/HETATM/ATOM  /g'     >> rec_cof_complete.pdb

#python /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts/renumber_pdb_continues_del_chain_name.py rec_cof_complete.pdb 0 rec_cof_complete.new_num
# script available in teb_scripts_programs repository

mkdir ${workdir}/amber_cof_parm
cd ${workdir}/amber_cof_parm

cp ../cof_addh.pdb ./cof.pdb

set charge = "-4.0"

cat << EOF > submit.csh
#!/bin/csh
#SBATCH -t 4:00:00
#SBATCH --output=stderr

$AMBERHOME/bin/antechamber -i cof.pdb -fi pdb -o cof.ante.mol2 -fo mol2
$AMBERHOME/bin/antechamber -dr no -i cof.ante.mol2 -fi mol2 -o cof.ante.charge.mol2 -fo mol2 -c bcc -at sybyl -nc ${charge}
$AMBERHOME/bin/antechamber -dr no -i cof.ante.mol2 -fi mol2  -o cof.ante.pdb  -fo pdb
$AMBERHOME/bin/antechamber -dr no -i cof.ante.charge.mol2 -fi mol2  -o cof.ante.charge.prep -fo prepi
$AMBERHOME/bin/parmchk2 -dr no -i cof.ante.charge.prep -f  prepi -o cof.ante.charge.frcmod
EOF

sbatch submit.csh

mkdir ${workdir}/db_build_working
cd ${workdir}/db_build_working

cp ${workdir}/xtal-lig_addh.mol2 lig_complete.mol2

cat << EOF > submit_build_lig.csh
#!/bin/csh
#SBATCH --output=stderr

source /home/baliuste/zzz.programs/openbabel/env.csh

bash $DOCK6BASE/template_pipeline/hdb_lig_gen/generate/build_ligand_charged_mol2_with_dock6.sh lig_complete.mol2

# this file can be used with rigid and flex sampling methods to do flex, rigid and fixed-anchor 
#   docking and single point and minimization on the xtal pose

cat output.mol2 >> lig_solv.mol2
echo "@<TRIPOS>SOLVATION" >> lig_solv.mol2
cat output.solv >> lig_solv.mol2

python /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts/mol2_replace_sybyl_with_ele.py lig_solv.mol2 lig_solv_ele.mol2
python /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts/mol2_removeH_all.py lig_solv_ele.mol2 lig_solv_ele_noH.mol2
EOF

sbatch submit_build_lig.csh

