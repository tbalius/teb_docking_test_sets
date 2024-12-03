#!/bin/csh
# this script was written by trent balius in the Rizzo Group, 2011
# modified in the Shoichet Group, 2013-2015

# TEB, MF comments -- March 2017
#
# This shell script will do the following:
# (1) aligns the ligand file and nearby waters onto MD frame of reference created in previous script [006gist.cpptraj_mk_ref.csh]
# (2) then writes out the aligned ligand and waters which will be used to calculate center of mass which centers the GIST box.
#  Aligned structures are then also useful for visualizing gist.

set pwd = `pwd`

set list = `cat ../systems.txt | sed 's/ /./g'`
# loop over systems
foreach pdbsys ( $list )

set pdb    = ${pdbsys:r}
set system = ${pdbsys:e}

echo $pdb $system

set filedir = "/mnt/projects/RAS-CompChem/static/work/DUDEZ/dudez_dockprep/${system}_dock6prep/blastermaster/working"
#set filedir = "${pwd}/0001.tleap_reduce_min/${system}"
set workdir = "${pwd}/0004.align_to_md/${system}"

rm -rf $workdir
mkdir -p $workdir
cd $workdir

set ref = "$pwd/0003.ref_rec/${system}/ref.pdb"
#set rec = "$filedir/rec.leap.pdb"
set rec1 = "$filedir/../rec.pdb"
set rec2 = "$filedir/rec.crg.pdb"
set lig = "$filedir/xtal-lig.pdb"

set chimerapath = "/home/baliuste/zzz.programs/Chimera/chimera-1.17.3_oel8/bin/chimera"

#write instruction file for chimera based alignment
cat << EOF > chimera.com
# template
open $ref
# rec.pdb
open $rec1
# rec.crg.pdb
open $rec2
# lig
open $lig

# move original to gist. it is harder to move the gist grids.

#match #1&~element.H #0&~element.H
mmaker #0 #1
matrixcopy #1 #2
matrixcopy #1 #3

write format pdb  0 ref.pdb
write format pdb  1 rec_aligned.pdb
write format pdb  2 rec.crg_aligned.pdb
write format pdb  3 lig_aligned.pdb
write format mol2 3 lig_aligned.mol2
EOF

${chimerapath} --nogui chimera.com > & chimera.com.out

end # system
