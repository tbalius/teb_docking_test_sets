import sys
import rdkit
from rdkit import Chem
from rdkit.Chem import AllChem
from rdkit import DataStructs
from rdkit.Chem import Descriptors
import fp_rdkit_lib as rfpgen
import tanimoto_tversky_cal_axon_lib as tccalc

## Written by Trent Balius in the FNLCR, Dec 2022
## Modified by Stanley Tan in the FNLCR, Aug 2023


def chem_sim(smifile_lig,smifile_dec,outfileprefix):

  fpfilelig = 'ligands.fp'
  fpveclig  = rfpgen.get_fp(smifile_lig,fpfilelig)
  fpfiledec = outfileprefix +'.fp'
  fpvecdec  = rfpgen.get_fp(smifile_dec,fpfiledec)

  matfilename = outfileprefix +'.tanimoto.matrix'
  smifilename = outfileprefix +'.lig_dissim.smi'
  with open(smifile_dec,'r') as f:
       smilines = f.readlines()

  matfile = open(matfilename,'w')
  smifile = open(smifilename,'w')
  count = 0
  #smilist = []
  for fp2 in fpvecdec: # decoy
      maxTC = 0.0
      for fp1 in fpveclig: # ligand
          #print(fp1)
          #print(fp2)
          TC = tccalc.tanimoto(fp1,fp2)
          if maxTC < TC:
             maxTC = TC
          matfile.write('%f' % TC )
      if maxTC <= 0.35:
         #smilist.append(smiline[count])
         smifile.write(smilines[count])
      else:
         print("Discard decoy, too similar to a ligand (maxTC = %f)"%maxTC)
      #smifile.write('\n')
      count += 1
  matfile.close()
  smifile.close()
  return


def main():

  if (len(sys.argv) != 4): # if wrong input
     print ("ERROR")
     print ("syntax: python ligand_sim.py ligand_smiles decoy_smiles outfileprefix")
     sys.exit()

  ligsmilesfile = sys.argv[1]
  decsmilesfile = sys.argv[2]
  outfileprefix = sys.argv[3]

  chem_sim(ligsmilesfile,decsmilesfile,outfileprefix)


main()

