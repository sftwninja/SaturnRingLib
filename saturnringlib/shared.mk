COMPILER_DIR=$(SDK_ROOT)/../Compiler

MODDIR = $(SDK_ROOT)/../modules
CMODIR = $(COMPILER_DIR)/Other Utilities

STDDIR = $(MODDIR)/danny/INC

SGLDIR = $(MODDIR)/sgl
IPFILE = $(SGLDIR)/IP.BIN
LDFILE = $(SGLDIR)/sgl.linker
SGLLDIR = $(SGLDIR)/LIB
SGLIDIR = $(SGLDIR)/INC

LIBS = $(SGLLDIR)/LIBCPK.A $(SGLLDIR)/SEGA_SYS.A $(SGLLDIR)/LIBCD.A $(SGLLDIR)/LIBSGL.A

# Allow custom IPBIN
ifneq ($(strip $(SRL_IPBIN)),)
	IPFILE = $(SRL_IPBIN);
endif

# include preloader first
PRELOADERSOURCES = $(SGLDIR)/SRC/preloader.cxx
OBJECTS = $(PRELOADERSOURCES:.cxx=.o)

# include extra modules
MODULE_EXTRA_INC =

.DEFAULT_GOAL := all

ifneq ($(strip $(MODULES_EXTRA)),)
	include $(patsubst %, $(SDK_ROOT)/../modules_extra/%/module.mk, $(strip $(MODULES_EXTRA)))
	MODULE_EXTRA_INC += $(patsubst %, -I$(SDK_ROOT)/../modules_extra/%/INC, $(strip $(MODULES_EXTRA)))
	MODULE_OBJECTS = $(MODULE_SOURCES:.c=.o)
	OBJECTS += $(MODULE_OBJECTS:.cxx=.o)
endif

COBJECTS = $(SOURCES:.c=.o)
OBJECTS += $(COBJECTS:.cxx=.o)

ifdef OS
   CC = sh2eb-elf-gcc.exe
   CXX = sh2eb-elf-g++.exe
   LD = sh2eb-elf-gcc.exe
   OBJCOPY = sh2eb-elf-objcopy.exe
else
	ifneq (, $(shell which sh2eb-elf-gcc))
		CC = sh2eb-elf-gcc
		CXX = sh2eb-elf-g++
		LD = sh2eb-elf-gcc
		OBJCOPY = sh2eb-elf-objcopy
	else
		CC = sh-elf-gcc
		CXX = sh-elf-g++
		LD = sh-elf-gcc
		OBJCOPY = sh-elf-objcopy
  endif
endif

GCCMAJORVERSION = $(shell $(CC) --version | head -n 1 | sed 's/^.* //g' | sed 's/[^0-9].//g')

# Handle defaults for user settings
ifeq ($(strip ${SRL_MAX_CD_BACKGROUND_JOBS}),)
	SRL_MAX_CD_BACKGROUND_JOBS=1
endif

ifeq ($(strip ${SRL_MAX_CD_FILES}),)
	SRL_MAX_CD_FILES=255
endif

ifeq ($(strip ${SRL_MAX_CD_RETRIES}),)
	SRL_MAX_CD_RETRIES=5
endif

ifeq ($(strip ${SRL_HIGH_RES}), 1)
	CCFLAGS += -DSRL_HIGH_RES
endif

ifeq ($(strip ${SRL_FRAMERATE}),)
	CCFLAGS += -DSRL_FRAMERATE=0
else
	CCFLAGS += -DSRL_FRAMERATE=$(strip ${SRL_FRAMERATE})
endif

ifeq ($(strip ${SRL_MAX_TEXTURES}),)
	SRL_MAX_TEXTURES=100
endif

ifeq ($(strip ${DEBUG}), 1)
	CCFLAGS += -DDEBUG
endif

ifneq ($(strip ${SRL_LOG_LEVEL}),)
	CCFLAGS += -DSRL_LOG_LEVEL=$(strip ${SRL_LOG_LEVEL})
endif

ifeq ($(strip ${SRL_USE_SGL_SOUND_DRIVER}), 1)
	CCFLAGS += -DSRL_USE_SGL_SOUND_DRIVER=$(strip ${SRL_USE_SGL_SOUND_DRIVER})
	LIBS += $(SGLLDIR)/LIBSND.A

	ifeq ($(strip ${SRL_ENABLE_FREQ_ANALYSIS}),1)
		CCFLAGS += -DSRL_ENABLE_FREQ_ANALYSIS=1
	endif
endif

ifneq ($(strip ${SRL_MODE}),PAL)
	ifneq (${SRL_MODE},NTSC)
		SRL_MODE = NTSC
	endif
endif

ifeq ($(strip ${SRL_DEBUG_MAX_PRINT_LENGTH}),)
	SRL_DEBUG_MAX_PRINT_LENGTH = 45
endif

ifeq ($(strip ${SRL_DEBUG_MAX_LOG_LENGTH}),)
	SRL_DEBUG_MAX_LOG_LENGTH = 80
endif

CCFLAGS += -DSRL_MODE_$(strip ${SRL_MODE}) \
	-DSRL_MAX_TEXTURES=$(strip ${SRL_MAX_TEXTURES}) \
	-DSRL_MAX_CD_BACKGROUND_JOBS=$(strip ${SRL_MAX_CD_BACKGROUND_JOBS}) \
	-DSRL_MAX_CD_FILES=$(strip ${SRL_MAX_CD_FILES}) \
	-DSRL_MAX_CD_RETRIES=$(strip ${SRL_MAX_CD_RETRIES}) \
	-DSRL_DEBUG_MAX_PRINT_LENGTH=$(strip ${SRL_DEBUG_MAX_PRINT_LENGTH}) \
	-DSRL_DEBUG_MAX_LOG_LENGTH=$(strip ${SRL_DEBUG_MAX_LOG_LENGTH}) \

# CD assets
ASSETS_DIR = ./cd/data
MUSIC_DIR = ./cd/music

# Handle work area
ifneq ($(strip ${SGL_MAX_VERTICES}),)
	SYSFLAGS += -DSGL_MAX_VERTICES=$(strip ${SGL_MAX_VERTICES})
else
	SYSFLAGS += -DSGL_MAX_VERTICES=2500
endif

ifneq ($(strip ${SGL_MAX_POLYGONS}),)
	SYSFLAGS += -DSGL_MAX_POLYGONS=$(strip ${SGL_MAX_POLYGONS})
else
	SYSFLAGS += -DSGL_MAX_POLYGONS=1700
endif

ifneq ($(strip ${SGL_MAX_EVENTS}),)
	SYSFLAGS += -DSGL_MAX_EVENTS=$(strip ${SGL_MAX_EVENTS})
else
	SYSFLAGS += -DSGL_MAX_EVENTS=64
endif

ifneq ($(strip ${SGL_MAX_WORKS}),)
	SYSFLAGS += -DSGL_MAX_WORKS=$(strip ${SGL_MAX_WORKS})
else
	SYSFLAGS += -DSGL_MAX_WORKS=256
endif

# Add custom FLAGS
ifneq ($(strip ${SRL_CUSTOM_CCFLAGS}),)
	CCFLAGS += $(strip ${SRL_CUSTOM_CCFLAGS})
endif

BUILD_ELF = $(BUILD_DROP)/$(CD_NAME).elf
BUILD_ISO = $(BUILD_ELF:.elf=.iso)
BUILD_BIN = $(BUILD_ELF:.elf=.bin)
BUILD_CUE = $(BUILD_ELF:.elf=.cue)
BUILD_MAP = $(BUILD_ELF:.elf=.map)

TLSFDIR = $(MODDIR)/tlsf
DUMMYIDIR = $(MODDIR)/dummy
SATURNMATHPPDIR = $(MODDIR)/SaturnMathPP

SYSSOURCES += $(SGLLDIR)/../SRC/workarea.c

ifdef SRL_MALLOC_METHOD
	ifeq ($(SRL_MALLOC_METHOD), TLSF)
		SYSSOURCES += $(TLSFDIR)/tlsf.c
		USE_TLSF_ALLOCATOR := TRUE
	endif
endif

SYSOBJECTS = $(SYSSOURCES:.c=.o)

# General compilation flags
CCFLAGS += $(SYSFLAGS) -W -m2 -c -O2 -Wno-strict-aliasing \
					-I$(DUMMYIDIR) -I$(SATURNMATHPPDIR) -I$(SGLIDIR) -I$(STDDIR) -I$(TLSFDIR) -I$(SDK_ROOT) $(MODULE_EXTRA_INC)
LDFLAGS = -m2 -L$(SGLLDIR) -Xlinker -T$(LDFILE) -Xlinker -Map \
					-Xlinker $(BUILD_MAP) -Xlinker -e -Xlinker ___Start -nostartfiles

ifeq "$(GCCMAJORVERSION)" "14"
    LDFLAGS += -specs=nosys.specs
endif

# Add custom FLAGS
ifneq ($(strip ${SRL_CUSTOM_LDFLAGS}),)
	LDFLAGS += $(strip ${SRL_CUSTOM_LDFLAGS})
endif

# pre-build script
ifneq ("$(wildcard ./pre.makefile)","")
	include ./pre.makefile
else
pre_build:
	$(info ****** No pre build steps ******)
endif

# post-build script
ifneq ("$(wildcard ./post.makefile)","")
	include ./post.makefile
else
post_build:
	$(info ****** No post build steps ******)
endif

# Compilation tasks
%.o : %.c
	$(CC) $< $(CCFLAGS) -std=c2x -o $@

%.o : %.cxx
	$(CXX) $< $(CCFLAGS) -std=c++23 -fpermissive -fno-exceptions -fno-rtti -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-threadsafe-statics -fno-use-cxa-atexit -o $@

compile_objects : $(OBJECTS) $(SYSOBJECTS)
	$(info ****** Info ******)
	$(info Maximum textures : ${SRL_MAX_TEXTURES})
	$(info Maximum vertices : ${SGL_MAX_VERTICES})
	$(info Maximum polygons : ${SGL_MAX_POLYGONS})
	$(info Maximum events : ${SGL_MAX_EVENTS})
	$(info Maximum work : ${SGL_MAX_WORKS})
	$(info Log level selected : $(if $(strip ${SRL_LOG_LEVEL}),${SRL_LOG_LEVEL},NONE))
	$(info Maximum Log length : $(if $(strip ${SRL_DEBUG_MAX_LOG_LENGTH}),${SRL_DEBUG_MAX_LOG_LENGTH},0))
	$(info ******************)
	mkdir -p $(MUSIC_DIR)
	mkdir -p $(ASSETS_DIR)
	mkdir -p $(BUILD_DROP)
	test -f $(ASSETS_DIR)/ABS.TXT || echo "NOT Abstracted by SEGA" >> $(ASSETS_DIR)/ABS.TXT
	test -f $(ASSETS_DIR)/BIB.TXT || echo "NOT Bibliographiced by SEGA" >> $(ASSETS_DIR)/BIB.TXT
	test -f $(ASSETS_DIR)/CPY.TXT || touch $(ASSETS_DIR)/CPY.TXT
	$(CC) $(LDFLAGS) $(SYSOBJECTS) $(OBJECTS) $(LIBS) -o $(BUILD_ELF)

convert_binary : compile_objects
	$(OBJCOPY) -O binary $(BUILD_ELF) ./cd/data/0.bin

create_iso : convert_binary
ifeq ($(strip ${SRL_USE_SGL_SOUND_DRIVER}),1)
	cp -r $(SGLDIR)/DRV/. ./cd/data/
ifeq ($(strip ${SRL_ENABLE_FREQ_ANALYSIS}), 1)
	cp $(SGLDIR)/DSP/3BANDANA.EXB ./cd/data/
endif
endif
	xorrisofs --norock -quiet -sysid "SEGA SATURN" -volid "SaturnApp" -volset "SaturnApp" \
	-publisher "SEGA ENTERPRISES, LTD." -preparer "SEGA ENTERPRISES, LTD." -appid "SaturnApp" \
	-abstract "$(ASSETS_DIR)/ABS.TXT" -copyright "$(ASSETS_DIR)/CPY.TXT" -biblio "$(ASSETS_DIR)/BIB.TXT" -generic-boot $(IPFILE) \
	-full-iso9660-filenames -o $(BUILD_ISO) $(ASSETS_DIR) $(ENTRYPOINT)

# Create CUE sheet
create_bin_cue: create_iso
	# Convert ISO to MODE1/2352 raw format with proper EDC/ECC
	@echo "Converting ISO to MODE1/2352 raw format..."
	@if [ -n "$(OS)" ]; then \
		$(SDK_ROOT)/../tools/bin/win/iso2raw/iso2raw.exe $(BUILD_ISO) -o $(BUILD_BIN); \
	else \
		host_platform=$$(uname -s); \
		if [ "$$host_platform" = "Linux" ]; then \
			$(SDK_ROOT)/../tools/bin/lin/iso2raw/iso2raw $(BUILD_ISO) -o $(BUILD_BIN); \
		elif [ "$$host_platform" = "Darwin" ]; then \
			$(SDK_ROOT)/../tools/bin/mac/iso2raw/iso2raw $(BUILD_ISO) -o $(BUILD_BIN); \
		else \
			echo "Unsupported platform: $$host_platform"; \
			exit 1; \
		fi; \
	fi; \
	echo 'FILE "$(CD_NAME).bin" BINARY' > $(BUILD_CUE)
	echo '  TRACK 01 MODE1/2352' >> $(BUILD_CUE)
	echo '    INDEX 01 00:00:00' >> $(BUILD_CUE)

# Check if tracklist file exists and determine audio file order
ifneq (,$(wildcard $(MUSIC_DIR)/tracklist))
    # Read files from tracklist, prepend MUSIC_DIR to each line, filter out empty lines and comments
    TRACKLIST_LINES := $(shell sed 's/^\s*//;s/\s*$$//;/^$$/d;/^#/d' $(MUSIC_DIR)/tracklist)
    AUDIO_FILES := $(foreach line,$(TRACKLIST_LINES),$(word 1,$(subst :, ,$(line))))
    AUDIO_FILES := $(addprefix $(MUSIC_DIR)/,$(AUDIO_FILES))
else
    # Fallback to original behavior - find all supported audio files
    AUDIO_FILES = $(patsubst ./%,%,$(shell find $(MUSIC_DIR) \( -name '*.mp3' -o -name '*.wav' -o -name '*.ogg' -o -name '*.flac' -o -name '*.aac' -o -name '*.m4a' -o -name '*.wma' \)))
endif

AUDIO_FILES_RAW = $(patsubst %,%.raw,$(AUDIO_FILES))

# Function to get the filter option for a given audio file
define get_filter_option
$(strip $(shell if [ -f "$(MUSIC_DIR)/tracklist" ]; then \
	basename_file=$$(basename "$(1)"); \
	grep "^$$basename_file:" "$(MUSIC_DIR)/tracklist" | head -1 | cut -d: -f2; \
fi))
endef

%.raw: %
	@filter_option="$(call get_filter_option,$<)"; \
	if [ -n "$$filter_option" ]; then \
		echo "Processing $< with filter option: $$filter_option"; \
	else \
		echo "Processing $< with no filter option"; \
	fi; \
	# apply any quick filter to the file through the sox conversion \
	if [ -n "$$filter_option" ]; then \
		filter_var="SRL_SOX_FILTERS_$$filter_option"; \
		filter_cmd=$$(eval echo \$$$$filter_var); \
		if [ -n "$$filter_cmd" ]; then \
			sox "$<" -t raw -r 44100 -e signed-integer -b 16 -c 2 "$@" $$filter_cmd; \
		else \
			echo "Warning: No SOX_FILTERS_$$filter_option defined, using no filters"; \
			sox "$<" -t raw -r 44100 -e signed-integer -b 16 -c 2 "$@"; \
		fi; \
	else \
		sox "$<" -t raw -r 44100 -e signed-integer -b 16 -c 2 "$@"; \
	fi; \
	# check to ensure the raw file is sector aligned to prevent track drift \
	size=$$(stat -c%s "$@"); \
	target_sectors=$$((size / 2352)); \
	if [ $$((size % 2352)) -ne 0 ]; then \
		target_sectors=$$((target_sectors + 1)); \
	fi; \
	target_size=$$((target_sectors * 2352)); \
	if [ $$size -lt $$target_size ]; then \
		mv "$@" "$@.unpadded"; \
		dd if=/dev/zero bs=1 count=$$((target_size - size)) of=padding.tmp status=none; \
		cat "$@.unpadded" padding.tmp > "$@"; \
		rm -f padding.tmp "$@.unpadded"; \
	fi; \
	echo "Converted $< to $@ ($$size -> $$target_size bytes, $$target_sectors sectors)";

add_audio_to_bin_cue: $(AUDIO_FILES_RAW)
	track=2; \
	total_size=$$(stat -c%s "$(BUILD_BIN)"); \
  sectors=$$((total_size / 2352)); \
	echo "Starting with $$total_size bytes ($$sectors sectors)"; \
	for i in $^; do \
		echo "Track $$track: starts at sector $$sectors"; \
		echo '  TRACK' $$(printf "%02d" $$track) 'AUDIO' >> $(BUILD_CUE); \
		# 150 frames are required to gap the audio track when directly following data \
		# See Section 20 of ECMA-130/Yellow Book spec \
		if [ $$track -eq 2 ]; then \
			echo '    PREGAP   00:02:00' >> $(BUILD_CUE); \
		fi; \
		index_sectors=$$sectors; \
		minutes=$$((index_sectors / (60 * 75))); \
		remaining=$$((index_sectors % (60 * 75))); \
		seconds=$$((remaining / 75)); \
		frames=$$((remaining % 75)); \
    msf=$$(printf "%02d:%02d:%02d" $$minutes $$seconds $$frames); \
		echo "  INDEX calculation: sector $$index_sectors = $$msf"; \
		if [ $$frames -ge 75 ]; then \
			echo "  ERROR: Invalid frame count $$frames (must be 0-74)"; \
			echo "  This indicates sector misalignment in the audio file(s)"; \
			exit 1; \
		fi; \
		echo '    INDEX 01' $$msf >> $(BUILD_CUE); \
		size=$$(stat -c%s "$$i"); \
		if [ $$((size % 2352)) -ne 0 ]; then \
			echo "  ERROR: File $$i is not sector-aligned ($$size bytes)"; \
			echo "  File size must be a multiple of 2352 bytes"; \
			exit 1; \
		fi; \
		sectors_in_file=$$((size / 2352)); \
		echo "  Adding $$i: $$size bytes ($$sectors_in_file sectors)"; \
		cat "$$i" >> $(BUILD_BIN); \
		total_size=$$((total_size + size)); \
		echo "  New total: $$total_size bytes ($$((total_size / 2352)) sectors)"; \
		track=$$((track + 1)); \
    sectors=$$((sectors + $$sectors_in_file)); \
	done
	rm -f $(AUDIO_FILES_RAW)

build_bin_cue: create_bin_cue add_audio_to_bin_cue

# CLONE_CD_PATH = $(BUILD_DROP)/CloneCdFiles
# CLONE_CD_CCD = $(CLONE_CD_PATH)/$(CD_NAME).ccd
# CLONE_CD_SUB = $(CLONE_CD_PATH)/$(CD_NAME).sub
# CLONE_CD_IMG = $(CLONE_CD_PATH)/$(CD_NAME).img

# create_clone_cd_files: build_bin_cue
# 	mkdir -p $(CLONE_CD_PATH)
# 	cp $(BUILD_BIN) $(CLONE_CD_IMG)
# 	touch $(CLONE_CD_SUB)
# 	echo "[CloneCD]" > $(CLONE_CD_CCD)
# 	echo "Version=3" >> $(CLONE_CD_CCD)
# 	echo "DiscType=CD" >> $(CLONE_CD_CCD)
# 	echo "Session=1" >> $(CLONE_CD_CCD)
# 	trackno=1; \
# 	while IFS= read -r line; do \
# 		if [[ $$line == TRACK* ]]; then \
# 			echo "[Session 1]" >> $(CLONE_CD_CCD); \
# 			echo "PreGapMode=2" >> $(CLONE_CD_CCD); \
# 			echo "PreGapSubC=0" >> $(CLONE_CD_CCD); \
# 			((trackno++)); \
# 		fi; \
# 		if [[ $$line == *BINARY ]]; then \
# 			echo "Point=0xA0" >> $(CLONE_CD_CCD); \
# 			echo "ADR=0x01" >> $(CLONE_CD_CCD); \
# 			echo "Control=0x04" >> $(CLONE_CD_CCD); \
# 			echo "TrackNo=$$trackno" >> $(CLONE_CD_CCD); \
# 			echo "AMin=0" >> $(CLONE_CD_CCD); \
# 			echo "ASec=0" >> $(CLONE_CD_CCD); \
# 			echo "AFrame=0" >> $(CLONE_CD_CCD); \
# 			echo "ALBA=-150" >> $(CLONE_CD_CCD); \
# 			echo "Zero=0" >> $(CLONE_CD_CCD); \
# 			echo "PMin=1" >> $(CLONE_CD_CCD); \
# 			echo "PSec=0" >> $(CLONE_CD_CCD); \
# 			echo "PFrame=0" >> $(CLONE_CD_CCD); \
# 			echo "PLBA=0" >> $(CLONE_CD_CCD); \
# 		fi; \
# 		if [[ $$line == *INDEX* ]]; then \
# 			IFS=':' read -ra ADDR <<< "$${line##* }"; \
# 			echo "Point=0x01" >> $(CLONE_CD_CCD); \
# 			echo "ADR=0x01" >> $(CLONE_CD_CCD); \
# 			echo "Control=0x04" >> $(CLONE_CD_CCD); \
# 			echo "TrackNo=$$trackno" >> $(CLONE_CD_CCD); \
# 			echo "AMin=$${ADDR[0]}" >> $(CLONE_CD_CCD); \
# 			echo "ASec=$${ADDR[1]}" >> $(CLONE_CD_CCD); \
# 			echo "AFrame=$${ADDR[2]}" >> $(CLONE_CD_CCD); \
# 			echo "ALBA=-150" >> $(CLONE_CD_CCD); \
# 			echo "Zero=0" >> $(CLONE_CD_CCD); \
# 			echo "PMin=$${ADDR[0]}" >> $(CLONE_CD_CCD); \
# 			echo "PSec=$${ADDR[1]}" >> $(CLONE_CD_CCD); \
# 			echo "PFrame=$${ADDR[2]}" >> $(CLONE_CD_CCD); \
# 			echo "PLBA=0" >> $(CLONE_CD_CCD); \
# 		fi; \
# 	done < $(BUILD_CUE)

clean:
	rm -f $(SGLLDIR)/../SRC/*.o
	rm -f $(OBJECTS) $(BUILD_ELF) $(BUILD_ISO) $(BUILD_MAP) $(ASSETS_DIR)/0.bin
	rm -f $(AUDIO_FILES_RAW)
ifeq ($(strip ${SRL_USE_SGL_SOUND_DRIVER}),1)
	rm -f $(ASSETS_DIR)/SDDRVS.DAT $(ASSETS_DIR)/SDDRVS.TSK $(ASSETS_DIR)/BOOTSND.MAP
ifeq ($(strip ${SRL_ENABLE_FREQ_ANALYSIS}), 1)
	rm -f $(ASSETS_DIR)/3BANDANA.EXB
endif
endif
	rm -rf $(BUILD_DROP)/

build : pre_build build_bin_cue post_build

all: clean build
