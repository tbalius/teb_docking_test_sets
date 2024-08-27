#!/bin/csh

# Written by Trent Balius, FNLCR 2020, mod from earler scripts from UCSF

#source /home/baliuste/.cshrc.python2
#source /home/baliuste/.cshrc.python3
echo "source /home/baliuste/.bashrc.python2"

set pwd = `pwd`

set list = `cat $1 | sed 's/ /_/g'`
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )
echo $pdblig

set mountdir = ${pwd}/${pdblig}
set workdir = ${mountdir}/07.gist_cap_blurr

if ( -s $workdir ) then
   echo "$workdir exists"
   exit
endif

if ! ( -e ${mountdir}/06a.full_gist_combine_rec/gist-EswPlus2Eww_ref.dx ) then
   echo "${mountdir}/06a.full_gist_combine_rec/gist-EswPlus2Eww_ref.dx does not exist"
   exit
endif

mkdir -p ${workdir}
cd ${workdir}

ln -s ${mountdir}/06a.full_gist_combine_rec/gist-EswPlus2Eww_ref_cap.dx .

cat << EOF > sub_blur.csh
#!/bin/csh
python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py gist-EswPlus2Eww_ref_cap.dx 1.0 2.0 1.8 gist-EswPlus2Eww_ref_cap_blurr_1pt0
python /home/baliuste/zzz.github/GIST_DX_tools/src/dx-gist_precalculate_sphere_gausian.py gist-EswPlus2Eww_ref_cap.dx 1.8 2.0 1.8 gist-EswPlus2Eww_ref_cap_blurr_1pt8
EOF

sbatch sub_blur.csh

end #pdb
