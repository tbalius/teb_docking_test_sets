#!/bin/csh

set mountdir = `pwd`
set scriptdir = /mnt/projects/RAS-CompChem/static/Stanley/decoy_gen/scripts
set protdir = ${mountdir}/protonate

if !(-e $protdir) then
  echo "Error, $protdir does not exist ..."
  exit
endif

if !(-e ${protdir}/decoys_prot.smi) then
  cat ${protdir}/decoys_*/decoys_*_prot.smi > ${protdir}/decoys_prot.smi
endif

foreach file (`ls lig_?????`)

if !(-e ${mountdir}/${file}_dir) then
  echo "Error, ${file}_dir does not exist ..."
  continue
endif

if (-s ${mountdir}/${file}_dir/decoys_matched.all.smi) then
  echo "${file}_dir/decoys_matched.all.smi exists ..."
  continue
endif

cd ${mountdir}/${file}_dir

ln -s ${protdir}/decoys_prot.smi .

cat << EOF > match_crg.csh
#!/bin/csh
python ${scriptdir}/match_protonated_decoys_sort.py ${file} decoys_prot.smi decoys_matched > match_crg.log
EOF

sbatch match_crg.csh

end

