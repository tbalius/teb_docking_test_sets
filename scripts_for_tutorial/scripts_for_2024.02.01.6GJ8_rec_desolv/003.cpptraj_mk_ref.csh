#!/bin/csh
## This script writes out the last frame of the 10md trajectory as a reference pdb to which we can align.
## Ref is also a useful visual reference when visualizing gist.

## TEB / MF comments -- March 2017
#setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber18
setenv AMBERHOME /home/baliuste/zzz.programs/amber/amber22_ambertools23/amber22

set pwd = `pwd`
set workdir = ${pwd}/03.ref_rec
set parm = rec.watbox.leap.prm7

rm -rf $workdir
mkdir -p $workdir
cd $workdir

set jobId = `grep '/tmp/' ${pwd}/02.MDrun_rec/stdout | head -1 | awk -F\/ '{print $4}'`
ln -s ${pwd}/02.MDrun_rec/${jobId} .

cat << EOF >! makeref.in 
parm ${jobId}/${parm} 
trajin ${jobId}/10md.rst7 1 1 
strip :WAT
trajout ref.pdb pdb
trajout ref.mol2 mol2 sybyltype
go
EOF

$AMBERHOME/bin/cpptraj -i makeref.in > ! makeref.log &

