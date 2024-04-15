
# script by Stanley Tan and Trent Balius, 2023/05/16

set mountdir = `pwd`
set workdir = ${mountdir}/chimera
cd ${workdir}

ls cof_addh.pdb
grep "^HETATM" cof_addh.pdb > temp.pdb
# if the cofactor is not protonated correctly then load into chimera and use the "Build Structure" function to remove undesired hydrogen(s) and add in desired hydrogen(s).  
# modify the below line to replace one H for another.  
sed -i 's/H3  GTP A 203      13.546  31.611   0.432  1.00  0.00           H/HN1 GTP A 203      16.813  29.728   2.042  1.00  0.00           H/g' temp.pdb
#rm cof_addh.pdb
mv cof_addh.pdb cof_addh.pdb.old
mv temp.pdb cof_addh.pdb

