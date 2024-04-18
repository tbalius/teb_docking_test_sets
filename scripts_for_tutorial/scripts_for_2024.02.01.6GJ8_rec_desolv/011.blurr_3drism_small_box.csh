#!/bin/csh

# Written by Trent Balius, FNLCR 2020, mod from earler scripts from UCSF

#source /home/baliuste/.cshrc.python2
#source /home/baliuste/.cshrc.python3
echo "source /home/baliuste/.bashrc.python2"

set pwd = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts 
set workdir = ${pwd}/11.cap_smallbox_blurr_3drism

## so you don't blow away stuff; continue means STOP here and continue with next pdb from list
if ( -s $workdir ) then
   echo "$workdir exists"
   rm -rf $workdir
   #continue
   #exit
endif

mkdir -p ${workdir}
cd ${workdir}

# use 'mol' for molecular reconstruction
ln -s ${pwd}/10.calc_3drism/potUV.1.dx ./potUV.dx
#ln -s ${pwd}/10.calc_3drism/potUV.mol.1.dx ./potUV.dx

ln -s ${pwd}/09.dock3todock6/box box.pdb

cat << EOF > sub_blurr.csh
#!/bin/csh
python2 /home/baliuste/zzz.github/GIST_DX_tools/src/dx-remove_extrema.py potUV.dx 100.0 potUV_cap100 > truncate.log
python2 /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_subset_box.py potUV_cap100.dx box.pdb 5.0 potUV_cap100_smallbox  > truncate.log
python2 /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py potUV_cap100_smallbox.dx 1.0 2.0 1.8 potUV_cap100_blurr_1pt0
python2 /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py potUV_cap100_smallbox.dx 1.8 2.0 1.8 potUV_cap100_blurr_1pt8
EOF

#csh sub_blurr.csh
sbatch sub_blurr.csh

