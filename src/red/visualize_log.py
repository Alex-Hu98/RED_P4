import re
import matplotlib.pyplot as plt

lines = []
enq_len_data = []
if_dropped = []
Qavg = []
this_drop_prob = []

with open("logs/s1.log", mode="r") as log_file:
    lines = log_file.readlines()

for line in lines:
    target_str = "Wrote register 'this_enq_qdepth' at index 0 with value"
    if target_str in line:
        number_list = []
        number_list = re.findall(r'\d+', line)
        temp = number_list[len(number_list)-1]
        result = float(temp)
        enq_len_data.append(result)
    
    target_str = "Wrote register 'if_dropped' at index 0 with value"
    if target_str in line:
        number_list = []
        number_list = re.findall(r'\d+', line)
        temp = number_list[len(number_list)-1]
        result = float(temp)
        if_dropped.append(result)

    target_str = "Wrote register 'Qavg' at index 0 with value"
    if target_str in line:
        number_list = []
        number_list = re.findall(r'\d+', line)
        temp = number_list[len(number_list)-1]
        result = float(temp)
        Qavg.append(result)

    target_str = "Wrote register 'this_drop_prob' at index 0 with value"
    if target_str in line:
        number_list = []
        number_list = re.findall(r'\d+', line)
        temp = number_list[len(number_list)-1]
        result = float(temp)
        this_drop_prob.append(result)


for i in range(len(this_drop_prob)):
    temp = this_drop_prob[i]
    this_drop_prob[i] = temp/256

x_axis = []
for i in range(len(enq_len_data)):
    x_axis.append(i+1)

fig1 = plt.figure(1)
plt.plot(x_axis, enq_len_data, color='r', label="current queue length", linewidth = 0.8, alpha = 0.7)
plt.plot(x_axis, Qavg, color='g', label='calcuated queue avg length', linewidth = 0.8, alpha = 0.7)
plt.xlabel("ingress packet index")
plt.ylabel("queue length")
plt.legend()
plt.savefig('queue length.png', dpi=300)


fig2 = plt.figure(2)
plt.plot(x_axis, this_drop_prob, color='r', label="drop_prob", linewidth = 0.8, alpha = 0.7)
plt.ylabel("drop_prob")
plt.xlabel("ingress packet index")
plt.legend()
plt.savefig('drop_prob.png', dpi=300)

fig3 = plt.figure(3)
plt.plot(x_axis, if_dropped, color='g', label="if_dropped", linewidth = 0.8, alpha = 0.7)
plt.ylabel("if_dropped")
plt.xlabel("ingress packet index")
plt.legend()
plt.savefig('if_dropped.png', dpi=300)

plt.show()
