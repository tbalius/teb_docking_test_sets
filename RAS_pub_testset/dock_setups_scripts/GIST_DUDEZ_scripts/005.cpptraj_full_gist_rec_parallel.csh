#!/bin/csh
# TEB/ MF comments -- March2017

## This script runs GIST with MPI. It
# 1) calculates the c.o.m. of the aligned ligand to use those coords as gist box center
# 2) reads in all frames (1-5000) of each trajectory
# 3) makes a GIST box of 40x40x40 voxels with a gridspacing of 0.50A aka a box with the dimensions of 20A in xyz directions.
# 4) submits 1 job to queue and runs ccptraj (with input script we created)

#setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber18
#set AMBERHOME = /home/baliuste/zzz.programs/amber/amber22_ambertools23/amber22

module load openmpi/4.1.5
module load cuda/10.2

set AMBERHOME = /mnt/projects/RAS-CompChem/static/Mayukh/amber22_install/amber22
set CPPTRAJ_MPI = /mnt/projects/RAS-CompChem/static/Mayukh/cpptraj_mpi/
source ${AMBERHOME}/amber.csh

set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts

set pwd = `pwd`

set list = `cat ../systems.txt | sed 's/ /./g'`
# loop over systems
foreach pdbsys ( $list )

set pdb    = ${pdbsys:r}
set system = ${pdbsys:e}

echo $pdb $system

set filedir = ${pwd}/0002.MDrun_rec/${system}
set workdir = ${pwd}/0005.full_gist_rec/${system}

if (-e $workdir) then
   echo "$workdir exists"
   continue
endif

mkdir -p $workdir
cd $workdir

set jobId = `grep '/tmp/tanys' ${filedir}/stdout | head -1 | awk -F\/ '{print $4}'`
ln -s ${filedir}/${jobId} .

set parm = rec.watbox.leap.prm7

#copy scripts from web
#curl http://docking.org/~tbalius/code/for_dock_3.7/mol2.py > mol2.py
#curl http://docking.org/~tbalius/code/for_dock_3.7/mol2_center_of_mass.py > mol2_center_of_mass.py
cp ${pwd}/0004.align_to_md/${system}/lig_aligned.mol2 .
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
#SBATCH --gres=gpu:2
#SBATCH --cpus-per-task=36
#SBATCH --output=stdout

cd $workdir

set OMP_NUM_THREADS=36

$CPPTRAJ_MPI/bin/cpptraj -i gist.in > ! gist.log

EOF

#csh qsub_fullgist.csh &  # you should run in screen or use nohub
#nohub csh qsub_fullgist.csh &
#qsub qsub_fullgist.csh
sbatch qsub_fullgist.csh

#/nfs/soft/amber/amber14/bin/cpptraj -i gist.in > ! gist.log &

end # system

