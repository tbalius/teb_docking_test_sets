# TEB/ MF comments -- March2017

## This script runs GIST. It
# 1) calculates the c.o.m. of the aligned ligand to use those coords as gist box center
# 2) reads in all frames (1-5000) of each trajectory
# 3) makes a GIST box of 40x40x40 voxels with a gridspacing of 0.50A aka a box with the dimensions of 20A in xyz directions.
# 4) submits 1 job to queue and runs ccptraj (with input script we created)

#setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber18
set AMBERHOME = /home/baliuste/zzz.programs/amber/amber22_ambertools23/amber22
source ${AMBERHOME}/amber.csh

set pwd = `pwd`

set list = `cat $1 | sed 's/ /_/g'`
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )
echo $pdblig

set mountdir = ${pwd}/${pdblig}
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts
set workdir  = $mountdir/05a.full_gist_rec

set parm = rec.watbox.leap.prm7

if (-e $workdir) then
   echo "$workdir exists"
   #rm -rf $workdir
   continue
endif

mkdir -p $workdir
cd $workdir

set jobId = `grep '/tmp/' ${mountdir}/02.MDrun_rec/stdout | head -1 | awk -F\/ '{print $4}'`
ln -s ${mountdir}/02.MDrun_rec/${jobId} .

#copy scripts from web
#curl http://docking.org/~tbalius/code/for_dock_3.7/mol2.py > mol2.py
#curl http://docking.org/~tbalius/code/for_dock_3.7/mol2_center_of_mass.py > mol2_center_of_mass.py
cp ${mountdir}/04.align_to_md/lig_aligned.mol2 .
python3 $scriptdir/mol2_center_of_mass.py lig_aligned.mol2 centermol.txt

set center = `cat centermol.txt`
#set griddim = "64 64 64"
set griddim = "100 100 100"

#parm rec.wat.leap.prm7 
#rec_w_h means with hydrogens added with reduces.
## reads in trajectories from 1 to 5000 (10k is picked since > 5000).
## for grid dimensions look at dock grid box 
#gist doorder gridcntr ${center} griddim 64 64 64 gridspacn 0.50 
#parm rec.watbox.leap.prm7 
#parm ${jobId}/lig.watbox.leap.prm7

#trajin ${jobId}/10md.mdcrd 1 10000
#trajin ${jobId}/11md.mdcrd 1 10000
#trajin ${jobId}/12md.mdcrd 1 10000
#trajin ${jobId}/13md.mdcrd 1 10000
#trajin ${jobId}/14md.mdcrd 1 10000
#trajin ${jobId}/15md.mdcrd 1 10000
#trajin ${jobId}/16md.mdcrd 1 10000
#trajin ${jobId}/17md.mdcrd 1 10000
#trajin ${jobId}/18md.mdcrd 1 10000

cat << EOF >! gist.in
parm ${jobId}/${parm}
trajin ${jobId}/09md.mdcrd 1 10000
gist doorder gridcntr ${center} griddim ${griddim} gridspacn 0.50
go
EOF
#gist doorder doeij gridcntr 35.759163 33.268703 31.520596 griddim 40 40 40 gridspacn 0.50 out gist.out

cat << EOF > qsub_fullgist.csh
#!/bin/tcsh
#SBATCH -t 72:00:00
#SBATCH -p gpu
#SBATCH --gres=gpu:1
#SBATCH --output=stdout

cd $workdir

$AMBERHOME/bin/cpptraj -i gist.in > ! gist.log

EOF

#qsub qsub_fullgist.csh
#csh qsub_fullgist.csh &  # you should run in screen or use nohub
sbatch qsub_fullgist.csh
#nohub csh qsub_fullgist.csh &

#/nfs/soft/amber/amber14/bin/cpptraj -i gist.in > ! gist.log &

end #pdb

