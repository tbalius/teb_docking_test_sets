#!/bin/csh
# Scripted by Stanley Tan and Trent Balius, FNLCR, 2023, May 16.  

# download file from web. 
wget https://files.rcsb.org/view/6OIM.pdb --no-check-certificate

# put standard residues in the rec.pdb file.
grep "^ATOM   " 6OIM.pdb  > rec.pdb

# put non-standard residues in the temp.pdb file.
grep "^HETATM " 6OIM.pdb > temp.pdb

# change the "HETATM" line starter to "ATOM  ".
sed -i 's/HETATM/ATOM  /g' temp.pdb

# put the BI-2853 in the lig.pdb file.
grep "MOV" temp.pdb > lig.pdb

# put the GTP analog in the cof.pdb file.
grep "GDP" temp.pdb > cof.pdb

# put the magnesium ion in the rec.pdb file.
grep "MG" temp.pdb >> rec.pdb

# remove temp.pdb file. 
rm temp.pdb
