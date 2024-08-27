#!/bin/csh

#echo "source ~/.bashrc.amber"
#source ~baliuste/.cshrc.amber
#echo "source /home/baliuste/.bashrc.amber"
#source /home/baliuste/.bashrc.amber
echo "source /home/baliuste/.bashrc.amber22"

set mountdir = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts
set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.17.3_oel8/bin
set obablepath  = /home/baliuste/zzz.programs/openbabel/install/bin

#set list = `cat pdb_lig_map.txt | awk '{print $1}'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
set list = `cat pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo $pdbname
echo $ligname

set filedir = ${mountdir}/003_chimera_cofactor_h/${pdbname}_${ligname}

#foreach cof_file (`ls $filedir/cof.?.pdb`)

set cof_file = ${filedir}/cof.pdb
set cof_name = $cof_file:t:r

echo $cof_name
#exit

set workdir = ${mountdir}/004_chimera_cofactor_q/${pdbname}_${ligname}/${cof_name}

if (-e $workdir) then
   echo "$workdir exists. skipping ... "
   continue
endif

mkdir -p $workdir
cd $workdir

ls -ltr $filedir
dos2unix $cof_file
ls -ltr $cof_file

#$obablepath/obabel -imol2 $filemol2 -opdb -O cof.pdb
#cp $cof_file cof.pdb
cp $cof_file cof.pdb.ori

sed -e 's/HETATM/ATOM  /g' cof.pdb.ori | grep "^ATOM" > cof.pdb
set file = cof.pdb

set charge = "-4.0"

if ("`grep -c GNP $file`" != "0") then
   set cof_file = GNP_cof.pdb
   cp $file GNP_cof.pdb 
endif

if ("`grep -c GCP $file`" != "0") then
   set cof_file = GCP_cof.pdb
   cp $file GCP_cof.pdb 
endif

if ("`grep -c GSP $file`" != "0") then
   set cof_file = GSP_cof.pdb
   cp $file GSP_cof.pdb 
endif

if ("`grep -c GTP $file`" != "0") then
   set cof_file = GTP_cof.pdb
   cp $file GTP_cof.pdb 
endif

if ("`grep -c GDP $file`" != "0") then
   set cof_file = GDP_cof.pdb
   cp $file GDP_cof.pdb 
   set charge = "-3.0"
endif

cat << EOF > submit.csh
#!/bin/csh
#SBATCH -t 4:00:00
#SBATCH --output=stderr

cd $workdir

$AMBERHOME/bin/antechamber -i cof.pdb -fi pdb -o cof.ante.mol2 -fo mol2
$AMBERHOME/bin/antechamber -dr no -i cof.ante.mol2 -fi mol2 -o cof.ante.charge.mol2 -fo mol2 -c bcc -at sybyl -nc ${charge}
$AMBERHOME/bin/antechamber -dr no -i cof.ante.mol2 -fi mol2  -o cof.ante.pdb  -fo pdb
$AMBERHOME/bin/antechamber -dr no -i cof.ante.charge.mol2 -fi mol2  -o cof.ante.charge.prep -fo prepi
$AMBERHOME/bin/parmchk2 -dr no -i cof.ante.charge.prep -f  prepi -o cof.ante.charge.frcmod
EOF

sbatch submit.csh

#end # cof
end # system

