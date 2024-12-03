#!/bin/csh

set pwd = `pwd`
set scriptdir = /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts 
set filedir = /mnt/projects/RAS-CompChem/static/Stanley/RAS_pub_testset/KRAS ## modify this line!

set list = `cat ../systems.txt | sed -e 's/ /./g'`
foreach pdbsys ( $list )

set pdb    = ${pdbsys:r}
set system = ${pdbsys:e}

echo $pdb $system

set filedir = ${pwd}/0009.dock3todock6/${system}
set workdir = ${pwd}/0010.random_spheres/${system}

# check if workdir exists
if ( -s $workdir ) then
   echo "$workdir exists ... "
   continue
endif

mkdir -p ${workdir}
cd ${workdir}

cp ${filedir}/matching_spheres.sph .

@ i = 1

while ($i <= 10)

python /home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts/make_random_sph.py matching_spheres.sph 0.5 random_spheres_${i}.sph

@ i += 1

end # spheres

end # system

