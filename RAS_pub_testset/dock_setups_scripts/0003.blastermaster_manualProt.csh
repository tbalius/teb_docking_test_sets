#!/bin/csh 

# This script runs Ryan's blastermaster python masterscript for generating everything that dock needs, i.e. grids, spheres
# Run on sgehead as jobs are submitted to the queue
#source ~/.tcshrc.python2
#source /home/baliuste/.cshrc.python3
#source /home/baliuste/.cshrc.DOCK_dev
echo "source /home/balisute/.bashrc.python3"
echo "source /home/baliuste/.bashrc.DOCK_dev"

set mountdir = `pwd`

# list is same as in 0001... script 
#set list = `cat pdb_lig_map.txt | awk '{print $1}'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
#set list = `cat pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
set list = `cat ../001.process_prepare_pdb_files/pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo $pdbname
echo $ligname

#set workdir = ${mountdir}/${pdbname}_${ligname}
#set workdir = ${mountdir}/0005.blastermaster/${pdbname}_${ligname}/rec_no_cof
set workdir = ${mountdir}/003.blastermaster_manualProt/${pdbname}_${ligname}/blastermaster_cof

# checks that 001 ran successfully and produced the directory structure as expected
# if not stops with current pdb code and continues with next one in list
  if ( -s $workdir ) then
     echo "$workdir exists... continue"
     continue
  endif

mkdir -p $workdir
cd $workdir


 set TEB_SCRIPTS_PATH = /home/baliuste/zzz.github/teb_scripts_programs

 cp $DOCKBASE/proteins/defaults/prot.table.ambcrg.ambH  $DOCKBASE/proteins/defaults/amb.crg.oxt . 


 #set cof_filelist = `ls ${mountdir}/004_chimera_cofactor_prep_multi_charge/$pdb/cof.*/cof.ante.charge.mol2`
 #set cof_mol2 = `ls ${mountdir}/../002.copy_man_mod_for_docking/${pdbname}_${ligname}/cof.1.ante.charge.mol2`
 #set cof_pdbfilelist = `ls ${mountdir}/../002.copy_man_mod_for_docking/${pdbname}_${ligname}/cof.*.ante.pdb`
 set cof_mol2 = `ls ${mountdir}/../003.files_for_docking/${pdbname}_${ligname}/cof.1.ante.charge.mol2`
 set cof_pdbfilelist = `ls ${mountdir}/../003.files_for_docking/${pdbname}_${ligname}/cof.ante.charge*.aligned.pdb`

echo $cof_pdbfilelist

# ${mountdir}/002.blastermaster/${pdbname}_${ligname}/rec_no_cof 
if !( -e ${mountdir}/002.blastermaster/${pdbname}_${ligname}/rec_no_cof/working/rec.crg.pdb ) then
    echo " ${workdir}/../rec_no_cof/working/rec.crg.pdb does not exist... continue"
    continue
endif

cat ${mountdir}/002.blastermaster/${pdbname}_${ligname}/rec_no_cof/working/rec.crg.pdb $cof_pdbfilelist | \
sed -e 's/ MG  . / MG    /g' \
    -e 's/ GNP . / GNP   /g' \
    -e 's/ GCP . / GCP   /g' \
    -e 's/ GSP . / GSP   /g' \
    -e 's/ GTP . / GTP   /g' \
    -e 's/ GDP . / GDP   /g' \
    -e 's/HETATM/ATOM  /g' \
| grep -v END \
| grep "^ATOM " \
> rec.crg_ori_num.pdb  

#cat ../rec_no_cof/rec.pdb ../chimera/cof/cof.pdb | \
cat ${mountdir}/002.blastermaster/${pdbname}_${ligname}/rec_no_cof/rec.pdb $cof_pdbfilelist | \
sed -e 's/ MG  . / MG    /g' \
    -e 's/ GNP . / GNP   /g' \
    -e 's/ GCP . / GCP   /g' \
    -e 's/ GSP . / GSP   /g' \
    -e 's/ GTP . / GTP   /g' \
    -e 's/ GDP . / GDP   /g' \
    -e 's/HETATM/ATOM  /g' \
| grep -v END \
> rec_ori_num.pdb  

python /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts/renumber_pdb_continues_del_chain_name.py rec.crg_ori_num.pdb 0 rec.crg_new_num
python /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts/renumber_pdb_continues_del_chain_name.py rec_ori_num.pdb 0 rec_new_num

ln -s rec.crg_new_num_1.pdb rec.crg.pdb
ln -s rec_new_num_1.pdb rec.pdb

 cat ${mountdir}/002.blastermaster/${pdbname}_${ligname}/rec_no_cof/working/xtal-lig.pdb > xtal-lig.pdb  
 python ${TEB_SCRIPTS_PATH}/zzz.scripts/mol2toDOCK37type.py $cof_mol2 temp

 cat temp.prot.table.ambcrg.ambH >> prot.table.ambcrg.ambH
 cat temp.amb.crg.oxt >>  amb.crg.oxt

#cat xtal-lig_ori.pdb | awk '{if ($1 == "ATOM" || $1 == "HETATM"){print $0}}' | sed -e "s/HETATM/ATOM  /g"  >  xtal-lig.pdb

rm -f  qsub.csh
# the following lines create a qsub script which submits blastermaster to the queue
cat <<EOF > qsub.csh
#!/bin/csh 
#SBATCH -t 4:00:00
#SBATCH --output=stderr

cd $workdir/
mkdir working
cp rec.crg.pdb working/rec.crg.pdb
# this is the modifed blastermaster script in which the user can spesify a manuly protonated file
# and it also can be used for tarting (making residues more polar). 
$DOCKBASE/proteins/blastermaster/blastermaster.py --addNOhydrogensflag --chargeFile=`pwd`/amb.crg.oxt --vdwprottable=`pwd`/prot.table.ambcrg.ambH -v
EOF

#qsub qsub.csh 
sbatch qsub.csh 

end # pdbname
# going to the next pdb

# this will produce two directories:
# 1) working - contains all input and output files that are generated; not needed afterwards but as a reference
# 2) dockfiles - contains everything that is needed to run dock (copied from working)
#    grids 
#    	trim.electrostatics.phi 
#    	vdw.vdw 
#    	vdw.bmp 
# 	ligand.desolv.heavy
# 	ligand.desolv.hydrogen
#    spheres
#    	matching_spheres.sph
