#!/bin/csh

# this script calls be_blasti.py which creates a receptor and ligand file from a (list of) pdbcode(s).

#source /home/baliuste/.cshrc.DOCK
#source /home/baliuste/.cshrc.python2
#source /home/baliuste/.cshrc.DOCK_dev
#source /home/baliuste/.cshrc.python3
#source /home/baliuste/.bashrc.DOCK_dev
#source /home/baliuste/.bashrc.python3
echo "source /home/baliuste/.bashrc.DOCK_dev"
echo "source /home/baliuste/.bashrc.python3"

# msms is a molecular surface generation program needed for be_blasti.py to run
# which is put in your path
set path = ( /home/baliuste/zzz.programs/msms $path )

#set list = "1DB1" # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
#set list = `cat $1`
set list = `cat pdb_lig_map.txt | sed 's/ /./g'`
#set list = `cat pdb_lig_map_sel.txt | sed 's/ /./g'`
#set list = `cat /nfs/work/users/tbalius/VDR/Enrichment/pdblist_rat `

# CHANGE THIS, according to where the magic is going to happen
#set mountdir = "/mnt/nfs/work/users/tbalius/VDR/"
set mountdir = `pwd` 

# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo "${pdblig}"
echo "${pdbname}"
echo "ligand = ${ligname}"

# for each pdb makes a directory with its name
set workdir = ${mountdir}/001_pdb_breaker/${pdbname}_${ligname}

# so you don't blow away stuff; continue means STOP here and continue with next pdb from list
if ( -s $workdir ) then
   echo "$workdir exists ..."
   continue
endif

  mkdir -p ${workdir}
  cd ${workdir}

# the atom type definition is needed for msms which is sym-linked into the cwd
  ln -s /home/baliuste/zzz.programs/msms/atmtypenumbers .
  #python /home/baliuste/zzz.scripts/be_blasti.py --pdbcode $pdbname nocarbohydrate renumber | tee -a pdbinfo_using_biopython.log        
# carbs are disregarded as ligands! if it is: carbohydrate instead of nocarbohydrate
# renumber renumbers the residue number
  echo "python ${DOCKBASE}/proteins/pdb_breaker/be_blasti.py --pdbcode $pdbname nocarbohydrate original_numbers $ligname | tee -a pdbinfor_using_biopython.log"
  python ${DOCKBASE}/proteins/pdb_breaker/be_blasti.py --pdbcode $pdbname nocarbohydrate original_numbers $ligname | tee -a pdbinfo_using_biopython.log

# error checking looks for receptor and ligand file which should be produced by be_blasti.py
  if !(-s rec.pdb) then
      echo "rec.pdb is not found"
  endif

  mv rec.pdb temp.pdb
  grep -v TER temp.pdb | grep -v END > rec.pdb

  rm temp.pdb

# be_blasti.py produces peptide which may be used as a ligand if no other ligand is produced
  if (-s lig.pdb) then
     sed -e "s/HETATM/ATOM  /g" lig.pdb > xtal-lig.pdb
  else if (-s pep.pdb) then ## if no ligand and peptide
     sed -e "s/HETATM/ATOM  /g" pep.pdb > xtal-lig.pdb
  else
     echo "Warning: No ligand or peptide."
  endif

# see if there might be a covalent bond between ligand and receptor
  grep LINK ${pdbname}_ori.pdb > covalent_info.txt

  #/home/baliuste/zzz.programs/Chimera/chimera-1.13.1/bin/chimera --nogui --script "/home/baliuste/zzz.scripts/chimera_dockprep_keep_h_sol.py rec.pdb rec_out"

  #if (-e xtal-lig.pdb) then
  #   /home/baliuste/zzz.programs/Chimera/chimera-1.13.1/bin/chimera --nogui --script "/home/baliuste/zzz.scripts/chimera_dockprep_keep_h.py xtal-lig.pdb xtal-lig_out"
  #endif

end # system

