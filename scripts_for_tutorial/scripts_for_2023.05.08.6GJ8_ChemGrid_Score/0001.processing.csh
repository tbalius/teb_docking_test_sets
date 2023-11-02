#!/bin/csh
# Scripted by Stanley Tan and Trent Balius, FNLCR, 2023, May 16.  

# download file from web. 
wget https://files.rcsb.org/view/6GJ8.pdb

# put standard residues in the rec.pdb file.
grep "ATOM   " 6GJ8.pdb | sed '1d' > rec.pdb

# put non-standard residues in the temp.pdb file.
grep "HETATM " 6GJ8.pdb | sed '1d' > temp.pdb

# change the "HETATM" line starter to "ATOM  ".
sed -i 's/HETATM/ATOM  /g' temp.pdb

# put the BI-2853 in the lig.pdb file.
grep "F0K" temp.pdb > lig.pdb

# put the GTP analog in the cof.pdb file.
grep "GCP" temp.pdb > cof.pdb

# change the name to GTP.
sed -i 's/GCP/GTP/g' cof.pdb

# put the magnesium ion in the rec.pdb file.
grep "MG" temp.pdb >> rec.pdb

# remove temp.pdb file. 
rm temp.pdb
