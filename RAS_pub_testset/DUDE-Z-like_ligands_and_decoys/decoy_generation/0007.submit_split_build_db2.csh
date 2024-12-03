#!/bin/csh

#conda activate
#chemaxon
#dockbase

set mountdir = `pwd`
set scriptdir = /mnt/projects/RAS-CompChem/static/Stanley/decoy_gen/scripts

#echo "source /home/tanys/set_dockbase.sh"
set DOCKBASE=/home/baliuste/zzz.github/DOCK_dev_2020_12_01/ucsfdock
set DOCK6BASE=/home/baliuste/zzz.github/dock6_10_merge/rizzo_branch

set smiles_file = $1
set smi_per_job = $2

ls ${mountdir}/${smiles_file}
split -a 5 -l ${smi_per_job} ${smiles_file} decoys_

foreach file (`ls decoys_?????`)

if (-e ${mountdir}/${file}_dir) then
  echo "Error, ${file}_dir exists ..."
  continue
endif

mkdir ${mountdir}/${file}_dir
cd ${mountdir}/${file}_dir

cp ${mountdir}/${file} .

#sbatch ${DOCKBASE}/ligand/generate/build_ligand_simple_with_dock6.csh ${file}
#sbatch ${DOCKBASE}/ligand/generate/build_ligand_simple_2Dto3D_smi_as_is.csh ${file}
sbatch ${scriptdir}/build_ligand_simple_2Dto3D_smi_as_is_gen_db2.csh ${file}

end

