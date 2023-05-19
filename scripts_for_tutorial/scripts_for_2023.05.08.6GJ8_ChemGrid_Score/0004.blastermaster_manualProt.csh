#!/bin/csh 

# This script runs Ryan's blastermaster python masterscript for generating everything that dock needs, i.e. grids, spheres
# Run on sgehead as jobs are submitted to the queue

set mountdir = `pwd`

set workdir = ${mountdir}/blastermaster_cof

setenv DOCKBASE "/home/baliuste/zzz.github/DOCK"

# if exists then do not over write. 
if ( -s $workdir ) then
  echo "$workdir exists.  stop ..."
  exit
endif

mkdir $workdir 
cd $workdir

# receptor and MG ions
ls ../rec_no_cof/working/rec.crg.pdb
# add in the cofactor to the receptor file.  
cat ../rec_no_cof/working/rec.crg.pdb ../chimera/cof/cof.pdb | sed -e 's/HETATM/ATOM  /g' > rec.crg.pdb  
# we need both rec.crg.pdb and rec.pdb to run blastermaster in the add-no-h mode. 
cat ../rec_no_cof/rec.pdb ../chimera/cof/cof.pdb | grep -v ' H$' | sed -e 's/HETATM/ATOM  /g' > rec.pdb  
# we also need the experimental ligand. 
cat ../rec_no_cof/xtal-lig.pdb > xtal-lig.pdb  

# we need the path to teb_scripts_programs available on github. 
set TEB_SCRIPTS_PATH = ~baliuste/zzz.github/teb_scripts_programs

# we creat a copy of the prot.table and amb.crg.oxt files.  
 cp $DOCKBASE/proteins/defaults/prot.table.ambcrg.ambH  $DOCKBASE/proteins/defaults/amb.crg.oxt . 
 chmod u+w prot.table.ambcrg.ambH amb.crg.oxt  

# we need to add in the cofactor parameters into the copies of prot.table and amb.crg.oxt. 
#   The python script will grab the partial charges from the mol2 and will look up vdw parameters an create temp.prot.table and temp.amb.crg.oxt. 
#   we can then cat them onto the end of the copied parameter files.  
 python ${TEB_SCRIPTS_PATH}/zzz.scripts/mol2toDOCK37type.py ../chimera/cof/cof.ante.charge.mol2 temp

 cat temp.prot.table.ambcrg.ambH >> prot.table.ambcrg.ambH
 cat temp.amb.crg.oxt >>  amb.crg.oxt


rm -f  qsub.csh
# the following lines create a qsub script which submits blastermaster to the queue
# we run blastermaster in add-no-h mode and give it parameter files that contain parameters for the cofactor. 
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
# csh qsub


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
