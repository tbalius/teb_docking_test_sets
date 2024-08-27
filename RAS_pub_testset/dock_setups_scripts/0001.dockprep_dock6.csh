#!/bin/csh

# Written by Trent Balius, FNLCR 2020, mod from earler scripts from UCSF

#source /home/baliuste/.cshrc.python2
#source /home/baliuste/.cshrc.python3
#source /home/baliuste/.cshrc.DOCK_dev
echo "source /home/baliuste/.bashrc.python3"
echo "source /home/baliuste/.bashrc.DOCK_dev"

set pwd = `pwd`
set mountdir = ${pwd}/..

#set list = `cat pdb_lig_map.txt | awk '{print $1}'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
#set list = `cat pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
set list = `cat ../001.process_prepare_pdb_files/pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo $pdbname
echo $ligname

set workdir = ${pwd}/001.dockprep/${pdbname}_${ligname}/dockprep_sph_grids

## so you don't blow away stuff; continue means STOP here and continue with next pdb from list
if ( -s $workdir ) then
   echo "$workdir exists... continue"
   continue
   #exit
endif

  mkdir -p ${workdir}
  cd ${workdir}

#set rec = ${mountdir}/004_chimera_dockprep_cofori/${pdbname}_${ligname}/rec_complete.mol2 
#set lig = ${mountdir}/004_chimera_dockprep_cofori/${pdbname}_${ligname}/lig_complete.mol2 

#set rec = ${mountdir}/../002.copy_man_mod_for_docking/${pdbname}_${ligname}/rec_complete.mol2 
#set lig = ${mountdir}/../002.copy_man_mod_for_docking/${pdbname}_${ligname}/lig_complete.mol2 

set rec = ${mountdir}/003.files_for_docking/${pdbname}_${ligname}/rec_complete.mol2 
set lig = ${mountdir}/003.files_for_docking/${pdbname}_${ligname}/lig_complete.mol2
set covsph = ${mountdir}/003.files_for_docking/${pdbname}_${ligname}/cov_sph.pdb


cat << EOFSD > submit_dockprep.csh
#!/bin/csh 
#SBATCH -t 4:00:00
#SBATCH --output=stderr

  cd ${workdir}

ln -s ${rec} rec.mol2
ln -s ${lig} xtal-lig.mol2

if ( -e $covsph ) then 
   ln -s ${covsph} cov_sph.pdb
endif

/home/baliuste/zzz.programs/openbabel/install/bin/obabel -d -imol2 rec.mol2 -opdb -O rec.pdb

rm 001.spheres/ 002.grids/ -rf

  mkdir 001.spheres
  cd 001.spheres/

  cp ../rec.pdb rec.pdb
  sed -i 's/HETATM/ATOM  /g' rec.pdb 

  $DOCKBASE/proteins/dms/bin/dms rec.pdb -a -d 0.2 -g dms.log -p -n -o rec.dms

cat <<EOF > INSPH
./rec.dms
R
X
0.0
4.0
1.4
rec.sph
EOF

  /home/baliuste/zzz.github/dock6_main_not_fork/dock6/bin_oel8/sphgen

  /home/baliuste/zzz.github/dock6_main_not_fork/dock6/bin_oel8/sphere_selector rec.sph ../xtal-lig.mol2 4.0 ; mv selected_spheres.sph selected_spheres.4.0.sph
  /home/baliuste/zzz.github/dock6_main_not_fork/dock6/bin_oel8/sphere_selector rec.sph ../xtal-lig.mol2 6.0 ; mv selected_spheres.sph selected_spheres.6.0.sph
  /home/baliuste/zzz.github/dock6_main_not_fork/dock6/bin_oel8/sphere_selector rec.sph ../xtal-lig.mol2 8.0
  python /home/baliuste/zzz.scripts/mol2toSPH_radius.py ../xtal-lig.mol2 xtal-lig.sph


 if ( -e $covsph ) then 
 #grep "SG" ../cov_sph.pdb  > cov_sph_reord.pdb
 #grep "?G" ../cov_sph.pdb  > cov_sph_reord.pdb
 #grep "CB" ../cov_sph.pdb >> cov_sph_reord.pdb
 #grep "CA" ../cov_sph.pdb >> cov_sph_reord.pdb
 grep "^ATOM" ../cov_sph.pdb | tac > cov_sph_reord.pdb

 $DOCKBASE/proteins/pdbtosph/bin/pdbtosph cov_sph_reord.pdb cov_sph.sph
 endif

  cd ../
  mkdir 002.grids/

  cd 002.grids/
  ln -s ../001.spheres/selected_spheres.sph .
  ln -s ../rec.mol2 .

cat <<EOF > showbox.in
Y
8.0
selected_spheres.sph
1
rec.box.pdb
EOF

  /home/baliuste/zzz.github/dock6_main_not_fork/dock6/bin_oel8/showbox < showbox.in

cat <<EOF > grid.in
allow_non_integral_charges     yes
compute_grids                  yes
grid_spacing                   0.3
output_molecule                no
contact_score                  no
energy_score                   yes
energy_cutoff_distance         9999
atom_model                     a
attractive_exponent            6
repulsive_exponent             9
distance_dielectric            yes
dielectric_factor              4
bump_filter                    yes
bump_overlap                   0.75
receptor_file                  rec.mol2
box_file                       rec.box.pdb
vdw_definition_file            /home/baliuste/zzz.github/dock6_main_not_fork/dock6/parameters/vdw_AMBER_parm99.defn 
score_grid_prefix              grid 
EOF

  /home/baliuste/zzz.github/dock6_main_not_fork/dock6/bin_oel8/grid -i grid.in -o grid.out
  cd ../

EOFSD


sbatch submit_dockprep.csh 


end #systpdb
