#!/bin/csh
## This script writes out the last frame of the 10md trajectory as a reference pdb to which we can align.
## Ref is also a useful visual reference when visualizing gist.

## TEB / MF comments -- March 2017
#setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber18
setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber22_ambertools23/amber22

set pwd = `pwd`

set list = `cat ../systems.txt | sed 's/ /./g'`
# loop over systems
foreach pdbsys ( $list )

set pdb    = ${pdbsys:r}
set system = ${pdbsys:e}

echo $pdb $system

set filedir = ${pwd}/0002.MDrun_rec/${system}
set workdir = ${pwd}/0003.ref_rec/${system}

rm -rf $workdir
mkdir -p $workdir
cd $workdir

set jobId = `grep '/tmp/' ${filedir}/stdout | head -1 | awk -F\/ '{print $4}'`
ln -s ${filedir}/${jobId} .

set parm = rec.watbox.leap.prm7

cat << EOF >! makeref.in 
parm ${jobId}/${parm} 
trajin ${jobId}/09md.rst7 1 1 
strip :WAT
trajout ref.pdb pdb
trajout ref.mol2 mol2 sybyltype
go
EOF

$AMBERHOME/bin/cpptraj -i makeref.in > ! makeref.log &

end # system

