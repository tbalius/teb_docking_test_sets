import sys

def chem_sim(Max_Tc_col,decsmifile):

    with open(Max_Tc_col) as maxTcfile, open(decsmifile) as decoyfile:
         maxTclines = maxTcfile.readlines()
         decoylines = decoyfile.readlines()

    if len(maxTclines) != len(decoylines):
       print("Error")
       print("Number of Tc values does not match number of decoys")
       sys.exit()

    output = ''
    for i,line in enumerate(maxTclines):
        maxTc = float(line.strip())
        if maxTc <= 0.35:
           decoyline = decoylines[i]
           output += decoyline
        else:
           print("Discard decoy, too similar to a ligand (maxTc = %f)"%maxTc)
    return output


def main():

    Max_Tc_col = sys.argv[1]
    decsmifile = sys.argv[2]
    outprefix  = sys.argv[3]

    output = chem_sim(Max_Tc_col,decsmifile)
    with open(outprefix+'.lig_dissim.smi','w') as outfile:
         outfile.write(output)


main()

