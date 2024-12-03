#!/bin/csh 

# This script runs Ryan's blastermaster python masterscript for generating everything that dock needs, i.e. grids, spheres
# Run on sgehead as jobs are submitted to the queue
#source ~/.tcshrc.python2
#source /home/baliuste/.cshrc.python3
#source /home/baliuste/.cshrc.DOCK_dev
echo "source /home/balisute/.bashrc.python3"
echo "source /home/baliuste/.bashrc.DOCK_dev"

set pwd = `pwd`

set list = `cat ../systems.txt | sed 's/ /./g'`
# loop over systems
foreach pdbsys ( $list )

set pdb    = ${pdbsys:r}
set system = ${pdbsys:e}

echo $pdb $system

set filedir = /mnt/projects/RAS-CompChem/static/work/DUDEZ/dudez_dockprep/${system}_dock6prep/blastermaster/working
set workdir = ${pwd}/0008.blastermaster_gist_aligned/${system}

if ( -s $workdir ) then
   echo "$workdir exists ... "
   continue
endif

mkdir -p $workdir
cd $workdir

#set TEB_SCRIPTS_PATH = /home/baliuste/zzz.github/teb_scripts_programs

if !( -e ${pwd}/0004.align_to_md/${system} ) then
    echo " ${pwd}/0004.align_to_md/${system} does not exist ... "
    continue
endif

cat ${pwd}/0004.align_to_md/${system}/rec.crg_aligned.pdb | sed -e 's/HETATM/ATOM  /g' | grep "^ATOM " > rec.crg.pdb
cat ${pwd}/0004.align_to_md/${system}/rec_aligned.pdb | sed -e 's/HETATM/ATOM  /g' | grep "^ATOM "     > rec.pdb
cat ${pwd}/0004.align_to_md/${system}/lig_aligned.pdb | sed -e 's/HETATM/ATOM  /g' | grep "^ATOM "     > xtal-lig.pdb

#cat ${filedir}/prot.table.ambcrg.ambH > prot.table.ambcrg.ambH
#cat ${filedir}/amb.crg.oxt > amb.crg.oxt

#cat xtal-lig_ori.pdb | awk '{if ($1 == "ATOM" || $1 == "HETATM"){print $0}}' | sed -e "s/HETATM/ATOM  /g"  >  xtal-lig.pdb

rm -f  qsub.csh
# the following lines create a qsub script which submits blastermaster to the queue
cat <<EOF > qsub.csh
#!/bin/csh 
#SBATCH -t 4:00:00
#SBATCH --output=stderr

cd $workdir/
mkdir working
cp rec.crg.pdb working/rec.crg.pdb
# this is the modifed blastermaster script in which the user can spesify a manuly protonated file
# and it also can be used for tarting (making residues more polar).
#$DOCKBASE/proteins/blastermaster/blastermaster.py --addhOptions=" -HIS -FLIPs "  -v
#$DOCKBASE/proteins/blastermaster/blastermaster.py --addNOhydrogensflag --chargeFile=`pwd`/amb.crg.oxt --vdwprottable=`pwd`/prot.table.ambcrg.ambH -v
$DOCKBASE/proteins/blastermaster/blastermaster.py --addNOhydrogensflag -v
EOF

#qsub qsub.csh 
sbatch qsub.csh 

# this will produce two directories:
# 1) working - contains all input and output files that are generated; not needed afterwards but as a reference
# 2) dockfiles - contains everything that is needed to run dock (copied from working)
#    grids 
#    	trim.electrostatics.phi 
#    	vdw.vdw 
#    	vdw.bmp 
# 	ligand.desolv.heavy
# 	ligand.desolv.hydrogen
#    spheres
#    	matching_spheres.sph

end # system
