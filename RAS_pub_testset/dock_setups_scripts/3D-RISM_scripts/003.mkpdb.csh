#!/bin/csh

#echo "sbatch -p norm-oel8 003.mkpdb.csh"

#setenv AMBERHOME /nfs/soft/amber/amber14
#setenv LD_LIBRARY_PATH ""
#setenv LD_LIBRARY_PATH "/usr/local/cuda-6.0/lib64/:$LD_LIBRARY_PATH"

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

if !(-s $workdir) then
  echo "$workdir does not exist ... continue"
  continue
endif

cd ${workdir}

cat << EOF > mkpdb.csh
#!/bin/csh
$AMBERHOME/bin/ambpdb -p rec.leap.prm7 -c 01mi.rst7 > 01mi.pdb
#$AMBERHOME/bin/ambpdb -p lig.leap.prm7 < 01mi.lig.rst7 > 01mi.lig.pdb
EOF

sbatch mkpdb.csh

end # pdb

