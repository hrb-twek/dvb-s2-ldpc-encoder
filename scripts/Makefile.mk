# 配置缺省值
ROOTDIR ?= .
CHIP_PART ?= xc7vx690tffg1761-2

SETUP_TCL = $(ROOTDIR)/scripts/setup.tcl
SYNTH_TCL = $(ROOTDIR)/scripts/synth.tcl
IMPL_TCL  = $(ROOTDIR)/scripts/impl.tcl

TCL = $(SETUP_TCL) $(SYNTH_TCL) $(IMPL_TCL)

# Common Vivado options
VIVADOCOMOPS = -mode batch -nolog -nojournal

# determine the OS shell - this make file should work on both linux and windows
UNAME := $(shell uname)

# on windows you have to prefix vivado call with a cmd shell with /c
ifeq ($(UNAME), Linux)
	PREFIX = ""
	POSTFIX = ""
else
	PREFIX = cmd /c "
	POSTFIX = "
endif

build: all

rebuild: clean build 

all: setup synth impl 

tcl_list: 
	@echo $(TCL)


# 建立工程xpr
setup: .setup.done 
.setup.done: $(SETUP_TCL)
	@echo ----------------- Create Project -------------------------
	@-rm -f $@
	$(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/setup.tcl $(POSTFIX)
	touch $@

# 综合
synth: .synth.done
.synth.done: .setup.done $(SYNTH_TCL)
	@echo ----------------- Synthessis -----------------------------
	@-rm -f $@
	$(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/synth.tcl $(POSTFIX)
	touch $@

# 实现
impl: .impl.done
.impl.done: synth $(IMPL_TCL)
	@echo ----------------- Implementation -------------------------
	@rm -f $@
	$(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/impl.tcl $(POSTFIX)
	touch $@

clean: clean_build
	@echo ----------------- Clean All ---------------------------------

# 清理工程目录
clean_build:
	@echo ----------------- Clean Build ---------------------------------
	@-rm -rf $(ROOTDIR)/par/prj/
	@-rm -rf $(ROOTDIR)/par/.Xil/
	@-rm -rf $(ROOTDIR)/par/*.done


.PHONY: clean clean_build impl synth setup build rebuild all
