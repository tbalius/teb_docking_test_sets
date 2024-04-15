#!/bin/csh

set chimerapath = /home/baliuste//zzz.programs/Chimera/chimera-1.17.3_oel8/bin # CHANGE THIS. Replace with your Chimera path.

cat << EOF > chimera.com
open ../dockprep/lig.pdb
write format mol2 #0 ref.mol2
open covalent.out_scored.mol2
del #1@D1
del #1@D2
write format mol2 #1 covalent.out_scored_noDu.mol2
EOF

${chimerapath}/chimera --nogui chimera.com >& chimera.out

python mol2_replace_sybyl_with_ele.py ref.mol2 ref_ele.mol2
python multimol2_removeH.py ref_ele.mol2 ref_ele_noH.mol2
python mol2_replace_sybyl_with_ele.py covalent.out_scored_noDu.mol2 covalent.out_scored_noDu_ele.mol2
python multimol2_removeH.py covalent.out_scored_noDu_ele.mol2 covalent.out_scored_noDu_ele_noH.mol2

cat << EOF > rmsd.in
conformer_search_type                                        rigid
use_internal_energy                                          no
ligand_atom_file                                             covalent.out_scored_noDu_ele_noH.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               yes
use_rmsd_reference_mol                                       yes
rmsd_reference_filename                                      ref_ele.mol2
use_database_filter                                          no
orient_ligand                                                no
bump_filter                                                  no
score_molecules                                              no
atom_model                                                   all
vdw_defn_file                                                /home/baliuste/zzz.github/dock6_main_not_fork/dock6/parameters/vdw_AMBER_parm99.defn
flex_defn_file                                               /home/baliuste/zzz.github/dock6_main_not_fork/dock6/parameters/flex.defn
flex_drive_file                                              /home/baliuste/zzz.github/dock6_main_not_fork/dock6/parameters/flex_drive.tbl
ligand_outfile_prefix                                        rmsd_output
write_orientations                                           no
num_scored_conformers                                        1
rank_ligands                                                 no
EOF

/home/baliuste/zzz.github/dock6_main_not_fork/dock6/bin/dock6 -i rmsd.in -o rmsd.out

grep "HA_RMSDh:" rmsd_output_scored.mol2

