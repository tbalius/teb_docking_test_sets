#!/bin/csh 

## TEB/ MF comments -- March 2017

set pwd = `pwd`

set list = `cat $1 | sed 's/ /_/g'`
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )
echo $pdblig

#set mountdir = "/mnt/nfs/work/users/tbalius/Water_Project/run_DOCK3.7"
#set mountdir = `pwd`
set mountdir = ${pwd}/${pdblig}

#set system = lig 
#set system = mcwat_com 
#set system = com 
set system = rec 

set workdir   = $mountdir/06a.full_gist_combine_${system}
set filedir   = $mountdir/05a.full_gist_${system}
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

  python ${scriptdir}/dx-combine_grids.py gist-Eww-dens.dx       1.0 gist-gO.dx               \${A14const1} 0.0 gist-dEww-dens_ref
  python ${scriptdir}/dx-combine_grids.py gist-Esw-dens.dx       1.0 gist-dEww-dens_ref.dx    1.0           0.0 gist-EswPlusEww_ref
  python ${scriptdir}/dx-combine_grids.py gist-dTSorient-dens.dx 1.0 gist-dTStrans-dens.dx    1.0           0.0 gist-TSsw
  python ${scriptdir}/dx-combine_grids.py gist-EswPlusEww_ref.dx 1.0 gist-TSsw.dx            -1.0           0.0 gist-Gtot1_ref

  python ${scriptdir}/dx-combine_grids.py gist-Esw-dens.dx        1.0 gist-dEww-dens_ref.dx   2.0           0.0 gist-EswPlus2Eww_ref    #<<THIS GUY
  python ${scriptdir}/dx-combine_grids.py gist-EswPlus2Eww_ref.dx 1.0 gist-TSsw.dx           -1.0           0.0 gist-Gtot2_ref

  # truncate points
  python ${scriptdir}/dx-remove_extrema.py gist-EswPlus2Eww_ref.dx 3.0 gist-EswPlus2Eww_ref_cap > truncate.log

  # apply density cutoff.
  #python ${scriptdir}/dx-density-threshold.py gist-EswPlusEww_ref2.dx gist-gO.dx 5.0 gist-EswPlusEww_ref2_threshold5.0
  
  # norm grids.
  #python ${scriptdir}/dx-divide_grids.py gist-Eww-dens.dx gist-gO.dx 0.0329 gist-Eww-norm
  #python ${scriptdir}/dx-combine_grids.py gist-Eww-norm.dx 1.0 gist-gO.dx 0.0 "-9.533" gist-Eww-norm-ref

EOF

#qsub qsub_full.csh 
csh qsub_full.csh 

end #pdb
