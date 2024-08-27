#!/bin/csh

# Written by Trent Balius, FNLCR 2020, mod from earler scripts from UCSF

#source /home/baliuste/.cshrc.python2
#source /home/baliuste/.cshrc.python3
echo "source /home/baliuste/.bashrc.python2"

set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts 
set pwd = `pwd`

set list = `cat $1 | sed 's/ /_/g'`
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )
echo $pdblig

set mountdir = ${pwd}/${pdblig}
#set workdir = ${mountdir}/11.cap_smallbox_blurr_3drism
#set workdir = ${mountdir}/11.cap_smallbox_blurr_3drism_mol
#set workdir = ${mountdir}/11.cap_smallbox_blurr_3drism_solvene
set workdir = ${mountdir}/11.cap_smallbox_blurr_3drism_exchem

## so you don't blow away stuff; continue means STOP here and continue with next pdb from list
if ( -s $workdir ) then
   echo "$workdir exists"
   rm -rf $workdir
   #continue
   #exit
endif

#if ! ( -e ${mountdir}/10.calc_3drism/potUV.1.dx ) then
#   echo "${mountdir}/10.calc_3drism/potUV.1.dx does not exist"
#   continue
#endif

#if ! ( -e ${mountdir}/10.calc_3drism/potUV.mol.1.dx ) then
#   echo "${mountdir}/10.calc_3drism/potUV.mol.1.dx does not exist"
#   continue
#endif

#if ! ( -e ${mountdir}/10.calc_3drism/solvene.1.dx ) then
#   echo "${mountdir}/10.calc_3drism/solvene.1.dx does not exist"
#   continue
#endif

if ! ( -e ${mountdir}/10.calc_3drism/exchem.1.dx ) then
   echo "${mountdir}/10.calc_3drism/exchem.1.dx does not exist"
   continue
endif

  mkdir -p ${workdir}
  cd ${workdir}

#ln -s ${mountdir}/10.calc_3drism/potUV.1.dx .
#ln -s ${mountdir}/10.calc_3drism/potUV.mol.1.dx .
#ln -s ${mountdir}/10.calc_3drism/solvene.1.dx .
ln -s ${mountdir}/10.calc_3drism/exchem.1.dx .
ln -s ${mountdir}/09.dock3todock6/box box.pdb

#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_subset_box.py potUV_cap100.dx box.pdb 1.8 potUV_cap100_smallbox  > truncate.log

#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-remove_extrema.py potUV.1.dx 100.0 potUV_cap100 > truncate.log
#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_subset_box.py potUV_cap100.dx box.pdb 5.0 potUV_cap100_smallbox  > truncate.log
#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py potUV_cap100_smallbox.dx 1.0 2.0 1.8 potUV_cap100_blurr_1pt0
#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py potUV_cap100_smallbox.dx 1.8 2.0 1.8 potUV_cap100_blurr_1pt8

#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-remove_extrema.py potUV.mol.1.dx 100.0 potUV_mol_cap100 > truncate.log
#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_subset_box.py potUV_mol_cap100.dx box.pdb 5.0 potUV_mol_cap100_smallbox  > truncate.log
#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py potUV_mol_cap100_smallbox.dx 1.0 2.0 1.8 potUV_mol_cap100_blurr_1pt0
#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py potUV_mol_cap100_smallbox.dx 1.8 2.0 1.8 potUV_mol_cap100_blurr_1pt8

#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-remove_extrema.py solvene.1.dx 100.0 solvene_cap100 > truncate.log
#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_subset_box.py solvene_cap100.dx box.pdb 5.0 solvene_cap100_smallbox  > truncate.log
#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py solvene_cap100_smallbox.dx 1.0 2.0 1.8 solvene_cap100_blurr_1pt0
#python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py solvene_cap100_smallbox.dx 1.8 2.0 1.8 solvene_cap100_blurr_1pt8

cat << EOF > sub_blur.csh
#!/bin/csh
python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-remove_extrema.py exchem.1.dx 100.0 exchem_cap100 > truncate.log
python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_subset_box.py exchem_cap100.dx box.pdb 5.0 exchem_cap100_smallbox  > truncate.log
python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py exchem_cap100_smallbox.dx 1.0 2.0 1.8 exchem_cap100_blurr_1pt0
python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py exchem_cap100_smallbox.dx 1.8 2.0 1.8 exchem_cap100_blurr_1pt8
EOF

sbatch sub_blur.csh

end #pdb
