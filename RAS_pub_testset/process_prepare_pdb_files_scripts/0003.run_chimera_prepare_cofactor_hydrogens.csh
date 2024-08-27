#!/bin/csh

set mountdir = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts
set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.17.3_oel8/bin

#foreach pdb ( $pdblist )
#set list = `cat pdb_lig_map.txt | awk '{print $1}'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
set list = `cat pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo $pdbname
echo $ligname

set workdir = ${mountdir}/003_chimera_cofactor_h/${pdbname}_${ligname}
set filedir = ${mountdir}/002_pick_receptor_ligand_cofactor_ions/${pdbname}_${ligname}_sel_cof_ions

if (-e $workdir) then
   echo "$workdir exists. skipping ... "
   continue
endif

mkdir -p $workdir
cd $workdir

set chainid = `head -1 $filedir/xtal-lig.pdb | cut -c 21-22`

set charge = "-4.0"
set count = 1
#foreach file (`ls $filedir/lig*aligned.pdb`)
#foreach file (`ls $filedir/lig.*.pdb`)
foreach file (`ls $filedir/lig.*.pdb $filedir/pep.*.pdb`)

echo $count

if (`head -1 $file | cut -c 21-22` == $chainid) then

if ("`grep -c GNP $file`" != "0") then
   set cof_file = GNP_cof.pdb
   cp $file GNP_cof.pdb 
   $chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py ${cof_file} cof.$count no"         >> chimera.log
@ count = $count + 1
endif

if ("`grep -c GCP $file`" != "0") then
   set cof_file = GCP_cof.pdb
   cp $file GCP_cof.pdb 
   $chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py ${cof_file} cof.$count no"         >> chimera.log
@ count = $count + 1
endif

if ("`grep -c GSP $file`" != "0") then
   set cof_file = GSP_cof.pdb
   cp $file GSP_cof.pdb 
   $chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py ${cof_file} cof.$count no"         >> chimera.log
@ count = $count + 1
endif

if ("`grep -c GTP $file`" != "0") then
   set cof_file = GTP_cof.pdb
   cp $file GTP_cof.pdb 
   $chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py ${cof_file} cof.$count no"         >> chimera.log
@ count = $count + 1
endif

if ("`grep -c GDP $file`" != "0") then
   set cof_file = GDP_cof.pdb
   cp $file GDP_cof.pdb 
   set charge = "-3.0"
   $chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py ${cof_file} cof.$count no"         >> chimera.log
@ count = $count + 1
endif

endif

end

# this will allow us to manually add a h to the cofactor.
# if there exists a man_H for this ligand

grep "^HETATM" ${cof_file} > cof.pdb

if (-e ${mountdir}/man_H/cof/${pdbname}_${ligname}_cof_man_H.pdb) then
   cat ${mountdir}/man_H/cof/${pdbname}_${ligname}_cof_man_H.pdb >> cof.pdb
endif

$chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py cof.pdb cof keepH"         >> chimera.log

# automate an common issue:
# sometimes the phosphates are protonated.
# remove incorrect hydrogens.
cp cof.pdb cof.pdb.ori
if ("`grep -c GNP cof.pdb.ori`" != "0") then
   cat cof.pdb.ori  | \
   #grep -v "  H1B " | grep -v "  H2B " | grep -v "  H3B " | \
   grep -v "  H1G " | grep -v "  H2G " | grep -v "  H3G " | \
   sed -e 's/HETATM/ATOM  /g' | grep "^ATOM" > cof.pdb
else
   cat cof.pdb.ori  | \
   grep -v "  H1B " | grep -v "  H2B " | grep -v "  H3B " | \
   grep -v "  H1G " | grep -v "  H2G " | grep -v "  H3G " | \
   grep -v " HOA2 " | grep -v " HOB2 " | grep -v " HOG2 " | grep -v " HOG3 " | \
   sed  -e 's/HETATM/ATOM  /g'  | grep "^ATOM" > cof.pdb
endif

end

