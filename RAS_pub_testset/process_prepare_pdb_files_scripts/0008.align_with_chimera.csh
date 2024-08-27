#!/bin/csh 
## this script was written by Trent Balius in the Rizzo Group, 2011
## modified in the Shoichet Group, 2013-2015
## modified at FNLCR 2022

# TEB, MF comments -- March 2017

# This shell script will do the following:
# (1) aligns the ligand file and cofactor for docking and cross docking

#set chimerapath = "/home/baliuste/zzz.programs/Chimera/chimera-1.13.1/bin/chimera"
set chimerapath = "/home/baliuste/zzz.programs/Chimera/chimera-1.17.3_oel8/bin/chimera"
set mountdir = `pwd`

set pdbref = "6GJ8_F0K"
echo $pdbref

set ref = "/mnt/projects/RAS-CompChem/static/Stanley/RAS_pub_testset/KRAS/001.process_prepare_pdb_files/001_pdb_breaker/${pdbref}/rec.pdb" # CHANGE THIS
ls $ref

if ! (-e $ref) then
   echo "$ref does not exist ..."
   exit
endif

#set list = `cat pdb_lig_map.txt | awk '{print $1}'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
set list = `cat pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo $pdbname
echo $ligname

set workdir  = $mountdir/008_align/${pdbname}_${ligname}
echo $workdir

if (-e $workdir) then 
    echo "$workdir exists... continue to next pdb"
    continue
endif

mkdir -p $workdir
cd $workdir

set rec = "${mountdir}/005_chimera_dockprep_cofori/${pdbname}_${ligname}/rec_complete.mol2"                         # the receptor given to tleap
#set lig = "${mountdir}/005_chimera_dockprep_cofori/${pdbname}_${ligname}/lig_complete.mol2"                         # ligand in the same frame as rec 
set lig = "${mountdir}/006_chimera_dockprep_noncovalent_lig_ante/${pdbname}_${ligname}/lig_complete.mol2"           # ligand in the same frame as rec 

if (-e ${mountdir}/../002.prepared_by_hand/${pdbname}_${ligname}/rec_complete.mol2) then
   set rec = "${mountdir}/../002.prepared_by_hand/${pdbname}_${ligname}/rec_complete.mol2"
endif

if (-e ${mountdir}/../002.prepared_by_hand/${pdbname}_${ligname}/lig_complete.mol2) then
   set lig = "${mountdir}/../002.prepared_by_hand/${pdbname}_${ligname}/lig_complete.mol2"
endif

set cov = 'F'
if (-e ${mountdir}/007_chimera_dockprep_covalent_lig_ante/${pdbname}_${ligname}/covlig_complete_du.mol2 || -e ${mountdir}/../002.prepared_by_hand/${pdbname}_${ligname}/covlig_complete_du.mol2) then
   echo "covlig_complete_du.mol2 exists ...  so align the covalent ligand."
   set cov = 'T'
endif

# if there is a covalent ligand
if ($cov == 'T') then
   set covsph = ${mountdir}/005_chimera_dockprep_cofori/${pdbname}_${ligname}/cov_sph.pdb
   set covlig = "${mountdir}/007_chimera_dockprep_covalent_lig_ante/${pdbname}_${ligname}/covlig_complete_du.mol2"     # ligand (covalent) in the same fram as rec 
   if (-e ${mountdir}/../002.prepared_by_hand/${pdbname}_${ligname}/cov_sph.pdb) then
      set covsph = ${mountdir}/../002.prepared_by_hand/${pdbname}_${ligname}/cov_sph.pdb
   endif
   if (-e ${mountdir}/../002.prepared_by_hand/${pdbname}_${ligname}/covlig_complete_du.mol2) then
      set covlig = "${mountdir}/../002.prepared_by_hand/${pdbname}_${ligname}/covlig_complete_du.mol2"
   endif
endif

set count = 3

# if there is a covalent ligand
if ($cov == 'T') then
   set count = 5
endif

touch chimera.load_cof.com
touch chimera.align_cof.com
touch chimera.write_cof.com
#foreach file (`ls ${mountdir}/../002.copy_man_mod_for_docking/${pdbname}_${ligname}/cof.*.ante.charge.mol2`)
ls $mountdir/004_chimera_cofactor_q/${pdbname}_${ligname}/cof/cof.ante.charge.mol2
set count_cof = 1
foreach file (`ls $mountdir/004_chimera_cofactor_q/${pdbname}_${ligname}/cof/cof.ante.charge.mol2`)

if (-e $mountdir/../002.prepared_by_hand/${pdbname}_${ligname}/cof.ante.charge.mol2) then
   set cof = $mountdir/../002.prepared_by_hand/${pdbname}_${ligname}/cof.ante.charge.mol2
else
   set cof = $file
endif

set name = ${file:t:r}

echo $name $count

cat << EOF >> chimera.load_cof.com
open $file
EOF

cat << EOF >> chimera.align_cof.com
matrixcopy #1 #$count
EOF

if ("$count_cof" == 1) then
cat << EOF >>chimera.write_cof.com
write format mol2  $count $name.aligned.mol2
write format pdb  $count $name.aligned.pdb
EOF
else
cat << EOF >>chimera.write_cof.com
write format mol2  $count $name.${count_cof}.aligned.mol2
write format pdb  $count $name.${count_cof}.aligned.pdb
EOF
endif

@ count = $count + 1
@ count_cof = $count_cof + 1
end
#exit


#write instruction file for chimera based alignment
cat << EOF > chimera.com
# template #0
open $ref 
# rec #1
open $rec
# xtal-lig
open $lig
EOF

if ($cov == 'T') then
cat << EOF >> chimera.com
# cov-lig
open $covlig
# cov spheres
open $covsph
EOF
endif

cat chimera.load_cof.com >> chimera.com

cat << EOF >> chimera.com
# move pdb to ref. 
mmaker #0 #1 
# move ligands
matrixcopy #1 #2
EOF

if ($cov == 'T') then
cat << EOF >> chimera.com
matrixcopy #1 #3
matrixcopy #1 #4
EOF
endif

cat chimera.align_cof.com >> chimera.com

cat << EOF >> chimera.com
write format pdb   0 ref.pdb
write format mol2  1 rec_complete_aligned.mol2
write format pdb   1 rec_complete_aligned.pdb
write format mol2  2 lig_complete_aligned.mol2
write format pdb   2 lig_complete_aligned.pdb
EOF

# if there is a covalent ligand
if ($cov == 'T') then
cat << EOF >> chimera.com
write format mol2  3 covlig_complete_du_aligned.mol2
write format pdb   4 cov_sph_aligned.pdb
EOF
endif

cat chimera.write_cof.com >> chimera.com

${chimerapath} --nogui chimera.com > & chimera.com.out

end
