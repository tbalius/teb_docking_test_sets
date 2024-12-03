#!/bin/csh

# This script will use dock6 for conformational generations. 
# Written by Trent Balius at FNLCR Feb 06 2020. 
#

# step 0. move the center of mass of the ligand to the origin. 
#

 #echo "source ~/.bashrc.python2"
 #source ~tbalius/.cshrc.python2
 source ~baliuste/.cshrc.python2

 set dock6home = "/home/baliuste/zzz.github/dock6_hdb_paper"
 #set dock3home = "/home/baliuste/zzz.github/DOCK"
 set dock3home = "$DOCKBASE"
 set scripthome = "/home/baliuste/zzz.github/teb_scripts_programs/zzz.scripts"
 #set dock6home = "~/zzz.github/dock6"
 #set dock6home = "/nfs/home/tbalius/zzz.github/dock6"
 #set dock3home = "~tbalius/zzz.github/DOCK"
 #set scripthome = "~tbalius/zzz.github/teb_scripts_programs/zzz.scripts"

 #echo "(1) I AM HERE"
 echo "num in argv: " $#argv
 if ($#argv == 3) then
     set sampling = 300
 else if ($#argv == 4) then
     set sampling = $4
 else
     echo " incorrect number of arguments \n mol2file solvfile name file [sampling parm]" 
 endif

 set mol2 = $1
 set solv = $2
 set name = $3

 if ($#argv == 4 ) then
   set int_energy_cutoff = $4
   echo "int_energy_cutoff = $int_energy_cutoff"
 else if ($#argv == 3 ) then
   set int_energy_cutoff = 200
   echo "int_energy_cutoff = $int_energy_cutoff"
 else 
    echo "wrong number of verables (must be 3 or 4): mol2 solv name [int_energy_cutoff]"
    exit
 endif

 echo "mol2file = $mol2"
 python $scripthome/mol2_center_of_mass.py $mol2 center.txt


set tran_move = ""
#set lab = ""
foreach v (`cat center.txt `)
 set val = `echo "$v*-1.0" | bc`
 set tran_move = `echo "$tran_move $val"`
 #set lab = `echo "${lab}_${val}"`
end

 python $scripthome/mol2_translate.py $mol2 center $tran_move

 ls center*.mol2 

 #cp center$lab.mol2 lig.mol2 
 cp center*.mol2 lig.mol2 

 if !($solv == "output.solv") then
    cp $solv output.solv
    cp $name name.txt
 endif

# step 1. run dock once to id anchors (ring). 
#

cat << EOF > dock_get_anchors.in
conformer_search_type                                        flex
write_fragment_libraries                                     no
user_specified_anchor                                        no
limit_max_anchors                                            no
min_anchor_size                                              5
pruning_use_clustering                                       yes
pruning_max_orients                                          1
pruning_clustering_cutoff                                    1
pruning_conformer_score_cutoff                               0.0
pruning_conformer_score_scaling_factor                       1.0
use_clash_overlap                                            no
write_growth_tree                                            no
use_internal_energy                                          no
ligand_atom_file                                             lig.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               no
use_database_filter                                          no
orient_ligand                                                no
bump_filter                                                  no
score_molecules                                              no
atom_model                                                   all
vdw_defn_file                                                ${dock6home}/parameters/vdw_AMBER_parm99.defn
flex_defn_file                                               ${dock6home}/parameters/flex.defn
flex_drive_file                                              ${dock6home}/parameters/flex_drive.tbl
ligand_outfile_prefix                                        output
write_orientations                                           no
num_scored_conformers                                        1
rank_ligands                                                 no
EOF

$dock6home/bin/dock6 -i dock_get_anchors.in -o dock_get_anchors.out -v

# step 2. loop over anchors and make a separate mol2 for each anchor. 


## place on atom at coordenate 100.0 100.0 100.0
#
#cat << EOF > rec.mol2
#@<TRIPOS>MOLECULE
#rec.crg.pdb.fullh.gnp
#1 0 1 0 0
#PROTEIN
#AMBER ff14SB
#
#
#@<TRIPOS>ATOM
#      1 C         100.0000  100.0000  100.0000 C.3       1 DUM    0.0000
#@<TRIPOS>BOND
#@<TRIPOS>SUBSTRUCTURE
#     1 DUM     1 RESIDUE           4 A     DUM     0 ROOT
#EOF

echo "here are the parameters"
#set maxorent      = 500
set maxorent      = 300
#set clustercutoff = 700
#set clustercutoff = 300
set clustercutoff = ${sampling}
set energy_val    = 200.0
#set energy_val    = 30.0
#set energy_val    = 50.0
set writenumber   = 5000
#set rmsdthreshold = 0.1
#set min_tor_step_size = 10
set min_tor_step_size = 5
 set min_num_step = 40
#set min_num_step = 20
echo "$maxorent,$clustercutoff,${energy_val},$writenumber"
#echo "$maxorent,$clustercutoff,${energy_val},$writenumber,$rmsdthreshold"


#interal_score_primary                                        yes
cat << EOF > dock_confgen.in 
conformer_search_type                                        flex
write_fragment_libraries                                     no
user_specified_anchor                                        yes
atom_in_anchor                                               #ATOM
pruning_use_clustering                                       yes
pruning_max_orients                                          ${maxorent}
pruning_clustering_cutoff                                    ${clustercutoff}
pruning_conformer_score_cutoff                               ${energy_val}
pruning_conformer_score_scaling_factor                       1.0
use_clash_overlap                                            no
write_growth_tree                                            no
use_internal_energy                                          no
ligand_atom_file                                             lig.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               no
use_database_filter                                          no
orient_ligand                                                no
bump_filter                                                  no
score_molecules                                              yes
contact_score_primary                                        no
grid_score_primary                                           no
multigrid_score_primary                                      no
dock3.5_score_primary                                        no
continuous_score_primary                                     no
footprint_similarity_score_primary                           no
pharmacophore_score_primary                                  no
hbond_score_primary                                          no
internal_energy_score_primary                                yes
internal_energy_rep_exp                                      12
minimize_ligand                                              yes
minimize_anchor                                              no
minimize_flexible_growth                                     yes
use_advanced_simplex_parameters                              no
simplex_max_cycles                                           1
simplex_score_converge                                       0.1
simplex_cycle_converge                                       1.0
simplex_trans_step                                           1.0
simplex_rot_step                                             0.1
simplex_tors_step                                            ${min_tor_step_size}
simplex_grow_max_iterations                                  0
simplex_grow_tors_premin_iterations                          ${min_num_step}
simplex_random_seed                                          0
simplex_restraint_min                                        yes
simplex_coefficient_restraint                                100
atom_model                                                   all
vdw_defn_file                                                ${dock6home}/parameters/vdw_AMBER_parm99.defn
flex_defn_file                                               ${dock6home}/parameters/flex_mod.defn
flex_drive_file                                              ${dock6home}/parameters/flex_drive_mod.tbl
ligand_outfile_prefix                                        output_#NAME
write_mol_solvation                                          no
write_orientations                                           no
num_scored_conformers                                        ${writenumber}
write_conformations                                          no
cluster_conformations                                        no
score_threshold                                              ${energy_val}
rank_ligands                                                 no
EOF
#cluster_rmsd_threshold                                       ${rmsdthreshold}

grep "ANCHOR #.:" dock_get_anchors.out

set list = `grep "ANCHOR #.:" dock_get_anchors.out | awk '{print $3}'`

#echo conda activate complete
#echo source ~/.bashrc.python3
#source ~/.cshrc.python3
 which python
 #source ~tbalius/.cshrc.python3
 source ~baliuste/.cshrc.python3

 which python
set count = 1
foreach anchor ($list)
  sed -e "s/#ATOM/$anchor/g" -e "s/#NAME/anchor$count/g" dock_confgen.in > dock_confgen_anchor$count.in
  ${dock6home}/bin/dock6 -i dock_confgen_anchor$count.in -o dock_confgen_anchor$count.out -v

  if ( -z output_anchor${count}_scored.mol2 || !(-e output_anchor${count}_scored.mol2) ) then
     echo "file output_anchor${count}_scored.mol2 is zero lenth or does not exist.  "
  else
     echo "file output_anchor${count}_scored.mol2 is non-empty. "
     #python ${dock3home}/ligand/mol2db2/mol2db2.py -m output_anchor${count}_scored.mol2 -s output.solv -n name.txt -o output_anchor${count}_scored.db2.gz -v
     #python ${dock3home}/ligand/mol2db2/mol2db2.py --norotateh -m output_anchor${count}_scored.mol2 -s output.solv -n name.txt -o output_anchor${count}_scored.db2.gz -v
     #sed -e 's/##########                      Internal_Score:/mmff94s/g' output_anchor${count}_scored.mol2 > output_anchor${count}_scored_mod.mol2
     awk  '{if ($2== "Internal_Score:"){energy = $3};if($1=="@<TRIPOS>MOLECULE"){printf"%s\n mmff94s = %f\n",$0,energy;}else{print $0}}' output_anchor${count}_scored.mol2 > output_anchor${count}_scored_mod.mol2
     python ${dock3home}/ligand/mol2db2/mol2db2.py --norotateh -m output_anchor${count}_scored_mod.mol2 -s output.solv -n name.txt -o output_anchor${count}_scored.db2.gz -v
  endif

  @ count = $count + 1
end


