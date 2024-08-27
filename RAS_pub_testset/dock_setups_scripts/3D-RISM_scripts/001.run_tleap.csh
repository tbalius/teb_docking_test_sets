#!/bin/csh

#source /home/baliuste/.cshrc.python2
echo "source /home/baliuste/.bashrc.python2"
echo "source /home/baliuste/zzz.programs/amber/amber22_ambertools23/amber22/amber.sh" 

set pwd = `pwd`
set filedir = /mnt/projects/RAS-CompChem/static/Stanley/RAS_pub_testset/KRAS
set scriptdir = /mnt/projects/RAS-CompChem/static/Stanley/scripts

#set list = `cat ../pdbdirlist.txt` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
#set list = `cat pdblist.txt` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
set list = `cat ${filedir}/001.process_prepare_pdb_files/pdb_lig_map.txt | sed 's/ /./g'` # or use `cat filename` to list your pdb codes here from a text file like pdblist_rat, to loop over each variable (pdb code) later
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )

set pdbname = ${pdblig:r}
set ligname = ${pdblig:e}

echo $pdbname
echo $ligname

set workdir = ${pwd}/${pdbname}_${ligname}/tleap

if (-s $workdir) then
  echo "$workdir exists... continue"
  continue
endif

mkdir -p $workdir
cd $workdir

cat ${filedir}/004.dock_setups/003.blastermaster_manualProt/${pdbname}_${ligname}/blastermaster_cof/working/rec.crg.pdb | grep -v OXT > rec_ori.pdb
python ${scriptdir}/add_ter_before_cof.py rec_ori.pdb rec.pdb

#sed -i 's/HIE/HID/g' rec.pdb

#cat << EOF >! tleap.rec.in
#set default PBradii mbondi2
## load the protein force field
#
#source leaprc.protein.ff14SB
##source leaprc.phosaa10
##source leaprc.phosaa14SB
##source leaprc.water.tip3p
### load ions
##loadAmberParams frcmod.ions234lm_1264_tip3p
#
#REC = loadpdb rec.pdb
#saveamberparm REC rec.leap.prm7 rec.leap.rst7
#quit
#EOF

cat << EOF >! tleap.rec.in
set default PBradii mbondi2
# load the protein force field

source leaprc.protein.ff14SB
#source leaprc.phosaa10
#source leaprc.phosaa14SB
source leaprc.water.tip3p
## load ions
source leaprc.gaff2
loadAmberParams frcmod.ions234lm_1264_tip3p
loadamberparams ${filedir}/003.files_for_docking/${pdbname}_${ligname}/amber_cof_parm/cof.1.ante.charg.frcmod

loadamberprep ${filedir}/003.files_for_docking/${pdbname}_${ligname}/amber_cof_parm/cof.1.ante.charg.prep 

REC = loadpdb rec.pdb
saveamberparm REC rec.leap.prm7 rec.leap.rst7
quit
EOF
# runs tleap and converts parameter and coordinate restart file back into pdb file


# --traj fxa-strip.nc --xvv cTIP3P_pse3.xvv \
# --solvcut 999999. --buffer 24. --tolerance 1e-2,1e-6 \

cat << EOF > run_tleap_rism.csh
#!/bin/csh

$AMBERHOME/bin/tleap -s -f tleap.rec.in > ! tleap.rec.out
$AMBERHOME/bin/ambpdb -p rec.leap.prm7 < rec.leap.rst7 > rec.leap.pdb
EOF

#$AMBERHOME/bin/rism3d.snglpnt \
# --pdb rec.leap.pdb --prmtop rec.leap.prm7 \
# --rst rec.leap.rst7 --xvv ../cTIP3P_pse3.xvv \
# --entropicDecomp --molReconstruct \
# --guv g \
# --exchem exchem --entropy entropy --solvene solvene --potUV potUV \
# --exchemUC exchemUC \
# --solvcut 999999. --buffer 24. --tolerance 1e-2,1e-6 \
# --closure kh,pse2,pse3 --uccoeff 0.0327564,-3.26166,-0.000507492,0.0100166 \
# --mdiis_restart 100.0 --mdiis_nvec 10\
# --maxstep 10000 \
# --centering 3 \
# --volfmt dx \
# --verbose 2 > rism.out
#
#EOF

sbatch run_tleap_rism.csh

#exit # csh
#exit # bash

end # pdb

