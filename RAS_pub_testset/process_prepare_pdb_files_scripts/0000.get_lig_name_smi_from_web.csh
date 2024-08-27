#!/bin/csh

rm pdb_lig_map.txt
touch pdb_lig_map.txt

set list = `cat systems.txt`

foreach pdb ($list) 

echo $pdb

curl "https://files.rcsb.org/view/$pdb.pdb" | grep "HET " | \
   grep -v "GDP" | grep -v "GNP" | grep -v "GCP" | grep -v "GSP" | grep -v "GTP" | \
   grep -v " MG" | grep -v " NA" | grep -v " CA" | grep -v " CL" | grep -v " ZN" | \
   grep -v "UNX" | grep -v "NO3" | grep -v "SO4" | grep -v "PO4" | \
   grep -v "IPA" | grep -v "GOL" | grep -v "EDO" | grep -v "HEZ" | \
   grep -v "PEG" | grep -v "PGE" | grep -v "PG4" | grep -v "1PE" | grep -v "P15" | \
   grep -v "ACE" | grep -v "ACT" | grep -v "CIT" | grep -v "FLC" | \
   grep -v "DMF" | grep -v "GLY" | grep -v "TRS" | \
   grep -v "DMS" | grep -v "CSO" | grep -v "CSX" | \
   grep -v "DTT" | grep -v "DTU" | \
   grep -v "HEX" | \
   grep -v "ETF" | \
   grep -v "TCE" | \
   grep -v "9GM" | grep -v "Y9Z" | grep -v "6ZD" | \
   grep -v "BEF" | grep -v "MPD" | grep -v "PTR" | \
   grep -v "YEG" | grep -v "RSF" | grep -v "RSG" | \
   grep -v "CAG" | \
   awk '{print "'$pdb'", $2}' | sort -u >> pdb_lig_map.txt

end #pdb

rm ligs.smi
touch ligs.smi 

foreach line (`cat pdb_lig_map.txt | sed 's/ /./g'`)

set pdb = $line:r
set lig = $line:e

curl https://files.rcsb.org/ligands/view/${lig}.cif | grep SMILES_CANONICAL | grep OpenEye | awk '{print $6, $1}' | sed 's/"//g' >> ligs.smi

end #lig

cat ligs.smi | sort -uk2  > ligs_uniq.smi

