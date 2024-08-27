#!/bin/csh

set pwd = `pwd`

#set mountdir = ${pwd}/../002.copy_man_mod_for_docking
set mountdir = ${pwd}/../003.files_for_docking

#set list = `cat pdb_lig_map.txt | awk '{print $1}'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
set list = `cat pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo $pdbname
echo $ligname

set workdir = ${mountdir}/${pdbname}_${ligname}

if (-e $workdir) then
   echo "$workdir exists ..."
   rm -r $workdir
endif

mkdir -p $workdir
cd $workdir

# receptor
cp $pwd/008_align/${pdbname}_${ligname}/rec_complete_aligned.mol2 rec_complete.mol2 
cp $pwd/008_align/${pdbname}_${ligname}/rec_complete_aligned.pdb rec_complete.pdb

if (-e $pwd/008_align/${pdbname}_${ligname}/cov_sph_aligned.pdb) then
  cp $pwd/008_align/${pdbname}_${ligname}/cov_sph_aligned.pdb cov_sph.pdb 
endif

# ligand
cp $pwd/008_align/${pdbname}_${ligname}/lig_complete_aligned.mol2 lig_complete.mol2 
cp $pwd/008_align/${pdbname}_${ligname}/lig_complete_aligned.pdb lig_complete.pdb 

if (-e $pwd/007_chimera_dockprep_covalent_lig_ante/${pdbname}_${ligname}/covlig_complete_du.mol2) then
  cp $pwd/007_chimera_dockprep_covalent_lig_ante/${pdbname}_${ligname}/covlig_complete_du.mol2 .
  cp $pwd/007_chimera_dockprep_covalent_lig_ante/${pdbname}_${ligname}/covlig_complete.mol2 .
endif

cp $pwd/006_chimera_dockprep_noncovalent_lig_ante/${pdbname}_${ligname}/lig_complete.mol2 lig_complete_ante.mol2

# check 002.prepared_by_hand
if (-e $pwd/../002.prepared_by_hand/${pdbname}_${ligname}) then
  if (-e $pwd/../002.prepared_by_hand/${pdbname}_${ligname}/covlig_complete_du.mol2) then
    cp $pwd/../002.prepared_by_hand/${pdbname}_${ligname}/covlig_complete_du.mol2 .
    cp $pwd/../002.prepared_by_hand/${pdbname}_${ligname}/covlig_complete.mol2 .
  endif
  if (-e $pwd/../002.prepared_by_hand/${pdbname}_${ligname}/lig_complete.mol2) then
    cp $pwd/../002.prepared_by_hand/${pdbname}_${ligname}/lig_complete.mol2 lig_complete_ante.mol2
  endif
endif

# cofactor

# copy aligned
foreach coffile (`ls $pwd/008_align/${pdbname}_${ligname}/cof.ante.charge*.aligned.pdb $pwd/008_align/${pdbname}/cof.ante.charge*.aligned.mol2`)
  cp $coffile .
end

# copy before aligned
set count = 1
foreach coffile (`ls $pwd/004_chimera_cofactor_q/${pdbname}_${ligname}/cof/cof.ante.charge.mol2`) 
 cp $coffile cof.$count.ante.charge.mol2

 echo ${coffile:r:r}
 #exit
 ls ${coffile:r:r}.pdb 
 cp ${coffile:r:r}.pdb cof.$count.ante.pdb

 if !(-e ${workdir}/amber_cof_parm) then
   mkdir ${workdir}/amber_cof_parm
 endif

 cd ${workdir}/amber_cof_parm
 #cp $pwd/004_chimera_cofactor_q/${pdbname}_${ligname}/cof.$count/cof.ante.charge.prep cof.$count.ante.charg.prep
 #cp $pwd/004_chimera_cofactor_q/${pdbname}_${ligname}/cof.$count/cof.ante.charge.frcmod cof.$count.ante.charg.frcmod
 cp $pwd/004_chimera_cofactor_q/${pdbname}_${ligname}/cof/cof.ante.charge.prep cof.$count.ante.charg.prep
 cp $pwd/004_chimera_cofactor_q/${pdbname}_${ligname}/cof/cof.ante.charge.frcmod cof.$count.ante.charg.frcmod

 @ count = $count + 1
end # cof

if (-e $pwd/../002.prepared_by_hand/${pdbname}_${ligname}/cof.ante.charge.mol2) then
   cp $pwd/../002.prepared_by_hand/${pdbname}_${ligname}/cof.ante.charge.mol2 ${workdir}/cof.1.ante.charge.mol2
   cp $pwd/../002.prepared_by_hand/${pdbname}_${ligname}/cof.ante.charge.prep ${workdir}/amber_cof_parm/cof.1.ante.charg.prep
   cp $pwd/../002.prepared_by_hand/${pdbname}_${ligname}/cof.ante.charge.frcmod ${workdir}/amber_cof_parm/cof.1.ante.charg.frcmod
endif

end # pdblig

echo "I AM HERE"

