# %%
#1.load all sheet of a excel
import pandas as pd
file_path = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_1/LISHEN_LFP_1.0C-2.0D_T25_1.xlsx"
xls = pd.ExcelFile(file_path)
print("Sheet 名称如下：")
print(xls.sheet_names)


# %%
# 2.load all data of the sheets
import pandas as pd
file_path = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_1/LISHEN_LFP_1.0C-2.0D_T25_1.xlsx"
cycle = pd.read_excel(file_path, sheet_name='Cycle_66_4_8')
statis = pd.read_excel(file_path, sheet_name='Statis_66_4_8')
detail = pd.read_excel(file_path, sheet_name='Detail_66_4_8')
print(cycle.head())
print(statis.head())
print(detail.head())

# %%
# Statistic the number of cycle
import pandas as pd
file_path = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_1/LISHEN_LFP_1.0C-2.0D_T25_1.xlsx"
detail = pd.read_excel(file_path, sheet_name=2)
unique_cycles = detail['Cycle'].unique()
print(f"共发现 {len(unique_cycles)} 个循环(Cycle):")
print(unique_cycles)

# %%
#  IC Curve from sheet3
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
file_path = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_1/LISHEN_LFP_1.0C-2.0D_T25_1.xlsx"
detail = pd.read_excel(file_path, sheet_name='Detail_66_4_8') 
# 过滤出 cycle 1 且状态为 'Charge' 的数据
detail_1 = detail[(detail['Cycle'] == 1) & (detail['State'].str.contains('Charge', case=False))]

# 获取电压和容量
voltage = detail['Voltage(V)'].values
capacity = detail['Capacity(mAh)'].values

# 计算 dQ/dV
dV = np.diff(voltage)
dQ = np.diff(capacity)
epsilon = 1e-8
dQ_dV = dQ / (dV + epsilon)
voltage_mid = (voltage[:-1] + voltage[1:]) / 2  # 中间点画图更平滑

# 绘图
plt.figure(figsize=(10, 6))
plt.plot(voltage_mid, dQ_dV, label='Cycle 1 Charge')
plt.xlabel('Voltage (V)')
plt.ylabel('dQ/dV (mAh/V)')
plt.title('Incremental Capacity Curve (Cycle 1 - Charge)')
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.show()
plt.savefig("dq_dv_cycle1.png")