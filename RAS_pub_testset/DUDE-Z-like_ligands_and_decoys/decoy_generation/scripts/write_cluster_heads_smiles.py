import sys

def get_cluster_heads(filein):
    with open(filein) as f:
         filelines = f.readlines()
    cluster_heads = []
    for line in filelines:
        #splitline = line.split(',')
        #name = splitline[2]
        cluster_heads.append(line.split(',')[2])
    return cluster_heads

def read_smiles_file(filein):
    with open(filein) as f:
         filelines = f.readlines()
    smiles_dict = {}
    for line in filelines:
        splitline = line.split()
        name = splitline[1]
        smiles_dict[name] = line
    return smiles_dict

def write_output(smiles_dict,cluster_heads):
    output = ''
    for name in cluster_heads:
        output += smiles_dict[name]
    return output

def main():

    clustheadfile = sys.argv[1]
    smifile = sys.argv[2]
    outfileprefix = sys.argv[3]

    clustheads = get_cluster_heads(clustheadfile)
    smidict = read_smiles_file(smifile)
    output = write_output(smidict,clustheads)
    with open(outfileprefix+'.self_dissim.all.smi','w') as f:
         f.write(output)

main()

