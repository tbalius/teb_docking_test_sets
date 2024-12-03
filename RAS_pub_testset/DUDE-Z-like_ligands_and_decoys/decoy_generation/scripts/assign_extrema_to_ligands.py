import sys,os
#import subprocess
import rdkit
from rdkit import Chem

def read_filelines(ligfile,decfile):

  with open(ligfile,'r') as flig:
       ligfilelines = flig.readlines()
  with open(decfile,'r') as fdec:
       decfilelines = fdec.readlines()
  return ligfilelines,decfilelines


def get_matched_decoy_files(ligfilelines,fileprefix,path):

  #path = subprocess.check_output('pwd').decode().strip()
  filelist = os.listdir(path)
  #print(filelist)

  splitligfilelist = []
  for filename in filelist:
      if ('lig_a' in filename) and ('_dir' not in filename):
          splitligfilelist.append(path+'/'+filename)

  fmatched = {}
  for ligline in ligfilelines:
      for splitligfile in splitligfilelist:
          with open(splitligfile,'r') as filein:
               filelines = filein.readlines()
          for line in filelines:
               if ligline == line:
                  lignum  = str(ligfilelines.index(ligline))
                  dirpath = splitligfile+'_dir'
                  filenum = str(filelines.index(line))
                  fmatched[lignum] = dirpath+'/'+fileprefix+'_matched.'+filenum+'.smi'
                  print(lignum)
                  print(fmatched[lignum])
  return fmatched


def assign_decoys_to_ligands(decfilelines,N_lig,ligname,charge,fmatched,maxdecoys):

  ligdict = {'-1':[]}  # '-1' -> no ligand (unassigned)
  numdecoys = {'-1':0} # '-1' -> no ligand (unassigned)
  for i in range(N_lig):
      lignum = str(i)
      ligdict[lignum] = []
      numdecoys[lignum] = 0

  # assign decoys to matching ligand with least number of decoys assigned
  for decoyline in decfilelines:
      smi  = decoyline.split()[0]
      name = decoyline.split()[1]
      m2 = Chem.rdmolfiles.MolFromSmiles(smi)
      crg  = rdkit.Chem.rdmolops.GetFormalCharge(m2)
      if crg != charge:
         print('Decoy %s wrong charge'%(name))
         continue
      assigned_lignum = '-1' # assigned ligand number
      for i in range(N_lig):
          current_lignum = str(i) # current ligand number
          current_numdecoys  = numdecoys[current_lignum]
          if current_numdecoys < maxdecoys:
             splitligfile = fmatched[current_lignum]
             with open(splitligfile) as f:
                  filelines = f.readlines()
             listsmi = [line.split()[0] for line in filelines]
             if smi in listsmi:
                if assigned_lignum == '-1':
                   assigned_lignum = current_lignum
                else:
                   assigned_numdecoys = numdecoys[assigned_lignum]
                   if current_numdecoys < assigned_numdecoys:
                      assigned_lignum = current_lignum
      ligdict[assigned_lignum].append(smi+' '+name)
      numdecoys[assigned_lignum] += 1
      #print('Finished assigning decoy %s'%(name))
      if assigned_lignum == '-1':
         print('Did not assign decoy %s'%(name))
      else:
         ligname = lignames[assigned_lignum]
         print('Assigned decoy %s to ligand %s'%(name,ligname))
  return ligdict


def write_output(ligdict,N_lig,lignames,fileprefix):

  # write smiles files containing assigned decoys for each ligand
  alloutput = ''
  for i in range(N_lig):
      lignum = str(i)
      ligname = lignames[lignum]
      assigned_decoys = ligdict[lignum]
      #output = ligfilelines[i]
      output = ''
      for decoyline in assigned_decoys:
          output += decoyline+'\n'
      #output = output.strip('\n')
      fileout = fileprefix+'_'+ligname+'.'+lignum+'.smi'
      with open(fileout,'w') as fout:
           fout.write(output)
      alloutput += output
      print('Finished writing %s'%(fileout))

  # write smiles file containing all assigned decoys
  fileoutall = fileprefix+'.assigned.smi'
  with open(fileoutall,'w') as foutall:
       foutall.write(alloutput)
  print('Finished writing %s'%(fileoutall))

  # write smiles file containing unassigned decoys
  unassigned_decoys = ligdict['-1']
  output = ''
  for decoyline in unassigned_decoys:
      output += decoyline + '\n'
  #output = output.strip('\n')
  fileout = fileprefix+'.not_assigned.smi'
  with open(fileout,'w') as fout:
      fout.write(output)
  print('Finished writing %s'%(fileout))
  return


def main():

  ligsmifile = sys.argv[1]
  decsmifile = sys.argv[2]
  charge     = sys.argv[3]
  dirpath    = sys.argv[4]
  fileprefix = sys.argv[5]
  #maxdecoys = sys.argv[6]
  maxdecoys  = 50

  crgdict = {'minus2':-2,'minus1':-1,'neutral':0,'plus1':1,'plus2':2}

  ligfilelines,decfilelines = read_filelines(ligsmifile,decsmifile)

  N_lig = len(ligfilelines)

  lignames = {}
  for i in range(N_lig):
      lignum = str(i)
      lignames[lignum] = ligfilelines[int(lignum)].split()[1]

  fmatched = get_matched_decoy_files(ligfilelines,fileprefix,dirpath)
  ligdict = assign_decoys_to_ligands(decfilelines,N_lig,lignames,crgdict[charge],fmatched,maxdecoys)
  write_output(ligdict,N_lig,lignames,fileprefix)


main()

