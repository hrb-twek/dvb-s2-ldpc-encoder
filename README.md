Build Guide
==============

## 生成的工程xpr文件位于par/prj/top.xpr

### 目录结构
 * par
    * par/prj vivado工程目录，Git不追踪
    * par/Makefile  构建文件
 * src
    * src/ip      IP文件，只能使用XCI格式, IP的文件名与存放目录相同，Git不追踪 `*.xci`之外的派生文件
    * src/ip/coe  IP所使用的coe文件
    * src/rtl     Verilog, Verilog Header, VHDL 等源代码，在脚本创建工程时自动全部添加
    * src/logic_common 指向公共库源代码，按需在初始化脚本内手动指派位置
    * src/netlist EDF, DCP等网表，在脚本创建工程时自动全部添加
 * scripts      工程脚本目录，包括构建脚本，初始化脚本，约束文件等
    * scripts/sdc 约束目录，在脚本创建工程时自动全部添加，以_impl后缀的作为实现脚本添加，仅在实现阶段有效， 其余在所有阶段有效
    * scripts/setup.tcl 工程初始化脚本，需填写添加的文件列表
    * scripts/chip_part.tcl 初始化配置文件，配置器件型号用
    * scripts/synth.tcl 综合脚本，正常无需修改
    * scripts/impl.tcl 实现脚本，正常无需修改
    * scripts/*.bat 自动化构建脚本，正常无需修改，双击运行即可




### 注意事项 
 * 执行前首先确认已添加vivado安装目录到环境变量`VIVADO_2018_3_INS_DIR`, 例如:`VIVADO_2018_3_INS_DIR = D:\Xilinx\Vivado\2018.3` 

 * 工程所用FPGA型号在`scripts/chip_part.tcl`中配置 

### 构建方法

 * 双击运行scripts/open.bat 会调用env.bat初始化环境 并以scripts目录中的脚本建立工程, 最终打开工程 

 * 双击运行scripts/build.bat 会调用env.bat初始化环境 并完成工程的综合、实现、写bitstream过程 

 * 在shell中执行scripts/env.bat 后可使用透过命令行启动vivado, 在par目录下执行make all 即可自动建立工程及完成实现过程, 执行 
    * make clean 清理工程文件  
    * make setup 建立工程  
    * make synth 综合工程  
    * make impl  实现工程  

 
 
 
 
## verilog源文件格式示例
```verilog
// *******************************************************************
// Procject Name : 
// File Name     : xxx.v
// Model Name    :
// Called By     :
// Abstract      :
//
// Autor         : %USERNAME%
// E-mail        : 
//
// ******************************************************************* 
// Modification History:
// Date         By                 Version      Change Description
// -------------------------------------------------------------------
// %TIME%                          1.0            Initial
//
// *******************************************************************

`timescale 1ns/1ps

module xxxx #(
parameter    DATA_WIDTH = 12
) (
input                            rst,
input                            clk_sys,

input                            xxxxx
);

// ********************************************
// signal define
// ********************************************



// ********************************************
// main code
// ********************************************


endmodule
```
