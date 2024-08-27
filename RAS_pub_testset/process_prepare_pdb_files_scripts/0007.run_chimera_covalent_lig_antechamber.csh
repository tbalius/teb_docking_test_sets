#!/bin/csh

#source ~baliuste/.cshrc.amber
#source ~baliuste/.cshrc.DOCK_dev
#echo "source /home/baliuste/.bashrc.amber"
echo "source /home/baliuste/.bashrc.amber22"
echo "source /home/baliuste/.bashrc.DOCK_dev"

set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts
#set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.13.1/bin
set chimerapath = /home/baliuste/zzz.programs/Chimera/chimera-1.17.3_oel8/bin

set mountdir = `pwd`

#set list = `cat pdb_lig_map.txt | awk '{print $1}'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
set list = `cat pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo $pdbname
echo $ligname

if ! ( -e ${mountdir}/005_chimera_dockprep_cofori/${pdbname}_${ligname}/cov_sph.pdb ) then
   echo "does not seem to be covalent ... go to next"
   continue
endif

set workdir = "${mountdir}/007_chimera_dockprep_covalent_lig_ante/${pdbname}_${ligname}"
echo $workdir

if (-e $workdir) then
   echo "$workdir exists.  Continue to next."
   continue
endif

mkdir -p $workdir
cd $workdir

set file = "${mountdir}/005_chimera_dockprep_cofori/${pdbname}_${ligname}/cov_sph.pdb"
set fpath = $file:h
cat $file | grep -v "CA" > covlig.pdb # do not put CA in ligand file just CB and SG
cat $fpath/lig_before_atom_removed.pdb | sed -e 's/HETATM/ATOM  /g' | grep "^ATOM" >> covlig.pdb

# this will allow us to manually add a h to the system.  
# if there exists a man_H for this ligand
if (-e  ${mountdir}/man_H/lig/${pdbname}_${ligname}_lig_man_H.pdb ) then
   cat ${mountdir}/man_H/lig/${pdbname}_${ligname}_lig_man_H.pdb >> covlig.pdb
endif
if (-e  ${mountdir}/man_H/lig/${pdbname}_${ligname}_covlig_man_H.pdb ) then
   cat ${mountdir}/man_H/lig/${pdbname}_${ligname}_covlig_man_H.pdb >> covlig.pdb
endif

#$chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py covlig.pdb covlig_addH keepH"    
$chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py covlig.pdb covlig_addH keepH"   >> chimera.log 

#exit

cat covlig_addH.pdb | sed -e 's/HETATM/ATOM  /g' | grep "^ATOM" > covlig1.pdb

grep -c 'Removing spurious proton from' ${mountdir}/007_chimera_dockprep_covalent_lig_ante/${pdbname}_${ligname}/chimera.log

if (-e ${mountdir}/007_chimera_dockprep_covalent_lig_ante/${pdbname}_${ligname}/chimera.log) then
  if ("`grep -c 'Removing spurious proton from' ${mountdir}/007_chimera_dockprep_covalent_lig_ante/${pdbname}_${ligname}/chimera.log `" != "0" ) then
     echo "Add man H again"
     #cat ${mountdir}/man_H/lig/${pdbname}_${ligname}_covlig_man_H.pdb >> covlig1.pdb
     grep ' H1 ' ${mountdir}/man_H/lig/${pdbname}_${ligname}_covlig_man_H.pdb >> covlig1.pdb
     grep ' H2 ' ${mountdir}/man_H/lig/${pdbname}_${ligname}_covlig_man_H.pdb >> covlig1.pdb
  endif
endif
#echo "I AM HERE"

   set ligname = `tail -1 covlig1.pdb | cut -c 18-20`
   set ligresid = `tail -1 covlig1.pdb | cut -c 24-27`

python ${scriptdir}/replace_resname_resnum.py $ligname $ligresid covlig1.pdb covlig.pdb

set liginfo = `tail -1 covlig1.pdb | cut -c 18-26`
sed -i -E "s/(.{17})(.{9})/\1$liginfo/" covlig.pdb

#continue

# this will allow us to manually remove a h from the system.
# if there exists a remove_H for this ligand
#if (-e ${mountdir}/man_H/lig/remove_H/${pdbname}_${ligname}_lig_remove_H.pdb ) then
#  grep -xvFf ${mountdir}/man_H/lig/remove_H/${pdbname}_${ligname}_lig_remove_H.pdb covlig1.pdb > covlig.pdb
#endif
if (-e ${mountdir}/man_H/lig/lig_remove_H.txt) then
   if (`grep -c "${pdbname} ${ligname}" ${mountdir}/man_H/lig/lig_remove_H.txt` != "0" ) then
      grep -wv `grep "${pdbname} ${ligname}" ${mountdir}/man_H/lig/lig_remove_H.txt | awk '{print $3}'` covlig.pdb > temp.pdb
      mv temp.pdb covlig.pdb
   endif
endif

#set charge = -4
#set charge = 0.0
set charge = `grep "$pdbname $ligname" ${mountdir}/pdb_lig_charge_map.txt | awk '{print $3}'`

cat << EOF > submit.csh
#!/bin/csh
#SBATCH -t 4:00:00
#SBATCH --output=stderr

$AMBERHOME/bin/antechamber -i covlig.pdb -fi pdb -o covlig.ante.mol2 -fo mol2
#$AMBERHOME/bin/antechamber -i covlig_addH.pdb -fi pdb -o covlig.ante.mol2 -fo mol2

#$AMBERHOME/bin/antechamber -i covlig.ante.mol2 -fi mol2 -o covlig.ante.charge.mol2 -fo mol2 -c bcc -at sybyl -nc ${charge}
$AMBERHOME/bin/antechamber -i covlig.ante.mol2 -fi mol2 -o covlig.ante.charge.mol2 -fo mol2 -c bcc -at sybyl -nc ${charge} -s 2
$AMBERHOME/bin/antechamber -i covlig.ante.mol2 -fi mol2  -o covlig.ante.pdb  -fo pdb
$AMBERHOME/bin/antechamber -i covlig.ante.charge.mol2 -fi mol2  -o covlig.ante.charge.prep -fo prepi
$AMBERHOME/bin/parmchk2 -i covlig.ante.charge.prep -f  prepi -o covlig.ante.charge.frcmod


cp covlig.ante.charge.mol2 covlig_complete.mol2 

python ${scriptdir}/mol_covalent_CB_SG_to_Du.py covlig_complete.mol2 covlig_complete_du

grep SG ${mountdir}/005_chimera_dockprep_cofori/${pdbname}_${ligname}/cov_sph.pdb >  cov_sph.pdb
grep CB ${mountdir}/005_chimera_dockprep_cofori/${pdbname}_${ligname}/cov_sph.pdb >> cov_sph.pdb
grep CA ${mountdir}/005_chimera_dockprep_cofori/${pdbname}_${ligname}/cov_sph.pdb >> cov_sph.pdb

$DOCKBASE/proteins/pdbtosph/bin/pdbtosph cov_sph.pdb cov_sph.sph
EOF

sbatch submit.csh

#exit
end

