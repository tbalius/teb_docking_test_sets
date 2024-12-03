#!/bin/csh

# Written by Trent Balius, FNLCR 2020, mod from earler scripts from UCSF

#source /home/baliuste/.cshrc.python2
#source /home/baliuste/.cshrc.python3
echo "source /home/baliuste/.bashrc.python2"

set pwd = `pwd`

set list = `cat ../systems.txt | sed 's/ /./g'`
# loop over systems
foreach pdbsys ( $list )

set pdb    = ${pdbsys:r}
set system = ${pdbsys:e}

echo $pdb $system

set filedir = ${pwd}/0006.full_gist_combine/${system}
set workdir = ${pwd}/0007.gist_blurr/${system}

if ( -s $workdir ) then
   echo "$workdir exists ... "
   continue
endif

if ! ( -e ${filedir}/gist-EswPlus2Eww_ref_cap.dx ) then
   echo "${filedir}/gist-EswPlus2Eww_ref_cap.dx does not exist ... "
   continue
endif

mkdir -p ${workdir}
cd ${workdir}

ln -s ${filedir}/gist-EswPlus2Eww_ref_cap.dx .

cat << EOF > sub_blurr.csh
#!/bin/csh
python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py gist-EswPlus2Eww_ref_cap.dx 1.0 2.0 1.8 gist-EswPlus2Eww_ref_cap_blurr_1pt0
python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py gist-EswPlus2Eww_ref_cap.dx 1.8 2.0 1.8 gist-EswPlus2Eww_ref_cap_blurr_1pt8

python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py gist-EswPlus2Eww_ref_cap.dx 1.0 1.3 1.8 gist-EswPlus2Eww_ref_cap_blurr_div1p3_1pt0
python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py gist-EswPlus2Eww_ref_cap.dx 1.8 1.3 1.8 gist-EswPlus2Eww_ref_cap_blurr_div1p3_1pt8
EOF

sbatch sub_blurr.csh

end # system
