
# coding: utf-8

# In[1]:

import sys


# In[2]:

def fibR(n):
    assert(n>0)
    if n==1 or n==2:
        return 1
    return fibR(n-1)+fibR(n-2)

def param_p1p2p3(nb):
    m1 = nb-2
    m2 = 4*((nb-1)+(nb-2)*3)
    m3 = 4*(nb+(nb-2)*3)
    return m1, m2, m3


# ### Fibonacci
#     I_mem_L2Cache
#         number = len(fib_list)+1 (0)
#         transform
#         //addi $3 $0 14   / addi r3, r0, 0x000E, r3 = 16-2
#         //addi $7 $0 00E4 / addi r7, r0, 0x00E4, r7 = 4*[(number-1)+(number-2)*3]
#         //addi $7 $0 00E0 / addi r7, r0, 0x00E0, r7 = 4*[(number-2)+(number-2)*3]   
#         to
#         //addi $3 $0 m1   
#         //addi $7 $0 m2 
#         //addi $7 $0 m3 
#      TestBed_L2Cache
#         `define	CheckNum	6'd33       
#         
#             6'd0 :	answer = 32'd0;
#             6'd1 :	answer = 32'd1;
#             6'd2 :	answer = 32'd1;
#             6'd3 :	answer = 32'd2;
#             6'd4 :	answer = 32'd3;
#             6'd5 :	answer = 32'd5;
#             6'd6 :	answer = 32'd8;
#             6'd7 :	answer = 32'd13;
#             6'd8 :	answer = 32'd21;
#             6'd9 :	answer = 32'd34;
#             6'd10:	answer = 32'd55;
#             6'd11:	answer = 32'd89;
#             6'd12:	answer = 32'd144;
#             6'd13:	answer = 32'd233;
#             6'd14:	answer = 32'd377;
#             6'd15:	answer = 32'd610;
#             6'd16:	answer = 32'd610;
#             6'd17:	answer = 32'd377;
#             6'd18:	answer = 32'd233;
#             6'd19:	answer = 32'd144;
#             6'd20:	answer = 32'd89;
#             6'd21:	answer = 32'd55;
#             6'd22:	answer = 32'd34;
#             6'd23:	answer = 32'd21;
#             6'd24:	answer = 32'd13;
#             6'd25:	answer = 32'd8;
#             6'd26:	answer = 32'd5;
#             6'd27:	answer = 32'd3;
#             6'd28:	answer = 32'd2;
#             6'd29:	answer = 32'd1;
#             6'd30:	answer = 32'd1;
#             6'd31:	answer = 32'd0;
#             6'd32:	answer = `EndSymbol;          

# In[3]:

nb = int(sys.argv[1])

# nb = 20
# nb = 16
m1, m2,  m3 = param_p1p2p3(nb)

fib_list = [0]+[fibR(i) for i in range(1,nb)]
### for solving issue: sequence lenghth extension not enough 
gen_list_p1p2p3 = [0,1]
for v in fib_list[2:]:
    gen_list_p1p2p3 += [v, v+1, v+2, v+3]
    
seq_sort = sorted(gen_list_p1p2p3)
seq_sort = seq_sort.copy()
seq_sort.reverse()

write_list = gen_list_p1p2p3 + seq_sort 

CheckNum = len(write_list) + 1 #`EndSymbol


# In[4]:

TestBed_L2Cache_file = open('TestBed_L2Cache.v','w')


with open("TestBed_L2Cache_ref.v", "r") as f:
    for line in f:
        if 'modify' in line:
            line = line.replace("117", format(CheckNum, 'd'))
        
        if 'modify2' in line: 
            line = line.replace("xxx", format(fib_list[-1], 'd'))
            TestBed_L2Cache_file.write(line)
            break
        TestBed_L2Cache_file.write(line)

for i, ans in enumerate(write_list):
    TestBed_L2Cache_file.write("\t\t10'd%d :answer = 32'd%d;\n" %(i,ans))
    
TestBed_L2Cache_file.write("\t\t10'd%d :answer = `EndSymbol;\n\t\tendcase\n\tend\n\nendmodule" %(CheckNum-1))
TestBed_L2Cache_file.close()


# In[5]:

I_mem_L2Cache_file = open('I_mem_L2Cache','w')

with open("I_mem_L2Cache_ref", "r") as f:
    for line in f:
        if 'modify1' in line:
            # annotation
            line = line.replace("0x000e",             format(m1, 'x').zfill(4))  # I-type operand immediate 16 bit
            line = line.replace("610",                format(fib_list[-1], 'd'))
            line = line.replace("16",                 format(nb, 'd'))
            line = line.replace("14",                 format(m1, 'd')) 

            # instruction
            line = line.replace("00000_00000_001110", format(m1, 'b').zfill(16)) # I-type operand immediate 16 bit
        elif 'modify2' in line:
            # annotation
            line = line.replace("E4",              format(m2, 'x').zfill(4))  # I-type operand immediate 16 bit
            line = line.replace("228",                 format(m2, 'd')) 
            
            # instruction
            line = line.replace("00000_00011100100", format(m2, 'b').zfill(16)) # I-type operand immediate 16 bit
        elif 'modify3' in line:
            # annotation
            line = line.replace("E8",             format(m3, 'x').zfill(4))  # I-type operand immediate 16 bit
            line = line.replace("232",                 format(m3, 'd')) 
            
            # instruction
            line = line.replace("0000000011101000",   format(m3, 'b').zfill(16)) # I-type operand immediate 16 bit
        
        I_mem_L2Cache_file.write(line)
I_mem_L2Cache_file.close()

