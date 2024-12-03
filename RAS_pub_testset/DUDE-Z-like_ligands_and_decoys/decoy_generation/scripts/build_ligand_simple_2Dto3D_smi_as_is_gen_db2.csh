#!/bin/csh
# Written by Trent Balius at FNLCR on Feb 6, 2020.
# This script is to simplify the database generation or at less make if easier for me to modify it.
# Taken from /home/baliuste/zzz.github/DOCK_dev_2020_12_01/ucsfdock/ligand/generate/

  if (-e db_build_working) then
      echo "Remove this directory: db_build_working"
      exit
  endif

  mkdir db_build_working
  cd db_build_working
  cp ../$1 .


  # Step 1. Process smiles with chemAxon to protonate and tautomerize.  
  #source ~/.cshrc.python3
  source ~baliuste/zzz.programs/openbabel/env.csh
  #source /nfs/soft/openbabel/current/env.csh
  source ~baliuste/zzz.programs/jchem/env.csh
  #source /nfs/soft/jchem/current/env.csh
  #echo "I AM HERE"
  echo "filename = $1"
#  set smilist = `cat $1 | awk '{print "\""$1"\""}'`   
#  echo "$smilist"
  #set PH = 7.2
  set PH = 7.2
  set TAUTOMER_LIMIT = 30
  #set PROTOMER_LIMIT = 30
  set PROTOMER_LIMIT = 10
  set TAUT_PROT_CUTOFF = 1
  set START = 1

  set CXCALCEXE = `which cxcalc`
  set MOLCONVERTEXE = `which molconvert`

#  sed 's/\s\+/ /g' "${1}" | \
#        ${CXCALCEXE} -g dominanttautomerdistribution -H "${PH}" -C false -t tautomer-dist | \
#        ${MOLCONVERTEXE} sdf -g -c "tautomer-dist>=${TAUTOMER_LIMIT}" | \
#        ${CXCALCEXE} -g microspeciesdistribution -H $PH -t protomer-dist | \
#        ${MOLCONVERTEXE} smiles -g -c "protomer-dist>=${PROTOMER_LIMIT}" -T name:tautomer-dist:protomer-dist | \
#        awk -v "cutoff=${TAUT_PROT_CUTOFF}" -v "start=${START}" '{ if (NR == 1 && start < 2) { print $0, "score" } else { score = ($3 * $4)/100 ; if (score >= cutoff) { print $0, score } } }'  > prot-taut.info


 #awk 'BEGIN{count=0}{if(count==0){count=1}else{print $0}}' prot-taut.info | sort -r -n -k2 | awk '{print $1 " " $2}' > prot-taut2.info
 #awk 'BEGIN{count=0}{if(count==0){count=1}else{print $0}}' prot-taut.info | awk '{print $1 " " $2}' | sort -u | sort -n -k2 > prot-taut2.info
  
  # Step 2. Convert smiles to mol2 files. 
  source /home/baliuste/zzz.programs/corina/env.csh
  #source /nfs/soft/corina/current/env.csh


  #split -a 8 -l 1 prot-taut2.info  prot-taut_split_
  split -a 8 -l 1 ${1}  prot-taut_split_

  #mv prot-taut_split_aaaaaaaa header # move the header
  set count = 0
  #foreach file (`ls prot-taut_split_???????[bcdghijklmnopqrstuvwxyz]`)

  set mountdir = `pwd`
  touch dirlist
  foreach file (`ls prot-taut_split_????????`)
     cd $mountdir
     #set name = `awk -F'\t' '{print $2}' $file`
     set name = `awk  '{print $2}' $file`
     set newname =  "${name}_$count"
     set workdir = ${mountdir}/${name}
     if !(-e $workdir) then 
        mkdir $workdir
        echo $name >> dirlist # remember all of the dir that we make
     endif
     
     echo "$newname"
     if (-e "$workdir/$newname.smi") then
        "Error. "
        exit
     endif
     mv "$file" "$workdir/$newname.smi"
    #awk '{printf "name.txt 0 %s %s | NO_LONG_NAME\n",$2,$1}' "$workdir/$newname.smi" > "$workdir/$newname.name.txt"
     awk '{printf "name.txt 0 %16s %s | NO_LONG_NAME\n",substr($2, 1, 16),$1}' "$workdir/$newname.smi" > "$workdir/$newname.name.txt"
     cd $workdir
     #/home/baliuste/zzz.programs/corina/corina -i t=smiles -o t=mol2 -d rc,flapn,de=6,mc=1,wh $newname.smi $newname.mol2
     corina -i t=smiles -o t=mol2 -d rc,flapn,de=6,mc=1,wh $newname.smi $newname.mol2
     
     @ count = $count + 1
  end
  #awk '{print $1 " " $2}' prot-taut.info > prot-taut.smi
  
  #/home/baliuste/zzz.programs/corina/corina -i t=smiles -o t=mol2 -d rc,flapn,de=6,mc=1,wh prot-taut.smi prot-taut.mol2

  # Step 3. Run Amsol.
  
  foreach  dir (`cat ${mountdir}/dirlist`)
     cd ${mountdir}/${dir}/
     foreach mol2 (`ls *.mol2`)
        ls -l $mol2
        ${DOCKBASE}/ligand/amsol/calc_solvation.csh $mol2 
        mv output.mol2 ${mol2:r}_output.mol2
        mv output.solv ${mol2:r}_output.solv
     end
  end
  
  # Step 4. Perform conformational expansion and db2 generation.
  #

  foreach  dir (`cat ${mountdir}/dirlist`)
     cd ${mountdir}/${dir}/
     echo ${dir}
     #foreach mol2 (`ls ${dir}_*[0123456789]*.mol2`)
     foreach mol2 (`ls ${dir}_*[0123456789].mol2`)
       echo $mol2
       set name = ${mol2:r}
       set db2dir = ${mountdir}/${dir}/${name}_db2
       mkdir $db2dir
       cd $db2dir
       if  ($#argv == 1) then
          #csh ${DOCKBASE}/ligand/generate/dock6_confgen_db2.csh ../${name}_output.mol2 ../${name}_output.solv ../${name}.name.txt
          csh /mnt/projects/RAS-CompChem/static/Stanley/decoy_gen/scripts/dock6_confgen_db2.csh ../${name}_output.mol2 ../${name}_output.solv ../${name}.name.txt
       else if  ($#argv == 2) then
          csh ${DOCKBASE}/ligand/generate/dock6_confgen_db2_covalent.csh ../${name}_output.mol2 ../${name}_output.solv ../${name}.name.txt
       endif
     end
  end
