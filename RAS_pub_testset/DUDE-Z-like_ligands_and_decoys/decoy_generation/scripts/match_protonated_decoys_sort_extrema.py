import sys,os
import rdkit
from rdkit import Chem
from rdkit.Chem import Descriptors
from rdkit.Chem import AllChem
from rdkit import DataStructs
from operator import itemgetter
import numpy as np

## Written by Trent Balius in the FNLCR, Dec 2022
## Modified by Stanley Tan in the FNLCR, Aug 2023


def filter_decoys_by_charge(inputfile,charge):

  fhi = open(inputfile,'r')
  decoy_dict = {}
  for line in fhi:
      splitline = line.split()
      if not splitline: # empty
         continue
      smi  = splitline[0]
      name = splitline[1]
      m2   = Chem.rdmolfiles.MolFromSmiles(smi)
      if m2 is None:
         print("Issue with MolFromSmiles for smi = %s, name = %s"%(smi,name))
         continue
      crg  = rdkit.Chem.rdmolops.GetFormalCharge(m2)
      if (crg != charge):
          continue
      decoy_dict[name] = line
  fhi.close()
  return decoy_dict


#def match_decoys(N,crg_ext,crg_delta,mwt_lig,mwt_delta,logp_lig,logp_delta,rb_lig,rb_delta,hba_lig,hba_delta,hbd_lig,hbd_delta,inputfile,outputfile):
def match_decoys(N,mwt_lig,mwt_delta,logp_lig,logp_delta,rb_lig,rb_delta,hba_lig,hba_delta,hbd_lig,hbd_delta,decoy_dict,outputfile):

  #crgstart  = crg_ext  - crg_delta
  #crgstop   = crg_ext  + crg_delta
  mwtstart  = mwt_lig  - mwt_delta
  mwtstop   = mwt_lig  + mwt_delta
  logpstart = logp_lig - logp_delta
  logpstop  = logp_lig + logp_delta
  rbstart   = rb_lig   - rb_delta
  rbstop    = rb_lig   + rb_delta
  hbastart  = hba_lig  - hba_delta
  hbastop   = hba_lig  + hba_delta
  hbdstart  = hbd_lig  - hbd_delta
  hbdstop   = hbd_lig  + hbd_delta

  #print('%i,%i,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f'%(crgstart,crgstop,mwtstart,mwtstop,logpstart,logpstop,rbstart,rbstop,hbastart,hbastop,hbdstart,hbdstop))

  #fhi = open(inputfile,'r')
  fho = open(outputfile,'w')
  count = 0
  scores = []
  listsmi = []
  #for line in fhi:
  #    #print(line)
  #    splitline = line.split()
  #    if not splitline: # empty
  #       continue
  #    smi  = splitline[0]
  #    name = splitline[1]
  #    m2   = Chem.rdmolfiles.MolFromSmiles(smi)
  #    if m2 is None:
  #       print("Issue with MolFromSmiles for smi = %s, name = %s"%(smi,name))
  #       continue
  for name in decoy_dict:
      line = decoy_dict[name]
      smi = line.split()[0]
      m2 = Chem.rdmolfiles.MolFromSmiles(smi)
      #crg  = rdkit.Chem.rdmolops.GetFormalCharge(m2)
      mwt  = rdkit.Chem.Descriptors.ExactMolWt(m2)
      logp = rdkit.Chem.Descriptors.MolLogP(m2)
      rb   = rdkit.Chem.Descriptors.NumRotatableBonds(m2)
      hba  = rdkit.Chem.Descriptors.NumHAcceptors(m2)
      hbd  = rdkit.Chem.Descriptors.NumHDonors(m2)
      #if (crgstart  <= crg  and crg  <= crgstop  and \
      if (mwtstart  <= mwt  and mwt  <= mwtstop  and \
          logpstart <= logp and logp <= logpstop and \
          rbstart   <= rb   and rb   <= rbstop   and \
          hbastart  <= hba  and hba  <= hbastop  and \
          hbdstart  <= hbd  and hbd  <= hbdstop  ): 
            count += 1
            #match_score = calc_match_score(mwt,mwt_lig,mwt_delta,logp,logp_lig,logp_delta,rb,rb_lig,rb_delta,hba,hba_lig,hba_delta,hbd,hbd_lig,hbd_delta)
            match_score = calc_match_score([mwt,logp,rb,hba,hbd],[mwt_lig,logp_lig,rb_lig,hba_lig,hbd_lig],[mwt_delta,logp_delta,rb_delta,hba_delta,hbd_delta])
            scores.append(match_score)
            listsmi.append(line)
            print('%d,%s,%s,%f,%f,%f,%f,%f,%f'%(count,smi,name,mwt,logp,rb,hba,hbd,match_score))
            fho.write('%s %s %f %f %f %f %f %f\n'%(smi,name,mwt,logp,rb,hba,hbd,match_score))
      if count >= N:
         break
  #fhi.close()
  fho.close()

  tuplist = list(zip(scores,listsmi))
  return tuplist


#def calc_match_score(mwt,mwt_lig,mwt_delta,logp,logp_lig,logp_delta,rb,rb_lig,rb_delta,hba,hba_lig,hba_delta,hbd,hbd_lig,hbd_delta):
  #mwt_match  = calc_dist_over_delta(mwt,mwt_lig,mwt_delta)
  #logp_match = calc_dist_over_delta(logp,logp_lig,logp_delta)
  #rb_match   = calc_dist_over_delta(rb,rb_lig,rb_delta)
  #hba_match  = calc_dist_over_delta(hba,hba_lig,hba_delta)
  #hbd_match  = calc_dist_over_delta(hbd,hbd_lig,hbd_delta)
  #return (mwt_match+logp_match+rb_match+hba_match+hbd_match)/5


def calc_match_score(decoy_properties,ligand_properties,deltas):
  match_vals = []
  for val in map(calc_dist_over_delta,decoy_properties,ligand_properties,deltas):
      match_vals.append(val)
  return np.average(match_vals)


def calc_dist_over_delta(x,x_0,delta):
  return abs(x-x_0)/delta


def main():
  if (len(sys.argv) != 5): # if wrong input
      print ("ERROR")
      print ("syntax: python match_protonated_decoys_sort.py charge ligand_smiles decoy_smiles output_prefix")
      return

  pid = str(os.getpid()) # get the process identifier so that we do not write over the same file
  print(pid)

  charge = sys.argv[1]
  crgdict = {'minus2':-2,'minus1':-1,'neutral':0,'plus1':1,'plus2':2}

  ligsmilesfile = sys.argv[2]
  decsmilesfile = sys.argv[3]
  outfileprefix = sys.argv[4]

  fhi = open(ligsmilesfile,'r')
  outputallfile = outfileprefix +'.all.smi'
  fho = open(outputallfile,'w')

  flag_first = False

  decoys = filter_decoys_by_charge(decsmilesfile,crgdict[charge])

  count = 0
  tuplist_all = []
  for line in fhi:
      if (flag_first):
          flag_first = True
          continue

      outputfile = outfileprefix+'.'+str(count)+'.smi'

      splitline = line.split()
      smi  = splitline[0]
      name = splitline[1]

      m2 = Chem.rdmolfiles.MolFromSmiles(smi)
      if m2 is None:
         print("Issue with MolFromSmiles for smi = %s, name = %s"%(smi,name))
         continue
      #crg  = rdkit.Chem.rdmolops.GetFormalCharge(m2)
      #crg  = crgdict[charge]
      mwt  = rdkit.Chem.Descriptors.ExactMolWt(m2)
      logp = rdkit.Chem.Descriptors.MolLogP(m2)
      rb   = rdkit.Chem.Descriptors.NumRotatableBonds(m2)
      hba  = rdkit.Chem.Descriptors.NumHAcceptors(m2)
      hbd  = rdkit.Chem.Descriptors.NumHDonors(m2)
      #hac  = rdkit.Chem.Descriptors.HeavyAtomCount(m2)
      #print('%s,%s,%f,%f,%f,%f,%f,%f'%(smi,name,crg,mwt,logp,rb,hba,hbd))
      print('%s,%s,%f,%f,%f,%f,%f'%(smi,name,mwt,logp,rb,hba,hbd))

      N = 10000
      #tuplist = match_decoys(N,crg,0,mwt,25.0,logp,0.5,rb,5,hba,4,hbd,3,decsmilesfile,outputfile)
      tuplist = match_decoys(N,mwt,25.0,logp,0.5,rb,5,hba,4,hbd,3,decoys,outputfile)
      tuplist.sort(key=itemgetter(0))
      print("Finished searching for decoys for ligand %s.\n"%(name))

      N_top = 1000
      tuplist_all += tuplist[:N_top]
      count += 1

  tuplist_all.sort(key=itemgetter(0))
  scores,listsmi = zip(*tuplist_all)
  for smiline in listsmi:
      fho.write(smiline)

  fhi.close()
  fho.close()


main()

