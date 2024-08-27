#!/bin/python3

import urllib.request


fh1 = open('./pdb_lig_map.txt','r')
fh2 = open('./pdb_covalent_bond_info.txt','w')

for line in fh1: 
    splitline = line.split()
    pdb = splitline[0]
    lig = splitline[1]
    print(pdb,lig)
    #with urllib.request.urlopen('https://files.rcsb.org/view/'+pdb+'.pdb') as response:
    #     html = response.read()
    #     print(html)
    r =  urllib.request.urlopen('https://files.rcsb.org/view/'+pdb+'.pdb')
    html = r.read().decode('UTF-8')
    #print(html)
    for line in html.split('\n'): 
        if "LINK" in line: 
            if lig in line : 
               #print (line)
               #LINK         SG  CYS E  12                 C19 QY5 E 202     1555   1555  1.81
               #LINK         SG  CYS A  12                 C38 H2T A1003     1555   1555  1.80  
               aname1 = line[13:16] 
               aname2 = line[43:46] 
               rname1 = line[17:20] 
               rname2 = line[47:50] 
               #rnum1 = line[23:26] 
               #rnum2 = line[53:56] 
               rnum1 = line[22:26] 
               rnum2 = line[52:56] 
               bondlength = line[73:79]
               print(line)
               #print(aname1+'--'+aname2)
               #print(rname1+'--'+rname2)
               #print(rnum1+'--'+rnum2)
               link_string = '(%s,%s,%s)--(%s,%s,%s)'%(aname1,rname1,rnum1,aname2,rname2,rnum2)
               print(pdb+" "+link_string)
               print('bondlength=%s'%bondlength)
               fh2.write('%s ; (%s,%s,%s)--(%s,%s,%s) ; %s\n'%(pdb,aname1,rname1,rnum1,aname2,rname2,rnum2,bondlength))

fh1.close()
fh2.close()

