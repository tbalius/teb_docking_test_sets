#!/bin/csh

set mountdir = `pwd`
set scriptdir = /mnt/projects/RAS-CompChem/static/Stanley/decoy_gen/scripts
set workdir = ${mountdir}/protonate
set smi_per_job = $1

if (-e $workdir) then
  echo "Error, $workdir exists ..."
  exit
endif

mkdir $workdir
cd $workdir

cat ${mountdir}/lig_*_dir/decoys.all.smi > decoys.smi
split -a 5 -l ${smi_per_job} decoys.smi decoys_

foreach file (`ls decoys_?????`)

mkdir ${workdir}/${file}_dir
cd ${workdir}/${file}_dir

cp ${workdir}/${file} .

sbatch ${scriptdir}/protonate_with_chemaxon.csh ${file} 7.2 ${file}

end

