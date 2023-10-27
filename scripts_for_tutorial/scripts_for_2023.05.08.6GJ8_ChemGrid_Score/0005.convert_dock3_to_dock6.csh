#!/bin/csh 

# Written by Trent Balius, 2022. 
# this script converts files into DOCK6 formate from DOCK3.7.  

set mountdir = `pwd`

set filedir0 = ${mountdir}/blastermaster_cof
set filedir = ${filedir0}/working
set filedir2 = ${filedir0}/dockfiles

#set workdir = $mountdir/dock6files
set workdir = ${filedir0}/dock6files
mkdir $workdir
cd $workdir

cp $filedir/vdw.* .
cp $filedir/box .
cp $filedir/qnifft.electrostatics.phi .
cp ${filedir2}/trim.electrostatics.phi .
cp $filedir/matching_spheres.sph .
cp $filedir2/ligand.desolv.* . 
cp $filedir0/INDOCK .

 ln -s vdw.bmp chem.bmp
 ln -s vdw.vdw chem.vdw
 ln -s vdw.esp chem.esp
 #ln -s qnifft.electrostatics.phi rec+sph.phi
 #ln -s trim.electrostatics.phi rec+sph.phi
 ln -s trim.electrostatics.phi chem.phi

 set dsize = `grep delphi_nsize INDOCK | awk '{print $2}'`

cat << EOF > gconv.in
compute_grids                  yes
DOCK3_7_grids                  yes
grid_spacing                   0.2
phi_grid_size                  $dsize
output_molecule                no
contact_score                  no
contact_cutoff_distance        4.5
chemical_score                 yes
energy_score                   yes
energy_cutoff_distance         10
atom_model                     u
attractive_exponent            6
repulsive_exponent             12
distance_dielectric            yes
dielectric_factor              4
bump_filter                    yes
bump_overlap                   0.5
receptor_file                  rec.crg
box_file                       box
vdw_definition_file            /home/baliuste/zzz.github/dock6/parameters/vdw_AMBER_parm94.defn
chemical_definition_file       /home/baliuste/zzz.github/dock6/parameters/chemgrid/conv.defn
score_grid_prefix              chem
EOF

# this script uses a developmental version of DOCK6.9.  code will be release in a future version of DOCK.  Like DOCK 6.11 or 6.12.  
# replace the parameter file paths in gconv.in and the call to grid-convert with the correct path for your installation of DOCK 6

  /home/baliuste/zzz.github/dock6/bin/grid-convert -i gconv.in > gconv.log

