#!/bin/csh

# Written by Trent Balius, FNLCR 2020, mod from earler scripts from UCSF

#source /home/baliuste/.cshrc.python2
#source /home/baliuste/.cshrc.python3
echo "source /home/baliuste/.bashrc.python2"

set pwd = `pwd`
set scriptdir = /home/baliuste/zzz.github/GIST_DX_tools/src
set filedir = ${pwd}/06.full_gist_combine_rec
set workdir = ${pwd}/07.gist_cap_blurr

if ( -s $workdir ) then
   echo "$workdir exists"
   exit
endif

mkdir -p ${workdir}
cd ${workdir}

if ! ( -e ${filedir}/gist-EswPlus2Eww_ref.dx ) then
   echo "${filedir}/gist-EswPlus2Eww_ref.dx does not exist"
   exit
endif

ln -s ${filedir}/gist-EswPlus2Eww_ref_cap.dx .

cat << EOF > sub_blurr.csh
#!/bin/csh
python2 ${scriptdir}/dx-gist_precalculate_sphere_gausian.py gist-EswPlus2Eww_ref_cap.dx 1.0 2.0 1.8 gist-EswPlus2Eww_ref_cap_blurr_1pt0
python2 ${scriptdir}/dx-gist_precalculate_sphere_gausian.py gist-EswPlus2Eww_ref_cap.dx 1.8 2.0 1.8 gist-EswPlus2Eww_ref_cap_blurr_1pt8
EOF

#csh sub_blurr.csh
sbatch sub_blurr.csh

