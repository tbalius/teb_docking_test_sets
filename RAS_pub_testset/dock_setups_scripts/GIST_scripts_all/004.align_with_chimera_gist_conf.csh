#!/bin/csh 
## this script was written by trent balius in the Rizzo Group, 2011
## modified in the Shoichet Group, 2013-2015

# TEB, MF comments -- March 2017
#
# This shell script will do the following:
# (1) aligns the ligand file and nearby waters onto MD frame of reference created in previous script [006gist.cpptraj_mk_ref.csh]
# (2) then writes out the aligned ligand and waters which will be used to calculate center of mass which centers the GIST box.
#  Aligned structures are then also useful for visualizing gist.

set pwd = `pwd`

set list = `cat $1 | sed 's/ /_/g'`
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )
echo $pdblig

set mountdir = ${pwd}/${pdblig}
set workdir  = $mountdir/04.align_to_md

rm -rf $workdir
mkdir -p $workdir
cd $workdir

set ref = "$mountdir/03.ref_rec/ref.pdb"
set rec = "$mountdir/rec.pdb"
set lig = "$mountdir/xtal-lig.pdb"
set cof = "$mountdir/lig.pdb"
set ion = "$mountdir/ion.pdb"
set rec_crg = "$mountdir/rec.crg.pdb"

set chimerapath = "/home/baliuste/zzz.programs/Chimera/chimera-1.17.3_oel8/bin/chimera"

#write instruction file for chimera based alignment
cat << EOF > chimera.com
# template
open $ref 
# rec.crg
open $rec_crg
# rec
open $rec
# lig
open $lig
# waters
#open \$wat
# cofactor
#open $cof
# ion
#open $ion

# move original to gist. it is harder to move the gist grids. 

#match #1&~element.H #0&~element.H
mmaker #0 #1

matrixcopy #1 #2
matrixcopy #1 #3
#matrixcopy #1 #3
#matrixcopy #1 #4
#matrixcopy #1 #5

write format pdb  0 ref.pdb
write format pdb  1 rec_crg_aligned.pdb
write format pdb  2 rec_aligned.pdb
write format pdb  3 lig_aligned.pdb
write format mol2 3 lig_aligned.mol2
#write format pdb  3 cofactor_aligned.pdb
#write format pdb  4 ion_aligned.pdb
EOF
 
${chimerapath} --nogui chimera.com > & chimera.com.out

end #pdb

