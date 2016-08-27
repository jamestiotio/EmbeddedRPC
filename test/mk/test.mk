#-------------------------------------------------------------------------------
# Copyright (C) 2014-2016 Freescale Semiconductor, Inc.
#
# THIS SOFTWARE IS PROVIDED BY FREESCALE "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL FREESCALE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.
#-------------------------------------------------------------------------------

# Parallel building can sometimes fail on certain systems.

include ../../mk/erpc_common.mk
-include $(TEST_ROOT)/$(TEST_NAME)/variables.mk

#-----------------------------------------------
# setup variables
# ----------------------------------------------

# client or server
ifeq "$(TYPE)" "CLIENT"
APP_TYPE=client
INCLUDES +=  $(ERPC_ROOT)/test/common/gtest
else
APP_TYPE=server
endif

# transport
ifeq "$(TRANSPORT)" "tcp"
CXXFLAGS += -DTRANSPORT_TCP
else ifeq "$(TRANSPORT)" "serial"
CXXFLAGS += -DSERIAL
endif

APP_NAME ?= $(TEST_NAME)_$(APP_TYPE)_$(TRANSPORT)_test
ERPC_OUT_DIR ?= $(RPC_OBJS_ROOT)/erpc_outputs
UNIT_OUT_DIR = $(OUTPUT_ROOT)/$(DEBUG_OR_RELEASE)/$(os_name)/test/
ERPC_NAME ?= $(TEST_NAME)

TEST_DIR = $(OUTPUT_ROOT)/test/$(TEST_NAME)/$(os_name)/$(TRANSPORT)/gcc/$(TEST_NAME)_$(APP_TYPE)/$(DEBUG_OR_RELEASE)
RPC_OBJS_ROOT = $(TEST_DIR)
TARGET_OUTPUT_ROOT = $(RPC_OBJS_ROOT)

UT_COMMON_SRC = $(ERPC_ROOT)/test/common

#-----------------------------------------------
# Include path. Add the include paths like this:
# INCLUDES += ./include/
#-----------------------------------------------
INCLUDES += $(TARGET_OUTPUT_ROOT) \
            $(ERPC_OUT_DIR) \
            $(UNIT_OUT_DIR) \
            $(UT_COMMON_SRC) \
            $(ERPC_ROOT)/erpc_c/config \
            $(ERPC_ROOT)/erpc_c/infra \
            $(ERPC_ROOT)/erpc_c/port \
            $(ERPC_ROOT)/erpc_c/setup \
            $(ERPC_ROOT)/erpc_c/transports \
            $(ERPC_ROOT)/erpcgen/src \
            $(OBJS_ROOT)

#-------------------------------
# Set IDL file
#-------------------------------
IDL_FILE = $(CUR_DIR).erpc

SOURCES +=  $(ERPC_OUT_DIR)/$(ERPC_NAME)_$(APP_TYPE).cpp \
            $(CUR_DIR)_$(APP_TYPE)_impl.cpp \
            $(UT_COMMON_SRC)/unit_test_$(TRANSPORT)_$(APP_TYPE).cpp

ifeq "$(is_linux)" "1"
LIBRARIES += -lpthread -lrt
endif

# Add libtest.a to build.
LIBRARIES += -ltest
LDFLAGS += -L$(OUTPUT_ROOT)/$(DEBUG_OR_RELEASE)/$(os_name)/test/lib

.PHONY: all
all: $(ERPC_OUT_DIR)/$(ERPC_NAME)_$(APP_TYPE).cpp $(ERPC_OUT_DIR)/$(ERPC_NAME)/$(APP_TYPE).py

include $(ERPC_ROOT)/mk/targets.mk

# Define dependency.
$(OUTPUT_ROOT)/test/$(TEST_NAME)/$(CUR_DIR)_$(APP_TYPE)_impl.cpp: $(ERPC_OUT_DIR)/$(ERPC_NAME)_$(APP_TYPE).cpp

# Run erpcgen for C.
$(ERPC_OUT_DIR)/$(ERPC_NAME)_$(APP_TYPE).cpp: $(IDL_FILE)
	@$(call printmessage,orange,Running erpcgen-c $(TEST_NAME), $(subst $(ERPC_ROOT)/,,$<))
	$(at)$(ERPCGEN) -gc -o $(RPC_OBJS_ROOT)/ $(IDL_FILE)

# Run erpcgen for Python.
$(ERPC_OUT_DIR)/$(ERPC_NAME)/$(APP_TYPE).py: $(IDL_FILE)
	@$(call printmessage,orange,Running erpcgen-py $(TEST_NAME), $(subst $(ERPC_ROOT)/,,$<))
	$(at)$(ERPCGEN) -gpy -o $(RPC_OBJS_ROOT)/ $(IDL_FILE)
