#!/bin/csh

#source /home/baliuste/.cshrc.python2
echo "source /home/baliuste/.bashrc.python2"
echo "source /home/baliuste/zzz.programs/amber/amber22_ambertools23/amber22/amber.sh" 

set filedir = /mnt/projects/RAS-CompChem/static/Stanley/RAS_pub_testset/KRAS
set pwd = `pwd`

set list = `cat $1 | sed 's/ /_/g'`
# loop over pdbnames e.g. 1DB1 or list
foreach pdblig ( $list )
echo $pdblig

set mountdir = ${pwd}/${pdblig}
set workdir = ${mountdir}/10.calc_3drism

if (-s $workdir) then
  echo "$workdir exists ... continue"
  continue
endif

mkdir $workdir
cd $workdir

cp ${mountdir}/08.blastermaster_gist_aligned/working/rec.crg.pdb rec.pdb

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
loadamberparams ${filedir}/003.files_for_docking/${pdblig}/amber_cof_parm/cof.1.ante.charg.frcmod

loadamberprep ${filedir}/003.files_for_docking/${pdblig}/amber_cof_parm/cof.1.ante.charg.prep 

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

$AMBERHOME/bin/rism3d.snglpnt \
 --pdb rec.leap.pdb --prmtop rec.leap.prm7 \
 --rst rec.leap.rst7 --xvv ${pwd}/cTIP3P_pse3.xvv \
 --entropicDecomp --molReconstruct \
 --guv g \
 --exchem exchem --entropy entropy --solvene solvene --potUV potUV \
 --exchemUC exchemUC \
 --solvcut 999999. --buffer 24. --tolerance 1e-2,1e-6 \
 --closure kh,pse2,pse3 --uccoeff 0.0327564,-3.26166,-0.000507492,0.0100166 \
 --mdiis_del 0.5 --mdiis_restart 1000.0 --mdiis_nvec 40\
 --maxstep 10000 \
 --centering 3 \
 --volfmt dx \
 --verbose 2 > rism.out
EOF

sbatch run_tleap_rism.csh

#exit # csh
#exit # bash

end #pdb
