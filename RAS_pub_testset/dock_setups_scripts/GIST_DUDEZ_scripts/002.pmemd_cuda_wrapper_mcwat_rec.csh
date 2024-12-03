#!/bin/csh
# TEB/ MF comments Feb2017
#
# This script writes a submission script to run amber MD on a GPU cluster.

set pwd = `pwd`

set list = `cat ../systems.txt | sed 's/ /./g'`
# loop over systems
foreach pdbsys ( $list )

set pdb    = ${pdbsys:r}
set system = ${pdbsys:e}

echo $pdb $system

set filedir = ${pwd}/0001.tleap_reduce_min/${system}
set workdir = ${pwd}/0002.MDrun_rec/${system}

if (-e $workdir) then 
  echo "warning: ${workdir} exists . . ."
  #echo "kill with control c."
  #pause(10)
  continue
endif

mkdir -p $workdir
cd $workdir

# restrain all protein residues and cofactor
set end = `grep ^ATOM $filedir/rec.leap.pdb | tail -1 | awk '{print $5}'`
set restraint_mask = ":1-$end"
set nameprefix     = "rec.watbox.leap"

# writing submission script
cat << EOF >! qsub.amber.csh
#!/bin/tcsh
#SBATCH -t 72:00:00
#SBATCH -p gpu
#SBATCH --gres=gpu:1
#SBATCH --output=stdout

#setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber18
setenv AMBERHOME /mnt/projects/RAS-CompChem/static/Mayukh/amber22_install/amber22
#source /home/baliuste/.cshrc.amber
source \${AMBERHOME}/amber.sh

#set amberexe = "/nfs/ge/bin/on-one-gpu - \$AMBERHOME/bin/pmemd.cuda"
set amberexe = "\${AMBERHOME}/bin/pmemd.cuda"

hostname
#csh ${pwd}/pickGPU.csh
#source ${pwd}/pickGPU.csh
echo \${CUDA_VISIBLE_DEVICES}

## make a local directory on the server to run calculations
## those will be copied over to /nfs at the end of the script
#set SCRATCH_DIR = /scratch
set SCRATCH_DIR = /tmp
if ! (-d \$SCRATCH_DIR ) then
    SCRATCH_DIR=/tmp
endif
set username = `whoami`

## queue assigns job_id
set TASK_DIR = "\$SCRATCH_DIR/\${username}/\${SLURM_JOB_ID}"
echo \$TASK_DIR

mkdir -p \${TASK_DIR}
cd \${TASK_DIR}
pwd

cp ${filedir}/${nameprefix}.* .

## parameters to add if writing NetCDF -- for production run not visualization (VMD)
# ioutfm=1, # write out NetCDF trajectory
# ntxo = 2, # write out NetCDF restart
# ntrx = 2, # read in NetCDF restart
## we didn't because VMD does not read it in (NetCDF is small in size and has more significant figures).


## equilibration run 01mi-02mi and 01md-08md (see details in comments below)
## production run starts at 09md


## 01mi and 02mi minimize all Hs and waters, restraint in kcal/mol/A^2
cat << EOF1 > ! 01mi.in
01mi.in: equil minimization with very strong Cartesian restraints
&cntrl
   imin=1, maxcyc=3000, ncyc = 1500, 
   ntpr=100, 
   ntr=1, 
   restraint_wt=100.0, 
   restraintmask= '${restraint_mask} & !@H'
/
EOF1

cat << EOF1 > ! 02mi.in
02mi.in: equil minimization with strong Cartesian restraints
&cntrl
   imin=1, maxcyc=3000, ncyc = 1500, 
   ntpr=100, 
   ntr=1, 
   restraint_wt=5.0, 
   restraintmask= '${restraint_mask} & !@H'
/
EOF1

## 01md-06md 	-- constant volume simulations, gradually heating up by 50K within each of the 6 steps (6x 20ps)
## 07md		-- const pressure, allow box dimensions to adjust
## 08md 	-- const vol, same conditions as production (5ns more equilibration time)

cat << EOF1 > ! 01md.in
01md.in: equilibration, constant volume, temp ramp from 0 to 50K, runs for 20ps (10000 steps); 1step=2femtoseconds.
&cntrl
   imin=0, irest=0, ntx=1, nstlim = 10000,
   ntt=3, tempi=0.0, temp0=50.0, gamma_ln=2.0, ig = 1234,
   ntp=0, taup=2.0, 
   ntb=1, ntc=2, ntf=2, 
   ntwx=500, ntpr=500, dt = 0.002, 
   ntr = 1, iwrap=1, 
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1

cat << EOF1 > ! 02md.in
02md.in: equilibration, constant volume,temp ramp from 50 to 100K, runs for 20ps (10000 steps) 
&cntrl
   imin=0, irest=1, ntx=5, nstlim = 10000,
   ntt=3, tempi=50.0, temp0=100.0, gamma_ln=2.0, ig = 2345,
   ntp=0, taup=2.0, 
   ntb=1, ntc=2, ntf=2, 
   ntwx=500, ntpr=500, dt = 0.002,
   ntr = 1, iwrap=1,
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1

cat << EOF1 > ! 03md.in
03md.in: equilibration, constant volume, temp ramp from 100 to 150K, runs for 20ps (10000 steps)
&cntrl
   imin=0, irest=1, ntx=5, nstlim = 10000,
   ntt=3, tempi=100.0, temp0=150.0, gamma_ln=2.0, ig = 3456,
   ntp=0, taup=2.0, 
   ntb=1, ntc=2, ntf=2, 
   ntwx=500, ntpr=500, dt = 0.002,
   ntr = 1, iwrap=1,
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1

cat << EOF1 > ! 04md.in
04md.in: equilibration, constant volume, temp ramp from 150 to 200K, runs for 20ps (10000 steps)
&cntrl
   imin=0, irest=1, ntx=5, nstlim = 10000,
   ntt=3, tempi=150.0, temp0=200.0, gamma_ln=2.0, ig = 4567,
   ntp=0, taup=2.0, 
   ntb=1, ntc=2, ntf=2, 
   ntwx=500, ntpr=500, dt = 0.002,
   ntr = 1, iwrap=1,
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1

cat << EOF1 > ! 05md.in
05md.in: equilibration, constant volume, temp ramp from 200 to 250K, runs for 20ps (10000 steps)
&cntrl
   imin=0, irest=1, ntx=5, nstlim = 10000,
   ntt=3, tempi=200.0, temp0=250.0, gamma_ln=2.0, ig = 5678,
   ntp=0, taup=2.0, 
   ntb=1, ntc=2, ntf=2, 
   ntwx=500, ntpr=500, dt = 0.002,
   ntr = 1, iwrap=1,
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1

cat << EOF1 > ! 06md.in
06md.in: equilibration, constant volume, temp ramp from 250 to RT, runs for 20ps (10000 steps) 
&cntrl
   imin=0, irest=1, ntx=5, nstlim = 10000,
   ntt=3, tempi=250.0, temp0=298.15, gamma_ln=2.0, ig = 6789, 
   ntp=0, taup=2.0, 
   ntb=1, ntc=2, ntf=2, 
   ntwx=500, ntpr=500, dt = 0.002,
   ntr = 1, iwrap=1,
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1

## constant pressure simulation allows box to adjust

#cat << EOF1 > ! 07md.in
#07md.in: equilibration, constant pressure, constant temp at 298.15 run for 5ns (2500000 steps).
#&cntrl
#   ioutfm=1, # write out NetCDF trajectory
#   ntwr=1000000000,
#   imin=0, irest=1, ntx=5, nstlim = 2500000,
#   ntt=3, temp0=298.15, gamma_ln=2.0, ig = 12345,
#   ntp=1, taup=2.0,
#   ntb=2, ntc=2, ntf=2,
#   ntwx=500, ntpr=500, dt = 0.002,
#   ntr = 1, iwrap=1,
#   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
#/
#EOF1

## box dimensions adjust quickly (40ps), crashes if too long (try less then, say 10ps)

#   ioutfm=1, # write out NetCDF trajectory
cat << EOF1 > ! 07.1md.in
07md.in: equilibration, constant pressure, constant temp at 298.15 run for 40ps (20000 steps).
&cntrl
   ioutfm=1, 
   ntwr=1000000000,
   imin=0, irest=1, ntx=5, nstlim = 10000,
   ntt=3, temp0=298.15, gamma_ln=2.0, ig = 12345,
   ntp=1, taup=2.0,
   ntb=2, ntc=2, ntf=2,
   ntwx=500, ntpr=500, dt = 0.002,
   ntr = 1, iwrap=1,
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1

## same as 07.1md but now starting with adjusted box as new restraint for protein coordinates
## this avoids pulling of protein into old position and hence crashing

cat << EOF1 > ! 07.2md.in
07md.in: equilibration, constant pressure, constant temp at 298.15 run for 5ns (2500000 steps).
&cntrl
   ioutfm=1, 
   ntwr=1000000000,
   imin=0, irest=1, ntx=5, nstlim = 2500000,
   ntt=3, temp0=298.15, gamma_ln=2.0, ig = 13245, 
   ntp=1, taup=2.0, 
   ntb=2, ntc=2, ntf=2, 
   ntwx=500, ntpr=500, dt = 0.002,
   ntr = 1, iwrap=1,
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1

## last equilibration run, is identical to production run - const volume (is 10% faster than const pressure)
## added ioutfm=1 here to write out NetCDF trajectory
## if ntwr=1000000000 > nstlim = 2500000, means only write one restart file at the end

cat << EOF1 > ! 08md_mcwat.in
08md.in: equilibration, constant volume, constant temp at 298.15 run for 5ns (2500000 steps).
&cntrl
   ioutfm=1,
   ntwr=1000000000,
   imin=0, irest=1, ntx=5, nstlim = 2500000,
   ntt=3, temp0=298.15, gamma_ln=2.0, ig = 23456,
   ntp=0, taup=2.0,
   ntb=1, ntc=2, ntf=2,
   ntwx=500, ntpr=500, dt = 0.002,
   ntr = 1, iwrap=1,
   mcwat=1, mcint=10000, mcrescyc=100000, mcresstr='WAT ',
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1


cat << EOF1 > ! 08md.in
08md.in: equilibration, constant volume, constant temp at 298.15 run for 5ns (2500000 steps).
&cntrl
   ioutfm=1, 
   ntwr=1000000000,
   imin=0, irest=1, ntx=5, nstlim = 2500000,
   ntt=3, temp0=298.15, gamma_ln=2.0, ig = 23456, 
   ntp=0, taup=2.0, 
   ntb=1, ntc=2, ntf=2, 
   ntwx=500, ntpr=500, dt = 0.002,
   ntr = 1, iwrap=1,
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1

## start of PRODUCTION RUN

cat << EOF1 > ! 09md.in
09md.in: production. constant volume, constant temp at 298.15 run for 10 ns (5000000 steps).
&cntrl
   ioutfm=1, 
   ntwr=1000000000,
   imin=0, irest=1, ntx=5, nstlim = 5000000,
   ntt=3, temp0=298.15, gamma_ln=2.0, ig = 34567, 
   ntp=0, taup=2.0, 
   ntb=1, ntc=2, ntf=2, 
   ntwx=500, ntpr=500, dt = 0.002,
   ntr = 1, iwrap=1,
   restraintmask = '${restraint_mask} & !@H', restraint_wt = 5.0,
/
EOF1

## generates identical input files for each run, only random seed (ig flag) changes

#cat 09md.in | sed 's/09md/10md/g' | sed 's/34567/10101/g'   > 10md.in
#cat 09md.in | sed 's/09md/11md/g' | sed 's/34567/111/g'     > 11md.in
#cat 09md.in | sed 's/09md/12md/g' | sed 's/34567/2121212/g' > 12md.in
#cat 09md.in | sed 's/09md/13md/g' | sed 's/34567/131313/g'  > 13md.in
#cat 09md.in | sed 's/09md/14md/g' | sed 's/34567/4443/g'    > 14md.in
#cat 09md.in | sed 's/09md/15md/g' | sed 's/34567/151515/g'  > 15md.in #35ns
#cat 09md.in | sed 's/09md/16md/g' | sed 's/34567/161616/g'  > 16md.in
#cat 09md.in | sed 's/09md/17md/g' | sed 's/34567/171717/g'  > 17md.in
#cat 09md.in | sed 's/09md/18md/g' | sed 's/34567/181818/g'  > 18md.in #50ns


## now that everything is set up -- let's run amber.

set pwd = `pwd`

  \$amberexe -O -i 01mi.in -o 01mi.out -p ${nameprefix}.prm7 \
  -c ${nameprefix}.rst7 -ref ${nameprefix}.rst7 \
  -x 01mi.mdcrd -inf 01mi.info -r 01mi.rst7

  \$amberexe -O -i 02mi.in -o 02mi.out -p ${nameprefix}.prm7 \
  -c 01mi.rst7 -ref 01mi.rst7 \
  -x 02mi.mdcrd -inf 02mi.info -r 02mi.rst7

  # CONSIDER running a step of NPT here first to at low temp to ajust the box size. 
  # then swiching to fixed volume to raise the tempature. 
  # or write python script to calc and import box size

  \$amberexe -O -i 01md.in -o 01md.out -p ${nameprefix}.prm7 \
  -c 02mi.rst7 -ref 02mi.rst7 -x 01md.mdcrd -inf 01md.info -r 01md.rst7 

  \$amberexe -O -i 02md.in -o 02md.out -p ${nameprefix}.prm7 \
  -c 01md.rst7 -ref 01md.rst7 -x 02md.mdcrd -inf 02md.info -r 02md.rst7 

  \$amberexe -O -i 03md.in -o 03md.out -p ${nameprefix}.prm7 \
  -c 02md.rst7 -ref 01md.rst7 -x 03md.mdcrd -inf 03md.info -r 03md.rst7 

  \$amberexe -O -i 04md.in -o 04md.out -p ${nameprefix}.prm7 \
  -c 03md.rst7 -ref 01md.rst7 -x 04md.mdcrd -inf 04md.info -r 04md.rst7

  \$amberexe -O -i 05md.in -o 05md.out -p ${nameprefix}.prm7 \
  -c 04md.rst7 -ref 01md.rst7 -x 05md.mdcrd -inf 05md.info -r 05md.rst7

  \$amberexe -O -i 06md.in -o 06md.out -p ${nameprefix}.prm7 \
  -c 05md.rst7 -ref 01md.rst7 -x 06md.mdcrd -inf 06md.info -r 06md.rst7

  \$amberexe -O -i 07.1md.in -o 07.1md.out -p ${nameprefix}.prm7 \
  -c 06md.rst7 -ref 01md.rst7 -x 07.1md.mdcrd -inf 07.1md.info -r 07.1md.rst7

  \$amberexe -O -i 07.2md.in -o 07.2md.out -p ${nameprefix}.prm7 \
  -c 07.1md.rst7 -ref 07.1md.rst7 -x 07.2md.mdcrd -inf 07.2md.info -r 07.2md.rst7


  \$amberexe -O -i 08md_mcwat.in -o 08md_mcwat.out -p ${nameprefix}.prm7 \
  -c 07.2md.rst7 -ref 07.2md.rst7 -x 08md_mcwat.mdcrd -inf 08md_mcwat.info -r 08md_mcwat.rst7

  \$amberexe -O -i 08md.in -o 08md.out -p ${nameprefix}.prm7 \
  -c 08md_mcwat.rst7 -ref 07.2md.rst7 -x 08md.mdcrd -inf 08md.info -r 08md.rst7

# \$amberexe -O -i 08md.in -o 08md.out -p ${nameprefix}.prm7 \
# -c 07.2md.rst7 -ref 07.2md.rst7 -x 08md.mdcrd -inf 08md.info -r 08md.rst7

## start PRODUCTION (10x 5ns = 50ns); takes about 24hrs on single GPU
  
  \$amberexe -O -i 09md.in -o 09md.out -p ${nameprefix}.prm7 \
  -c 08md.rst7 -ref 07.2md.rst7 -x 09md.mdcrd -inf 09md.info -r 09md.rst7
  
#  \$amberexe -O -i 10md.in -o 10md.out -p ${nameprefix}.prm7 \
#  -c 09md.rst7 -ref 07.2md.rst7 -x 10md.mdcrd -inf 10md.info -r 10md.rst7
#  
#  \$amberexe -O -i 11md.in -o 11md.out -p ${nameprefix}.prm7 \
#  -c 10md.rst7 -ref 07.2md.rst7 -x 11md.mdcrd -inf 11md.info -r 11md.rst7
#  
#  \$amberexe -O -i 12md.in -o 12md.out -p ${nameprefix}.prm7 \
#  -c 11md.rst7 -ref 07.2md.rst7 -x 12md.mdcrd -inf 12md.info -r 12md.rst7
#
#  \$amberexe -O -i 13md.in -o 13md.out -p ${nameprefix}.prm7 \
#  -c 12md.rst7 -ref 07.2md.rst7 -x 13md.mdcrd -inf 13md.info -r 13md.rst7
#
#  \$amberexe -O -i 14md.in -o 14md.out -p ${nameprefix}.prm7 \
#  -c 13md.rst7 -ref 07.2md.rst7 -x 14md.mdcrd -inf 14md.info -r 14md.rst7
#
#  \$amberexe -O -i 15md.in -o 15md.out -p ${nameprefix}.prm7 \
#  -c 14md.rst7 -ref 07.2md.rst7 -x 15md.mdcrd -inf 15md.info -r 15md.rst7
#
#  \$amberexe -O -i 16md.in -o 16md.out -p ${nameprefix}.prm7 \
#  -c 15md.rst7 -ref 07.2md.rst7 -x 16md.mdcrd -inf 16md.info -r 16md.rst7
#
#  \$amberexe -O -i 17md.in -o 17md.out -p ${nameprefix}.prm7 \
#  -c 16md.rst7 -ref 07.2md.rst7 -x 17md.mdcrd -inf 17md.info -r 17md.rst7
#
#  \$amberexe -O -i 18md.in -o 18md.out -p ${nameprefix}.prm7 \
#  -c 17md.rst7 -ref 07.2md.rst7 -x 18md.mdcrd -inf 18md.info -r 18md.rst7


## move scratch directory from cluster onto nfs
mv \$TASK_DIR ${workdir} 

EOF

chmod u+x qsub.amber.csh 

#qsub qsub.amber.csh 
#srun qsub.amber.csh 
sbatch qsub.amber.csh 

echo "To view whether job was submitted and running use \n qstat \n Then look at submitted queue e.g. gpu.q@n-1-141.cluster.ucsf.bks and log into node by typing \n qlogin -q int.q@n-1-141 \n cd /scratch/yourname/jobid \n ls -ltr \n look for latest .info file (e.g. 17md.info) and cat to screen \n cat 17md.info \n Use 005md.checkMDrun.py to see if run went to plan."

end # system

