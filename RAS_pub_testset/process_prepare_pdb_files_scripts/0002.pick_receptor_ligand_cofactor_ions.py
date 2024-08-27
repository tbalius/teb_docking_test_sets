#!/bin/python3

#import urllib.request
import sys,os,shutil

workdir = '002_pick_receptor_ligand_cofactor_ions/'

os.mkdir(workdir)
os.chdir(workdir)

#fh = open('./pdb_lig_map.txt','r')
fh = open('../pdb_lig_map.txt','r')

for line in fh: 
    splitline = line.split()
    pdb = splitline[0]
    lig = splitline[1]
    #print(pdb,lig)

    filedir = '../001_pdb_breaker/'+pdb+'_'+lig

    if os.path.isdir(pdb+'_sel_cof_ions'):
        print(pdb+'_sel_cof_ions/ exists')
        continue

    #oh = os.popen('grep "^ATOM  " '+pdb+'/rec.pdb | cut -c 21-23 | sort -u')
    #oh = os.popen('grep "^ATOM  " '+pdb+'/rec.pdb | cut -c 21-22 | sort -u')
    oh = os.popen('grep "^ATOM  " '+filedir+'/rec.pdb | cut -c 21-22 | sort -u')
    chains = oh.readlines()
    oh.close()
    #oh = os.popen('ls '+pdb+'/lig.*.pdb')
    oh = os.popen('ls '+filedir+'/lig.*.pdb')
    lig_files = oh.readlines()
    oh.close()

    os.mkdir(pdb+'_'+lig+'_sel_cof_ions')
    os.chdir(pdb+'_'+lig+'_sel_cof_ions')
    #shutil.copyfile(src_file, dest_file, *, follow_symlinks=True)
    #shutil.copy('../'+pdb+'/rec.pdb','./')
    #shutil.copy('../'+pdb+'/xtal-lig.pdb','./')
    shutil.copy('../'+filedir+'/rec.pdb','./')
    shutil.copy('../'+filedir+'/xtal-lig.pdb','./')
    #print (chains)
    for line in chains:
        chain = line.strip()
        #print (chain)
        os.popen("cat ./rec.pdb | awk '$5 ~ /"+chain+"/' > rec_"+chain+".pdb")
        for line2 in lig_files:
            lig_file = line2.strip()
            fh = open('../'+lig_file)
            line3 = fh.readline()
            fh.close()
            #chainid = line3[21:23]
            chainid = line3[21:22]
            liganame = line3[17:20]
            print (chainid.strip(), chain.strip())
            #print("**%s** == **%s**"%(chainid,chain))
            if (chainid.strip() == chain.strip()):
                #print("*%s* == *%s*"%(chainid,chain))
                if (liganame == 'GDP' \
                 or liganame == 'GTP' \
                 or liganame == 'GNP' \
                 or liganame == 'GCP' \
                 or liganame == 'GSP' ):
                    #print(lig_file)
                    print("found cofactor: %s %s %s"%(lig_file, liganame, chainid))
                    shutil.copy('../'+lig_file,'./')
                    #shutil.copy('../'+lig_file,'./cof_'+chain+'.pdb')
                if(liganame == ' MG' or liganame == ' CA' ):
                    #print(lig_file)
                    print("found ion: %s %s %s"%(lig_file, liganame, chainid))
                    shutil.copy('../'+lig_file,'./')
                    #shutil.copy('../'+lig_file,'./ion_'+chain+'.pdb')
    os.chdir('../')
        
fh.close()
