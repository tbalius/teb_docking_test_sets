#!/bin/csh

#conda activate
#chemaxon

set SMIFILE = $1
set PH = $2
set OUTFILE_PREFIX = $3

set PROTOMER_LIMIT = 10

set CXCALCEXE = ${CHEMAXON_PATH}/bin/cxcalc
set MOLCONVERTEXE = ${CHEMAXON_PATH}/bin/molconvert

cat ${SMIFILE} | \
  ${CXCALCEXE} -g microspeciesdistribution -H $PH -t protomer-dist | \
  ${MOLCONVERTEXE} smiles -g -c "protomer-dist>=${PROTOMER_LIMIT}" -T name:protomer-dist > prot.info

cat prot.info | \
  tail -n +2  | \
  sort -u     | \
  awk -v OFS='\t' '{print $1, $2}' > ${OUTFILE_PREFIX}_prot.smi

cat << EOF > prot.log
SMIFILE = ${SMIFILE}
PH = ${PH}
OUTFILE_PREFIX = ${OUTFILE_PREFIX}
PROTOMER_LIMIT = ${PROTOMER_LIMIT}
EOF

