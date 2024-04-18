#!/bin/csh 

## TEB/ MF comments -- March 2017

#source /home/baliuste/.cshrc.python2
#source /home/baliuste/.cshrc.python3
echo "source /home/baliuste/.bashrc.python2"

set pwd = `pwd`

#set mountdir = "/mnt/nfs/work/users/tbalius/Water_Project/run_DOCK3.7"
set mountdir = `pwd`
set workdir   = $mountdir/06.full_gist_combine_rec
set filedir   = $mountdir/05.full_gist_rec
set scriptdir = /home/baliuste/zzz.github/GIST_DX_tools/src

rm -rf  ${workdir}
mkdir ${workdir}
cd ${workdir}

cp $filedir/gist-dTSorient-dens.dx .
cp $filedir/gist-dTStrans-dens.dx .
cp $filedir/gist-Esw-dens.dx .
cp $filedir/gist-Eww-dens.dx .

# this is the density of the water.
cp $filedir/gist-gO.dx .


cat <<EOF > qsub_full.csh
#!/bin/csh 
#\$ -cwd
#\$ -j yes
#\$ -o stderr
#\$ -q all.q

  cd ${workdir}
 # make a combination of the grids
 # We think that we should be substracting
 # Remove comment from top of line

 # tip3p and amber 18
 # TIP3P -9.533 0.0329 # amber 18 manual.

  set bulkE = "-9.533" # kcal/mol/water
  set numberdensity = "0.0329" # waters/(angstroms^3)
  set A14const1 = \`echo "scale=4; -1.0 * \${bulkE} * \${numberdensity}" | bc\`
  # -0.3184 should be positive -*- = +

  python2 ${scriptdir}/dx-combine_grids.py gist-Eww-dens.dx       1.0 gist-gO.dx               \${A14const1} 0.0 gist-dEww-dens_ref
  python2 ${scriptdir}/dx-combine_grids.py gist-Esw-dens.dx       1.0 gist-dEww-dens_ref.dx    1.0           0.0 gist-EswPlusEww_ref
  python2 ${scriptdir}/dx-combine_grids.py gist-dTSorient-dens.dx 1.0 gist-dTStrans-dens.dx    1.0           0.0 gist-TSsw
  python2 ${scriptdir}/dx-combine_grids.py gist-EswPlusEww_ref.dx 1.0 gist-TSsw.dx            -1.0           0.0 gist-Gtot1_ref

  python2 ${scriptdir}/dx-combine_grids.py gist-Esw-dens.dx        1.0 gist-dEww-dens_ref.dx   2.0           0.0 gist-EswPlus2Eww_ref    #<<THIS GUY
  python2 ${scriptdir}/dx-combine_grids.py gist-EswPlus2Eww_ref.dx 1.0 gist-TSsw.dx           -1.0           0.0 gist-Gtot2_ref

  # truncate points
  python2 ${scriptdir}/dx-remove_extrema.py gist-EswPlus2Eww_ref.dx 3.0 gist-EswPlus2Eww_ref_cap > truncate.log

  # apply density cutoff.
  #python2 ${scriptdir}/dx-density-threshold.py gist-EswPlusEww_ref2.dx gist-gO.dx 5.0 gist-EswPlusEww_ref2_threshold5.0
  
  # norm grids.
  #python2 ${scriptdir}/dx-divide_grids.py gist-Eww-dens.dx gist-gO.dx 0.0329 gist-Eww-norm
  #python2 ${scriptdir}/dx-combine_grids.py gist-Eww-norm.dx 1.0 gist-gO.dx 0.0 "-9.533" gist-Eww-norm-ref

EOF

#qsub qsub_full.csh 
csh qsub_full.csh 

