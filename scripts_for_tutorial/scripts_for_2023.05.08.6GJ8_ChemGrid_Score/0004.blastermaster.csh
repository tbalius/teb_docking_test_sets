#!/bin/csh 

# This script is by Trent Balius. began in ~2014 and continuously modified with contubutions by others. 
# This script runs Ryan's blastermaster python masterscript for generating everything that dock needs, i.e. grids, spheres
# Run on a cluster as jobs are submitted to the queue


set mountdir = `pwd`


set workdir = ${mountdir}/rec_no_cof
setenv DOCKBASE "/home/baliuste/zzz.github/DOCK" # CHANGE ME.  Replace this with your DOCK 3 location.

# if exists then do not over write.
if ( -s $workdir ) then
  echo "$workdir exists.  stop ..."
  exit
endif

mkdir $workdir 
cd $workdir

# receptor and MG ions
cat ../chimera/rec_complete_noH.pdb | sed -e 's/HETATM/ATOM  /g' > rec.pdb  

# experimental ligand
cat ../lig.pdb | sed -e 's/HETATM/ATOM  /g' > xtal-lig.pdb

rm -f  qsub.csh
# the following lines create a qsub script which submits blastermaster to the queue
cat <<EOF > qsub.csh
#!/bin/csh 
#SBATCH -t 4:00:00
#SBATCH --output=stderr

cd $workdir/
# this is the modifed blastermaster script in which the user can spesify a manuly protonated file
# and it also can be used for tarting (making residues more polar). 
$DOCKBASE/proteins/blastermaster/blastermaster.py --addhOptions=" -HIS -FLIPs "  -v 
EOF

#qsub qsub.csh  # for sge or pbs 
sbatch qsub.csh  # for slurm
# csh qsub.csh  # for running on front-end-node. 

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
