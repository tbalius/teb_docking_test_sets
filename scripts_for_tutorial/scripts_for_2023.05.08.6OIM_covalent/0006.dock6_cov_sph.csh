#!/bin/csh

setenv DOCKBASE "/home/baliuste/zzz.github/DOCK" # CHANGE ME.  Replace this with your DOCK 3 location.

set pwd = `pwd`
set workdir = ${pwd}/dock6_cov_spheres

mkdir $workdir
cd $workdir

grep "SG  CYS A  12" ${pwd}/blastermaster_cof/rec.pdb >  cov_sph.pdb
grep "CB  CYS A  12" ${pwd}/blastermaster_cof/rec.pdb >> cov_sph.pdb
grep "CA  CYS A  12" ${pwd}/blastermaster_cof/rec.pdb >> cov_sph.pdb

$DOCKBASE/proteins/pdbtosph/bin/pdbtosph cov_sph.pdb cov_sph.sph

