#!/bin/csh

setenv DOCKBASE "/home/baliuste/zzz.github/DOCK" # CHANGE ME.  Replace this with your DOCK 3 location.
mkdir dock6_cov_spheres

cd dock6_cov_spheres

grep "SG  CYS A  12" ../blastermaster_cof/rec.pdb >  cov_sph.pdb
grep "CB  CYS A  12" ../blastermaster_cof/rec.pdb >> cov_sph.pdb
grep "CA  CYS A  12" ../blastermaster_cof/rec.pdb >> cov_sph.pdb

$DOCKBASE/proteins/pdbtosph/bin/pdbtosph cov_sph.pdb cov_sph.sph

