#!/bin/csh

# create list of db2 files to dock called split_database_index
ls ../build_ligand_dock3/db_build_working/MOV/MOV_*_db2/*.db2.gz > split_database_index

# copy INDOCK file from blastermaster
cp ../dockprep/blastermaster_cof/INDOCK INDOCK.ori 

# symlink dockfiles
ln -s ../dockprep/blastermaster_cof/dockfiles . 

# replace "../dockfiles" with "./dockfiles" 
sed -e 's/\.\.\/dockfiles/.\/dockfiles/g' \
    -e 's/bump_maximum                  10.0/bump_maximum                  1000.0/g' \
    -e 's/bump_rigid                    10.0/bump_rigid                    1000.0/g' \
    -e 's/mol2_score_maximum            -10.0/mol2_score_maximum            1000.0/g' \
    -e 's/dockovalent                   no/dockovalent                   yes/g' \
    -e 's/minimize                      yes/minimize                      no/g' \
    -e 's/check_clashes                 yes/check_clashes                 no/g' \
INDOCK.ori > INDOCK

