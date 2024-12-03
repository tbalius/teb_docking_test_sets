#!/bin/csh

set mountdir = `pwd`
set scriptdir = /mnt/projects/RAS-CompChem/static/Stanley/decoy_gen/scripts
set ligand_file = $1
set ligs_per_job = $2

ls ${mountdir}/${ligand_file}
if !(-e ${mountdir}/ligands.smi) then
   sort -u ${ligand_file} > ligands.smi
endif
split -a 5 -l ${ligs_per_job} ligands.smi lig_

foreach file (`ls lig_?????`)

if (-e ${mountdir}/${file}_dir) then
  echo "Error, ${file}_dir exists ..."
  continue
endif

mkdir ${mountdir}/${file}_dir
cd ${mountdir}/${file}_dir

cp ${mountdir}/${file} .
cp ${mountdir}/lookupforzinc.txt .

cat << EOF > search_zinc.csh
#!/bin/csh
python ${scriptdir}/mwt_logp_lookup_zinc_search_2d_sort.py ${file} decoys > search_zinc.log
EOF

sbatch search_zinc.csh

end

