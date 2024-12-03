import sys

def read_filein(filein):
    with open(filein) as f:
         filelines = f.readlines()
    names = []
    smiles = []
    for line in filelines:
        splitline = line.split()
        names.append(splitline[1])
        smiles.append(splitline[0])
    return names,smiles

def make_names_different(names):
    newnames = []
    for name in names:
        newname = name
        if newnames.count(name) > 0:
           count = sum(name+'_' in string for string in newnames)+1
           newname = name+'_'+str(count)
        newnames.append(newname)
    if len(newnames) != len(names):
       print('Error')
       sys.exit()
    return newnames

def write_fileout(names,smiles,fileout):
    output = ''
    if len(names) != len(smiles):
       print('Error')
       sys.exit()
    for i in range(len(smiles)):
        name = names[i]
        smi = smiles[i]
        output += smi+'\t'+name+'\n'
    with open(fileout,'w') as f:
         f.write(output)
    return


def main():

    fhi = sys.argv[1]
    fho = sys.argv[2]

    names,smiles = read_filein(fhi)
    newnames = make_names_different(names)
    write_fileout(newnames,smiles,fho)

main()

