DOCKER_NAME   = armhf-builder
SRC_DIR       ?= ${shell pwd}/src
JOBS          ?= 8 # more jobs might cause error due to resource limiting
BUILD_CMD     ?= docker run --rm -it \
                -v ${SRC_DIR}:/src_dir \
                ${DOCKER_NAME}

CROSS_COMPILE ?= arm-linux-gnueabihf-
BASH_CMD      := ${BUILD_CMD} /bin/bash -c

all: u-boot linux rfs libinput lvgl_demo

builder:
	@wget -nc https://images.apertis.org/release/v2022/v2022.4/amd64/sdk/ospack_v2022-amd64-sdk_v2022.4.tar.gz
	@docker build -t ${DOCKER_NAME} ${http_proxy:+--build-arg=http_proxy=$http_proxy} ${https_proxy:+--build-arg=https_proxy=$https_proxy} --network host .

u-boot:
	@${BASH_CMD} "make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -j$(JOBS) -C /src_dir/$@ am335x_evm_config all"

linux:
	@${BASH_CMD} "make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -C /src_dir/$@ bb.org_defconfig"
	@${BASH_CMD} "/src_dir/$@/scripts/config --file /src_dir/$@/.config -e INPUT_EVDEV -e HID_MULTITOUCH -e USB_VIDEO_CLASS"
	@${BASH_CMD} "make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -j$(JOBS) -C /src_dir/$@"

rfs:
	wget -nc https://images.apertis.org/release/v2022/v2022.4/armhf/fixedfunction/ospack_v2022-armhf-fixedfunction_v2022.4.tar.gz

libinput:
	@${BASH_CMD} "/src_dir/$@/install.sh"

lvgl_demo: libinput
	@${BASH_CMD} "make -j$(JOBS) CC=${CROSS_COMPILE}gcc -C /src_dir/$@"

clean:
	@${BASH_CMD} "make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -C /src_dir/linux distclean"
	@${BASH_CMD} "make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -C /src_dir/u-boot distclean"
	@${BASH_CMD} "make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -C /src_dir/lvgl_demo clean"
