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


def zincinfo():

  #fhz = open('lookupforzinc.txt','r')
  with open('lookupforzinc.txt') as fhz:
       filelines = fhz.readlines()
  dic_mwt  = {}
  dic_logp = {}
  for line in filelines:
      sline = line.strip().split(',')
      if line[0] != 'l':
         letter = sline[0]
         mwt    = sline[1]
         logp   = sline[2]
         dic_mwt[mwt]   = letter
         dic_logp[logp] = letter
  return dic_mwt,dic_logp


def lookup_multi(val,delta,dic):

  start = lookup(val-delta,dic)
  stop  = lookup(val+delta,dic)
  print("%s-%s" %(start,stop))
  all_letters = []
  for key in dic.keys():
      letter = dic[key]
      all_letters.append(letter)
  all_letters.sort()
  letters = []
  for letter in all_letters:
      if letter <= stop and letter >= start:
         print(letter)
         letters.append(letter)
  return letters


def lookup(val,dic):

  key_list = []
  for key in dic.keys():
      key_list.append(key)
  #print(key_list)
  key_list.sort()
  #key_list = key_list.sort()
  #print(key_list)
  #exit()
  for key in key_list:
      #print('%s,%f'%(key,val))
      if '>' in key:
          if val > float(key.replace('>','')):
              letter = dic[key]
              break
      elif val <= float(key):
           letter = dic[key]
           #print(letter)
           break
  #print(letter)
  return letter


def get_N_from_zinc(N,mwt_lig,mwt_delta,logp_lig,logp_delta,rb_lig,rb_delta,hba_lig,hba_delta,hbd_lig,hbd_delta,zinc_slice,outputfile):

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

  #print('%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%s'%(N,mwtstart,mwtstop,logpstart,logpstop,rbstart,rbstop,hbastart,hbastop,hbdstart,hbdstop,zinc_slice))

  #path='/is2/projects/RAS-CompChem/static/work/zzz.databases/ZINC20_2D_smi/2D/'+zinc_slice+'/'
  path='/mnt/projects/RAS-CompChem/static/work/zzz.databases/ZINC20_2D_smi/2D/'+zinc_slice+'/'

  filelist = os.listdir(path)
  #fhi = os.popen('cat '+path+'*.smi')
  fho = open(outputfile,'a')
  count = 0
  scores = []
  listsmi = []
  for filename in filelist:
      fhi = open(path+filename)
      linecount = 0
      for line in fhi:
          if "smiles" in line:
              continue
          #print(line)
          splitline = line.split()
          smi  = splitline[0]
          name = splitline[1]
          m2   = Chem.rdmolfiles.MolFromSmiles(smi)
          if m2 is None:
             print("Issue with MolFromSmiles for smi = %s, name = %s"%(smi,name))
             continue
          mwt  = rdkit.Chem.Descriptors.ExactMolWt(m2)
          logp = rdkit.Chem.Descriptors.MolLogP(m2)
          rb   = rdkit.Chem.Descriptors.NumRotatableBonds(m2)
          hba  = rdkit.Chem.Descriptors.NumHAcceptors(m2)
          hbd  = rdkit.Chem.Descriptors.NumHDonors(m2)
          if (mwtstart  <= mwt  and mwt  <= mwtstop  and \
              logpstart <= logp and logp <= logpstop and \
              rbstart   <= rb   and rb   <= rbstop   and \
              hbastart  <= hba  and hba  <= hbastop  and \
              hbdstart  <= hbd  and hbd  <= hbdstop  ):
                count += 1
                #match_score = calc_match_score(mwt,mwt_lig,mwt_delta,logp,logp_lig,logp_delta,rb,rb_lig,rb_delta,hba,hba_lig,hba_delta,hbd,hbd_lig,hbd_delta)
                match_score = calc_match_score([mwt,logp,rb,hba,hbd],[mwt_lig,logp_lig,rb_lig,hba_lig,hbd_lig],[mwt_delta,logp_delta,rb_delta,hba_delta,hbd_delta])
                #match_score = calc_match_score([mwt,rb,hba,hbd],[mwt_lig,rb_lig,hba_lig,hbd_lig],[mwt_delta,rb_delta,hba_delta,hbd_delta]) # do not use logp in match score
                scores.append(match_score)
                listsmi.append(line)
                print('%d,%s,%s,%f,%f,%f,%f,%f,%f'%(count,smi,name,mwt,logp,rb,hba,hbd,match_score))
                fho.write('%s %s %f %f %f %f %f %f\n'%(smi,name,mwt,logp,rb,hba,hbd,match_score))
          else:
                linecount += 1
          if (linecount >= 1000000) or (count >= N):
              break
      fhi.close()
      if (count >= N):
          break
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
  if (len(sys.argv) != 3): # if wrong input
      print ("ERROR")
      print ("syntax: python mwt_logp_lookup_zinc_search_2d_sort.py ligand_smiles output_prefix")
      return

  pid = str(os.getpid()) # get the process identifier so that we do not write over the same file
  print(pid)

  ligsmilesfile = sys.argv[1]
  outfileprefix = sys.argv[2]

  fhi = open(ligsmilesfile,'r')
  outputallfile = outfileprefix +'.all.smi'
  fho = open(outputallfile,'w')

  flag_first = False

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
      print("Searching for decoys for ligand %s ..." %(name))

      m2 = Chem.rdmolfiles.MolFromSmiles(smi)
      if m2 is None:
         print("Issue with MolFromSmiles for smi = %s, name = %s"%(smi,name))
         continue
      crg  = rdkit.Chem.rdmolops.GetFormalCharge(m2)
      mwt  = rdkit.Chem.Descriptors.ExactMolWt(m2)
      logp = rdkit.Chem.Descriptors.MolLogP(m2)
      rb   = rdkit.Chem.Descriptors.NumRotatableBonds(m2)
      hba  = rdkit.Chem.Descriptors.NumHAcceptors(m2)
      hbd  = rdkit.Chem.Descriptors.NumHDonors(m2)
      #hac  = rdkit.Chem.Descriptors.HeavyAtomCount(m2)
      print('%s,%s,%f,%f,%f,%f,%f,%f'%(smi,name,crg,mwt,logp,rb,hba,hbd))
      print('%s %f %f'%(name,mwt,logp))
      dic_w,dic_l = zincinfo()
      print("mwt letters")
      lws = lookup_multi(mwt,25.0,dic_w) # molecular weight letters
      print("logp letters")
      lls = lookup_multi(logp,1.0,dic_l) # logp letters
      n_slices = len(lws)*len(lls)

      N = 100000 # get N decoys from each zinc slice

      tuplist = []
      for lw in lws:
        for ll in lls:
          zinc_slice = lw+ll
          print('Searching zinc slice %s ...'%(zinc_slice))
          tuplist += get_N_from_zinc(N,mwt,25.0,logp,1.0,rb,5,hba,4,hbd,3,zinc_slice,outputfile)
      tuplist.sort(key=itemgetter(0)) # sort decoys by match score
      print("Finished searching for decoys for ligand %s.\n"%(name))

      N_top = N # only keep N_top decoys for protonation
      if (abs(crg) >= 2):
          N_top *= n_slices # keep more decoys for high charge ligands
      tuplist_all += tuplist[:N_top]
      count += 1

  tuplist_all.sort(key=itemgetter(0))
  scores,listsmi = zip(*tuplist_all)
  for smiline in listsmi:
      fho.write(smiline)

  fhi.close()
  fho.close()


main()

