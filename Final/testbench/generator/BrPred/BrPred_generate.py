
# coding: utf-8

# In[38]:

import sys

nb_notBEQ   = int(sys.argv[1])
nb_interBEQ = int(sys.argv[2])
nb_BEQ      = int(sys.argv[3])
# nb_notBEQ   = 1
# nb_interBEQ = 2
# nb_BEQ      = 3


# In[55]:

I_mem_BrPred_file = open('I_mem_BrPred','w')

with open("I_mem_BrPredref", "r") as f:
    for line in f:
        if 'modify1' in line:
            # annotation
            line = line.replace(" 10 ",               '{:^5}'.format(nb_notBEQ, 'd')) 
            # instruction
            line = line.replace("0000000000001010",   format(nb_notBEQ, 'b').zfill(16)) # I-type operand immediate 16 bit
        elif 'modify2' in line:
            # annotation
            line = line.replace(" 20 ",               '{:^5}'.format(nb_interBEQ, 'd')) 
            # instruction
            line = line.replace("0000000000010100",   format(nb_interBEQ, 'b').zfill(16)) # I-type operand immediate 16 bit
        elif 'modify3' in line:
            # annotation
            line = line.replace(" 30 ",               '{:^5}'.format(nb_BEQ, 'd')) 
            I_mem_BrPred_file.write(line)
            break
            
        I_mem_BrPred_file.write(line)
        
for i in range(nb_BEQ):
    I_mem_BrPred_file.write("000000_00111_00011_00111_00000_100000      //add  r7,r7,r3\n000100_00001_00010_0000000000000001        //beq  r1,r2, 0x0001\n000010_00000000000000000000001110          //j    14\n")

I_mem_BrPred_file.write("000000_00100_00010_00110_00000_100000      //add  r6,r2, r4\n000000_00111_00110_00110_00000_100000      //add  r6,r6, r7\n101011_00000_00110_0000000000000000        //sw   r6,r0, 0x0000 ; a+b+c = %d\n" %(nb_notBEQ+nb_interBEQ+nb_BEQ))
I_mem_BrPred_file.close()


# In[37]:

TestBed_BrPred_file = open('TestBed_BrPred.v','w')

with open("TestBed_BrPredref.v", "r") as f:
    for line in f:
        if '`define	answer' in line:
            line = line.replace("60",format(nb_notBEQ+nb_interBEQ+nb_BEQ, 'd')) 
        TestBed_BrPred_file.write(line)
TestBed_BrPred_file.close()


# In[ ]:



