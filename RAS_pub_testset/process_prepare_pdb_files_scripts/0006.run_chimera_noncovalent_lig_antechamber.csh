#!/bin/csh

#source ~baliuste/.cshrc.amber
#echo "source /home/baliuste/.bashrc.amber"
echo "source /home/baliuste/.bashrc.amber22"

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

set charge = `grep "$pdbname $ligname" ${mountdir}/pdb_lig_charge_map.txt | awk '{print $3}'`
echo "charge = $charge"

if $charge == "" then 
    echo "charge is blank ... $pdbname likely not in pdb_lig_charge_map.txt"
    #exit
    continue
endif

set workdir = "${mountdir}/006_chimera_dockprep_noncovalent_lig_ante/${pdbname}_${ligname}"
echo $workdir

if (-e $workdir) then
   echo "$workdir exists."
   #continue
endif

mkdir -p $workdir
cd $workdir

set fpath = "${mountdir}/005_chimera_dockprep_cofori/${pdbname}_${ligname}"

#if (-e $fpath/lig_before_atom_removed.pdb) then
#   echo "covlanet perpared non-covalently"
#   cat $fpath/lig_before_atom_removed.pdb | sed -e 's/HETATM/ATOM  /g' | grep ATOM > lig.pdb
#else
   #cat $fpath/lig_complete.pdb | sed -e 's/HETATM/ATOM  /g' | grep "^ATOM" > lig.pdb
#endif

cat $fpath/lig.pdb | grep "^ATOM" > lig.pdb

# this will allow us to manually add a h to the system.
# if there exists a man_H for this ligand
if (-e ${mountdir}/man_H/lig/${pdbname}_${ligname}_lig_man_H.pdb ) then
  cat ${mountdir}/man_H/lig/${pdbname}_${ligname}_lig_man_H.pdb >> lig.pdb
endif

$chimerapath/chimera --nogui --script "${scriptdir}/chimera_addh.py lig.pdb lig_addH keepH"   >> chimera.log

cat lig_addH.pdb | sed -e 's/HETATM/ATOM  /g' | grep "^ATOM" > lig1.pdb

cp lig1.pdb lig.pdb

# this will allow us to manually remove a h from the system.
# if there exists a remove_H for this ligand
#if (-e ${mountdir}/man_H/lig/remove_H/${pdbname}_${ligname}_lig_remove_H.pdb ) then
#   grep -xvFf ${mountdir}/man_H/lig/remove_H/${pdbname}_${ligname}_lig_remove_H.pdb lig1.pdb > lig.pdb
#endif
if (-e ${mountdir}/man_H/lig/lig_remove_H.txt) then
   if (`grep -c "${pdbname} ${ligname}" ${mountdir}/man_H/lig/lig_remove_H.txt` != "0" ) then
      grep -wv `grep "${pdbname} ${ligname}" ${mountdir}/man_H/lig/lig_remove_H.txt | awk '{print $3}'` lig1.pdb > lig.pdb
   endif
endif

#python ${scriptdir}/replace_resname_resnum.py $ligname $ligresid cof1.pdb cof.pdb

#set charge = -4
#set charge = 0.0
#exit
cat << EOF > submit.csh
#!/bin/csh
#SBATCH -t 4:00:00
#SBATCH --output=stderr

$AMBERHOME/bin/antechamber -i lig.pdb -fi pdb -o lig.ante.mol2 -fo mol2
$AMBERHOME/bin/antechamber -i lig.ante.mol2 -fi mol2 -o lig.ante.charge.mol2 -fo mol2 -c bcc -at sybyl -nc "${charge}" -s 2
$AMBERHOME/bin/antechamber -i lig.ante.mol2 -fi mol2  -o lig.ante.pdb  -fo pdb
$AMBERHOME/bin/antechamber -i lig.ante.charge.mol2 -fi mol2  -o lig.ante.charge.prep -fo prepi
$AMBERHOME/bin/parmchk2 -i lig.ante.charge.prep -f  prepi -o lig.ante.charge.frcmod

cp lig.ante.charge.mol2 lig_complete.mol2
EOF

sbatch submit.csh
#python ${scriptdir}/mol_covalent_CB_SG_to_Du.py covlig_complete.mol2 covlig_complete_du
#
#grep SG ${mountdir}/004_chimera_dockprep_cofori/$pdbname/cov_sph.pdb >  cov_sph.pdb
#grep CB ${mountdir}/004_chimera_dockprep_cofori/$pdbname/cov_sph.pdb >> cov_sph.pdb
#grep CA ${mountdir}/004_chimera_dockprep_cofori/$pdbname/cov_sph.pdb >> cov_sph.pdb
#
#$DOCKBASE/proteins/pdbtosph/bin/pdbtosph cov_sph.pdb cov_sph.sph

#exit

end # system

