# Makefile 'wrapper' for the OpenFPGA Aurora2 Wrapper

# usage hints:
# make and show onscreen and log everything to build_DATE_TIME.log:
#     make install -j$(nproc) 2>&1 | tee build_$(date "+%d_%B_%Y")_$(date +"%H_%M_%S").log

# https://stackoverflow.com/questions/18136918/how-to-get-current-relative-directory-of-your-makefile
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR_PATH := $(patsubst %/,%,$(dir $(MAKEFILE_PATH)))
MAKEFILE_DIR_NAME := $(notdir $(MAKEFILE_DIR_PATH))
# $(info )
# $(info MAKEFILE_LIST=$(MAKEFILE_LIST))
# $(info MAKEFILE_PATH=$(MAKEFILE_PATH))
# $(info MAKEFILE_DIR_PATH=$(MAKEFILE_DIR_PATH))
# $(info MAKEFILE_DIR_NAME=$(MAKEFILE_DIR_NAME))
# $(info )
# https://stackoverflow.com/a/33616144 : get the jobs passed in to make...
MAKE_PID := $(shell echo $$PPID)
JOB_FLAG := $(filter -j%, $(subst -j ,-j,$(shell ps T | grep "^\s*$(MAKE_PID).*$(MAKE)")))
JOBS     := $(subst -j,,$(JOB_FLAG))
# $(info )
# $(info MAKE_PID=$(MAKE_PID))
# $(info JOB_FLAG=$(JOB_FLAG))
# $(info JOBS=$(JOBS))
# $(info )
$(info using parallel jobs: $(JOBS))

# underscores are better for using in filename/dirname
# DATE example: 01_JUL_2024
# TIME example: 21_36_45
# TZ example: +05:30 IST
export DATE_FORMAT := "%d_%^b_%Y"
export TIME_FORMAT := "%H_%M_%S"
export TZ_FORMAT := "%:z %Z"
CURRENT_DATE := $(shell date +$(DATE_FORMAT))
CURRENT_TIME := $(shell date +$(TIME_FORMAT))
CURRENT_TZ := $(shell date +$(TZ_FORMAT))
$(info time: $(CURRENT_DATE) $(CURRENT_TIME) $(CURRENT_TZ))

# Use bash as the default shell
SHELL := /bin/bash

# PREFIX for 'install' path
PREFIX ?= $(MAKEFILE_DIR_PATH)/install

# CMake
BUILD_DIR := $(MAKEFILE_DIR_PATH)/openfpga/build
SOURCE_DIR := $(MAKEFILE_DIR_PATH)/openfpga

# Options
OPENFPGA_WITH_VERSION ?= OFF

# https://askubuntu.com/questions/279168/detect-if-its-ubuntu-linux-os-in-makefile
# http://linuxmafia.com/faq/Admin/release-files.html
BUILD_PLATFORM ?=
SUPPORTED_BUILD_PLATFORMS :=
SUPPORTED_BUILD_PLATFORMS += WIN32_MSYS2_MINGW64
SUPPORTED_BUILD_PLATFORMS += WIN32_MSYS2_UCRT64
# SUPPORTED_BUILD_PLATFORMS += WIN32_MSVC
SUPPORTED_BUILD_PLATFORMS += UBUNTU_2004
# SUPPORTED_BUILD_PLATFORMS += UBUNTU_2204

ifeq ($(OS),Windows_NT)
ifneq ($(filter $(MSYSTEM),MINGW64),)
	BUILD_PLATFORM := WIN32_MSYS2_MINGW64
else ifneq ($(filter $(MSYSTEM),UCRT64),)
	BUILD_PLATFORM := WIN32_MSYS2_UCRT64
else
	BUILD_PLATFORM := WIN32_MSVC
endif
else ifeq ($(OS),)
	OS=$(shell uname -s)
ifeq ($(OS),Linux)
ifneq ("$(wildcard /etc/lsb-release)","")
	DISTRO := $(shell lsb_release -si | tr '[:lower:]' '[:upper:]')
	VERSION := $(subst .,,$(shell lsb_release -sr))
	BUILD_PLATFORM := $(DISTRO)_$(VERSION)
endif
endif
endif # ifeq ($(OS),Windows_NT)

ifneq ($(filter $(BUILD_PLATFORM),$(SUPPORTED_BUILD_PLATFORMS)),)
$(info using build platform: $(BUILD_PLATFORM))
else
$(error unsupported build platform: $(BUILD_PLATFORM))
endif


ifeq ($(BUILD_PLATFORM),$(filter $(BUILD_PLATFORM),WIN32_MSYS2_MINGW64 WIN32_MSYS2_UCRT64))
export SOURCE_DIR_W := $(shell cygpath -w "$(SOURCE_DIR)" | sed 's;\\;/;g')
export MSYS2_ARG_CONV_EXCL := "../EXTERNAL/capnproto/c++/src/capnp/capnp.exe;$(SOURCE_DIR_W)/build/openfpga/vtr-verilog-to-routing/libs/EXTERNAL/capnproto/c++/src/capnp/capnpc-c++.exe:."
endif


.DEFAULT_GOAL := install


.PHONY: prepare
prepare:
ifeq ($(BUILD_PLATFORM),$(filter $(BUILD_PLATFORM),WIN32_MSYS2_MINGW64 WIN32_MSYS2_UCRT64))
	find $(SOURCE_DIR)/vtr-verilog-to-routing/libs/libvtrutil/src/vtr_util.cpp -type f -exec sed -i 's-getdelim(-0;//-g' {} \;
	find $(SOURCE_DIR)/vtr-verilog-to-routing/libs/EXTERNAL/capnproto/c++/src/kj/test-helpers.c++ -type f -exec sed -i 's-needle.size()};-needle.end()};-g' {} \;
	find $(SOURCE_DIR)/vtr-verilog-to-routing/libs/EXTERNAL/capnproto/c++/ekam-provider/canonical/kj/test-helpers.c++ -type f -exec sed -i 's-needle.size()};-needle.end()};-g' {} \;
	find $(SOURCE_DIR)/vtr-verilog-to-routing/libs/EXTERNAL/capnproto/c++/ekam-provider/c++header/kj/test-helpers.c++ -type f -exec sed -i 's-needle.size()};-needle.end()};-g' {} \;
	find $(SOURCE_DIR)/libs/libnamemanager/src/base/io_name_map.h -type f -exec sed -i '7 i #include <array>' {} \;
	find $(SOURCE_DIR)/openfpga/src/fpga_bitstream/fabric_bitstream.h -type f -exec sed -i '33 i #include <cstdint>' {} \;
else ifeq ($(BUILD_PLATFORM),UBUNTU_2004)
endif


.PHONY: run-cmake
run-cmake: prepare
ifeq ($(BUILD_PLATFORM),$(filter $(BUILD_PLATFORM),WIN32_MSYS2_MINGW64 WIN32_MSYS2_UCRT64))
	@cmake -G "MSYS Makefiles" \
	-DCMAKE_INSTALL_PREFIX=$(PREFIX) \
	-DOPENFPGA_IPO_BUILD=off \
	-DOPENFPGA_WITH_YOSYS=OFF \
	-DOPENFPGA_WITH_YOSYS_PLUGIN=OFF \
	-DOPENFPGA_WITH_TEST=OFF \
	-DOPENFPGA_WITH_VERSION=$(OPENFPGA_WITH_VERSION) \
	-DOPENFPGA_WITH_SWIG=OFF \
	-DWITH_ABC=OFF \
	-DVTR_IPO_BUILD=off \
	-DHAVE_STRUCT_TIMESPEC=1 \
	-DABC_USE_STDINT_H=1 \
	-S $(SOURCE_DIR) -B $(BUILD_DIR)
else ifeq ($(BUILD_PLATFORM),UBUNTU_2004)
	@cmake \
	-DCMAKE_INSTALL_PREFIX=$(PREFIX) \
	-DOPENFPGA_WITH_YOSYS=OFF \
	-DOPENFPGA_WITH_YOSYS_PLUGIN=OFF \
	-DOPENFPGA_WITH_TEST=OFF \
	-DOPENFPGA_WITH_VERSION=$(OPENFPGA_WITH_VERSION) \
	-DOPENFPGA_WITH_SWIG=OFF \
	-DWITH_ABC=OFF \
	-S $(SOURCE_DIR) -B $(BUILD_DIR)
endif


.PHONY: install
install: run-cmake
#cmake --install ${BUILD_DIR} -j$(JOBS)
	@START_DATE=$$(date +$(DATE_FORMAT)) && echo "START_DATE=$${START_DATE}"; \
	START_TIME=$$(date +$(TIME_FORMAT)) && echo "START_TIME=$${START_TIME}"

# ifeq ($(BUILD_PLATFORM),$(filter $(BUILD_PLATFORM),WIN32_MSYS2_MINGW64 WIN32_MSYS2_UCRT64))
# 	@export SOURCE_DIR_W=$(shell cygpath -w "$(SOURCE_DIR)" | sed 's;\\;/;g') && \
# 	export MSYS2_ARG_CONV_EXCL="../EXTERNAL/capnproto/c++/src/capnp/capnp.exe;$${SOURCE_DIR_W}/build/openfpga/vtr-verilog-to-routing/libs/EXTERNAL/capnproto/c++/src/capnp/capnpc-c++.exe:." && \
# 	$(MAKE) -C $(BUILD_DIR) install
# else ifeq ($(BUILD_PLATFORM),UBUNTU_2004)
# 	@$(MAKE) -C $(BUILD_DIR) install
# endif
	$(MAKE) -C $(BUILD_DIR) install
	
	@END_DATE=$$(date +$(DATE_FORMAT)) && echo "END_DATE=$${END_DATE}"; \
	END_TIME=$$(date +$(TIME_FORMAT)) && echo "END_TIME=$${END_TIME}"


.PHONY: package
package:


.PHONY: clean
clean:
ifneq ("$(wildcard $(PREFIX))","")
	@rm -rf $(PREFIX)
endif
ifneq ("$(wildcard $(BUILD_DIR))","")
	@$(MAKE) -C ${BUILD_DIR} clean
	@rm -rf $(BUILD_DIR)
endif


.PHONY: _testing
_testing:
	$(info )
	$(info _testing)
	$(info OS: $(OS))
	$(info BUILD_PLATFORM: $(BUILD_PLATFORM))
