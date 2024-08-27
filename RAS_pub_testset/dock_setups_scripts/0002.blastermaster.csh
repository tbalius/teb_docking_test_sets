#!/bin/csh 

# This script runs Ryan's blastermaster python masterscript for generating everything that dock needs, i.e. grids, spheres
# Run on sgehead as jobs are submitted to the queue
# source ~/.tcshrc.python2
#source /home/baliuste/.cshrc.python3
#source /home/baliuste/.cshrc.DOCK_dev
echo "source /home/baliuste/.bashrc.python3"
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

set workdir = ${mountdir}/002.blastermaster/${pdbname}_${ligname}/rec_no_cof

  if ( -s $workdir ) then
     echo "$workdir exists... continue"
     continue
  endif

mkdir -p $workdir
cd $workdir

#set rec = ${mountdir}/../002.copy_man_mod_for_docking/${pdbname}_${ligname}/rec_complete.pdb 
#set lig = ${mountdir}/../002.copy_man_mod_for_docking/${pdbname}_${ligname}/lig_complete.pdb 

set rec = ${mountdir}/../003.files_for_docking/${pdbname}_${ligname}/rec_complete.pdb 
set lig = ${mountdir}/../003.files_for_docking/${pdbname}_${ligname}/lig_complete.pdb 

cat $rec | grep -v "GDP" | grep -v "GTP"| grep -v "GCP"| grep -v "GNP" | grep -v "GSP" | sed -e 's/HETATM/ATOM  /g' | grep "ATOM" > rec.pdb  

set ligfile = $lig

cat $ligfile | grep "HETATM" | sed -e 's/HETATM/ATOM  /g'> xtal-lig.pdb

#cat xtal-lig_ori.pdb | awk '{if ($1 == "ATOM" || $1 == "HETATM"){print $0}}' | sed -e "s/HETATM/ATOM  /g"  >  xtal-lig.pdb

rm -f  qsub.csh
# the following lines create a qsub script which submits blastermaster to the queue
cat <<EOF > qsub.csh
#!/bin/csh
#SBATCH -t 4:00:00
#SBATCH --output=stderr

cd $workdir/
# this is the modifed blastermaster script in which the user can specify a manually protonated file
# and it also can be used for tarting (making residues more polar). 
$DOCKBASE/proteins/blastermaster/blastermaster.py --addhOptions=" -HIS -FLIPs "  -v 
EOF

#qsub qsub.csh 
sbatch qsub.csh 

end # pdb
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
