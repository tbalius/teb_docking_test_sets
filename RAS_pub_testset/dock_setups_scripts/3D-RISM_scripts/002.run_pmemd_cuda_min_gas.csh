#setenv AMBERHOME /nfs/soft/amber/amber14

#setenv AMBERHOME /nfs/soft/amber/amber14
#setenv LD_LIBRARY_PATH ""
#setenv LD_LIBRARY_PATH "/usr/local/cuda-6.0/lib64/:$LD_LIBRARY_PATH"
#setenv LD_LIBRARY_PATH "/nfs/soft/cuda-6.5/lib64/:\$LD_LIBRARY_PATH"

#source ~baliuste/.bashrc.amber 

set pwd = `pwd`
set filedir = /mnt/projects/RAS-CompChem/static/Stanley/RAS_pub_testset/KRAS

#set list = `cat ../pdbdirlist.txt` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
#set list = `cat pdblist.txt` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
set list = `cat ${filedir}/001.process_prepare_pdb_files/pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo $pdbname
echo $ligname

set workdir = ${pwd}/${pdbname}_${ligname}/min_gas

if (-s $workdir) then
  echo "$workdir exists... continue"
  continue
endif

mkdir -p ${workdir}
cd ${workdir}

cp ../tleap/rec.leap.* . 

cat << EOF1 > ! 01mi.in
01mi.in: minimization with GAS
&cntrl
 imin = 1, maxcyc = 10000, ncyc = 500,  ntmin = 1,
 igb=6,
 ntx = 1, ntc = 1, ntf = 1,
 ntb = 0, ntp = 0,
 ntwx = 1000, ntwe = 0, ntpr = 1000,
 cut = 999.9,
 ntr = 1,
 restraintmask = '!@H=', 
 restraint_wt = 10.0,
/
EOF1


#$AMBERHOME/bin/pmemd.cuda -O -i 01mi.in -o 01mi.out -p com.leap.prm7 -c com.leap.rst7 -ref com.leap.rst7 -x 01mi.mdcrd -inf 01mi.info -r 01mi.rst7
#$AMBERHOME/bin/sander -O -i 01mi.in -o 01mi.out -p com.leap.prm7 -c com.leap.rst7 -ref com.leap.rst7 -x 01mi.mdcrd -inf 01mi.info -r 01mi.rst7

#cd $pwd

#echo "running: sinfo -p gpu"

#sinfo -p gpu

#SBATCH --nodelist=cn051

  #source ${pwd}/pickGPU.csh

cat << EOF > ! qsub.sander.csh
#!/bin/tcsh
#SBATCH -t 48:00:00
#SBATCH -p gpu
#SBATCH --gres=gpu:1
#SBATCH --output=stdout

  echo \${CUDA_VISIBLE_DEVICES}
  cd ${workdir}
  
  $AMBERHOME/bin/pmemd.cuda -O -i 01mi.in -o 01mi.out -p rec.leap.prm7 -c rec.leap.rst7 -ref rec.leap.rst7 -x 01mi.mdcrd -inf 01mi.info -r 01mi.rst7

EOF

  sbatch qsub.sander.csh 

end # pdb

