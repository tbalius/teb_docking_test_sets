grep "ATOM   " 6GJ8.pdb | sed '1d' > rec.pdb
grep "HETATM " 6GJ8.pdb | sed '1d' > temp.pdb

grep "F0K" temp.pdb > lig.pdb
grep "GCP" temp.pdb > cof.pdb
sed -i 's/GCP/GTP/g' cof.pdb

sed -i 's/HETATM/ATOM  /g' temp.pdb
grep "MG" temp.pdb >> rec.pdb

rm temp.pdb
