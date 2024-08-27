#!/bin/csh 

#source /home/baliuste/.cshrc.DOCK_dev
#source /home/baliuste/.cshrc.python3
echo "source /home/baliuste/.bashrc.DOCK_dev"
echo "source /home/baliuste/.bashrc.python3"

set mountdir = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts
set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.17.3_oel8/bin

#set list = `cat pdb_lig_map.txt | awk '{print $1}'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
set list = `cat pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo $pdbname
echo $ligname

#set filedir = ${mountdir}/001_pdb_breaker/${pdbname}_${ligname}
set filedir = ${mountdir}/002_pick_receptor_ligand_cofactor_ions/${pdbname}_${ligname}_sel_cof_ions
set workdir = ${mountdir}/005_chimera_dockprep_cofori/${pdbname}_${ligname}

if (-e $workdir) then
   echo "$workdir exists. skipping ... "
   continue
endif

mkdir -p $workdir
cd $workdir

#~/zzz.programs/Chimera/UCSF-Chimera64-1.13.1/bin/chimera --nogui --script "/home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts/chimera_dockprep.py 1L2S.pdb 1L2S_out"

set chainid = `head -1 $filedir/xtal-lig.pdb | cut -c 21-22`

# rec
#cat $filedir/rec.pdb | grep -v 'H$' | grep -v 'H $' | grep -v 'H  $' > rec.1.noh.pdb
foreach file (`ls $filedir/rec_?.pdb`)
if (`head -1 $file | cut -c 21-22` == $chainid) then
   cat $file | grep -v 'H$' | grep -v 'H $' | grep -v 'H  $' > rec.1.noh.pdb 
endif
end

# ions 
#cat $filedir/lig.*.pdb | grep "MG" >> rec.1.noh.pdb 
#cat $filedir/lig.*.pdb $filedir/pep.*.pdb | grep "MG" >> rec.1.noh.pdb 
foreach file (`ls $filedir/lig.*.pdb $filedir/pep.*.pdb`)
if (`head -1 $file | cut -c 21-22` == $chainid) then
   cat $file | grep -E "MG|CA" >> rec.1.noh.pdb 
endif
end

# lig
#cat $filedir/lig.*.pdb | grep -v 'H$' | grep -v 'H $' | grep -v 'H  $' > lig_ori.pdb
#cat $filedir/xtal-lig.pdb | grep -v 'H$' | grep -v 'H $' | grep -v 'H  $' > lig_ori.pdb
cat $filedir/xtal-lig.pdb | grep -v 'H$' | grep -v 'H $' | grep -v 'H  $' | grep "^ATOM" > lig_ori.pdb

head -1 lig_ori.pdb 
set name = `head -1 lig_ori.pdb | cut -c '17-21'`
set resnum = `head -1 lig_ori.pdb | cut -c '23-26'`
set chain = `head -1 lig_ori.pdb | cut -c '22-22'`
#set resnummod = `head -1 lig_ori.pdb | cut -c '24-26'`
echo "**$name**"
echo "**$resnum**"
echo "**$chain**"
#echo "**$resnummod**"

set string = `grep ${pdbname} ${mountdir}/pdb_covalent_bond_info.txt | grep -m1 $resnum | grep -v " MG" | sed -e 's/ /_/g'`
echo "string=**$string**"
#exit 
if ("$string" != "") then 
   echo $string
   echo $string | awk -F\; '{print $2}'
   set one_string = `echo $string | awk -F\; '{print $2}' | awk -F\- '{print $1}' | sed -e 's/_(//g' -e 's/)//g'`
   set two_string = `echo $string | awk -F\; '{print $2}' | awk -F\- '{print $3}' | sed -e 's/(//g' -e 's/)_//g'`
   set onename = `echo $one_string | awk -F, '{printf"%3s",$2}'`
   set twoname = `echo $two_string | awk -F, '{printf"%3s",$2}'`
   if "$onename" == "$name" then
        echo "one is ligand"
        set lig_string = "${one_string}"
        set rec_string = "${two_string}"
   else if "$twoname" == "$name" then
        echo "two is ligand"
        set rec_string = "${one_string}"
        set lig_string = "${two_string}"
   else
       echo "error"
       exit
   endif 
   echo "rec_string=$rec_string"
   echo "lig_string=$lig_string"
   #exit

   #set recgrepsearch = `echo $rec_string | awk -F, '{printf"%2s..%3s...%3s",$1,$2,$3}'`
   set recgrepsearch = `echo $rec_string | awk -F, '{printf"%2s..%3s...%3s",$1,$2,$3}'| sed -e 's/SG /SG/g'`
   set recname = `echo $rec_string | awk -F, '{printf"%3s",$2}'`
   set recnum = `echo $rec_string | awk -F, '{printf"%3s",$3}'`
   set recnumif = `echo $rec_string | awk -F, '{printf"%3s",$3}'| sed -e 's/_//g'`
   echo "recname=*$recname*"
   echo "recnum=*$recnum*"
   #exit
   set liggrepsearch = `echo $lig_string | awk -F, '{printf"%-3s.%3s..%3s",$1,$2,$3}' | sed -e 's/ /_/g'`
   echo "rec search = $recgrepsearch"
   echo "lig search = $liggrepsearch"
   #exit

   cat rec.1.noh.pdb | sed -e 's/HETATM/ATOM  /g' > rec_before_atom_removed.pdb
   grep -v "$recgrepsearch" rec_before_atom_removed.pdb > rec_removed.pdb

   if ("$recnumif" == "12") then
      python ${scriptdir}/replace_cys_to_ala.py rec_removed.pdb "$recname" " $recnumif" rec.2.pdb
      python ${scriptdir}/write_cys_to_sphers.py rec.1.noh.pdb "$recname" " $recnumif" "$chain" cov_sph.pdb
   else if ("$recnumif" == "72") then
      python ${scriptdir}/replace_cys_to_ala.py rec_removed.pdb "$recname" " $recnumif" rec.2.pdb 
      python ${scriptdir}/write_cys_to_sphers.py rec.1.noh.pdb "$recname" " $recnumif" "$chain" cov_sph.pdb
   else if ("$recnumif" == "70") then
      python ${scriptdir}/replace_cys_to_ala.py rec_removed.pdb "$recname" " $recnumif" rec.2.pdb 
      python ${scriptdir}/write_cys_to_sphers.py rec.1.noh.pdb "$recname" " $recnumif" "$chain" cov_sph.pdb
   else if ("$recnumif" == "39") then
      python ${scriptdir}/replace_cys_to_ala.py rec_removed.pdb "$recname" " $recnumif" rec.2.pdb 
      python ${scriptdir}/write_cys_to_sphers.py rec.1.noh.pdb "$recname" " $recnumif" "$chain" cov_sph.pdb
   else if ("$recnumif" == "32") then
      python ${scriptdir}/replace_cys_to_ala.py rec_removed.pdb "$recname" " $recnumif" rec.2.pdb 
      python ${scriptdir}/write_cys_to_sphers.py rec.1.noh.pdb "$recname" " $recnumif" "$chain" cov_sph.pdb
   else
      echo "$recnum != 12"
      echo "Error... add resnum to if statement... exiting..."
      exit
   endif
   mv lig_ori.pdb lig_before_atom_removed.pdb
   #grep -v "$liggrepsearch" lig_before_atom_removed.pdb > lig.pdb 
   echo $liggrepsearch | sed -e 's/_/ /g'
   #exit

   grep -v "`echo $liggrepsearch | sed -e 's/_/ /g'`" lig_before_atom_removed.pdb > lig.pdb 

else
  cp rec.1.noh.pdb rec.2.pdb
  cp lig_ori.pdb lig.pdb
  echo "not covalent"
endif

# this will allow us to manually add a h to the system.
# if there exists a man_H for this ligand
#if (-e ${mountdir}/man_H/lig/${pdbname}_${ligname}_lig_man_H.pdb ) then
#  cat ${mountdir}/man_H/lig/${pdbname}_${ligname}_lig_man_H.pdb >> lig.pdb
#endif

set cof_filelist = `ls ${mountdir}/004_chimera_cofactor_q/${pdbname}_${ligname}/cof*/cof.ante.charge.mol2`

cat << EOF > chimera.com
open rec_complete_no_cof.mol2
#open cof.mol2
#combine #0,1 modelId 2
open ${cof_filelist}
sel
combine sel modelId 100
write format mol2 100 rec_complete.mol2
write format pdb 100 rec_complete.pdb
EOF

#exit
#dos2unix rec.4.pdb
#$DOCKBASE/proteins/Reduce/reduce -HIS -FLIPs rec.2.pdb >! rec.pdb
#$chimerapath/chimera --nogui --script "${scriptdir}/chimera_dockprep.py rec.pdb rec_complete_no_cof"  >> chimera.log
#$chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py rec.pdb rec_complete"         >> chimera.log
#$chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py lig.pdb lig_complete"         >> chimera.log 
#cp ${mountdir}/004_chimera_cofactor_prep_charge/$pdb/cof.ante.charge.mol2 cof.mol2 

#continue

cat << EOF > submit.csh
#!/bin/csh
#SBATCH -t 4:00:00
#SBATCH --output=stderr

$DOCKBASE/proteins/Reduce/reduce -Trim rec.2.pdb > rec.3.pdb  # this step should remove Hydrogens
$DOCKBASE/proteins/Reduce/reduce -HIS -FLIPs rec.3.pdb >! rec.pdb  # this step should add Hydrogens

${chimerapath}/chimera --nogui --script "${scriptdir}/chimera_dockprep.py rec.pdb rec_complete_no_cof yes"  >> chimera.log # keepH is set to yes so H generated with reduce are not removed.  
${chimerapath}/chimera --nogui --script "${scriptdir}/chimera_dockprep.py lig.pdb lig_complete yes"     >> chimera.log # keepH is set to yes so man_H not removed.

${chimerapath}/chimera --nogui chimera.com > & chimera.com.out
EOF

sbatch submit.csh

#exit
end
