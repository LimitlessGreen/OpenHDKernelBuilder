#!/bin/bash

PLATFORM=$1
DISTRO=$2

##############
### Config ###
##############

PI_TOOLS_REPO=https://github.com/raspberrypi/tools.git
PI_TOOLS_BRANCH=master

# Fixed at v5.2.20 until 5.3.4 works for injection
RTL_8812AU_REPO=https://github.com/OpenHD/rtl8812au.git
RTL_8812AU_BRANCH=20200719.1

RTL_8812BU_REPO=https://github.com/OpenHD/rtl88x2bu.git
RTL_8812BU_BRANCH=5.6.1_30362.20181109_COEX20180928-6a6a


V4L2LOOPBACK_REPO=https://github.com/OpenHD/v4l2loopback.git
V4L2LOOPBACK_BRANCH=openhd1



#####################
### BUILD HELPERS ###
#####################

SRC_DIR=$(pwd)
LINUX_DIR=$(pwd)/linux-${PLATFORM}
CONFIGS=$(pwd)/configs
J_CORES=$(nproc)
PACKAGE_DIR=$(pwd)/package

# load helper scripts
for File in scripts/*.sh; do
    source ${File}
    echo "LOAD ${File}"
done

# Remove previous build dir and recreate
init

###################   Env's like $ARCH
### BUILD ENV's ###   and $CROSS_COMPILE
###################   are set here

setup_pi_env



build_pi_kernel() {
    echo "Building pi kernel"

    pushd ${LINUX_DIR}

        echo "Set kernel config"
        cp "${CONFIGS}/.config-${KERNEL_BRANCH}-${ISA}" ./.config || exit 1

        make clean

        yes "" | make oldconfig || exit 1

        KERNEL=${KERNEL} KBUILD_BUILD_TIMESTAMP='' make -j $J_CORES zImage modules dtbs || exit 1

        echo "Copy kernel"
        cp arch/arm/boot/zImage "${PACKAGE_DIR}/usr/local/share/openhd/kernel/${KERNEL}.img" || exit 1

        echo "Copy kernel modules"
        make -j $J_CORES INSTALL_MOD_PATH="${PACKAGE_DIR}" modules_install || exit 1

        echo "Copy DTBs"
        cp arch/arm/boot/dts/*.dtb "${PACKAGE_DIR}/usr/local/share/openhd/kernel/dtb/" || exit 1
        cp arch/arm/boot/dts/overlays/*.dtb* "${PACKAGE_DIR}/usr/local/share/openhd/kernel/overlays/" || exit 1
        cp arch/arm/boot/dts/overlays/README "${PACKAGE_DIR}/usr/local/share/openhd/kernel/overlays/" || exit 1

        # prevents the inclusion of firmware that can conflict with normal firmware packages, dpkg will complain. there
        # should be a kernel config to stop installing this into the package dir in the first place
        rm -r "${PACKAGE_DIR}/lib/firmware/*"
    popd

    # Build Realtek drivers
    build_rtl8812au_driver
    build_rtl8812bu_driver

    cp ${SRC_DIR}/overlay/boot/* "${PACKAGE_DIR}/usr/local/share/openhd/kernel/" || exit 1

    depmod -b ${PACKAGE_DIR} ${KERNEL_VERSION}
}

prepare_build() {
    check_time
    fetch_pi_source
    fetch_rtl8812au_driver
    fetch_rtl8812bu_driver
    fetch_v4l2loopback_driver
    build_pi_kernel
}

if [[ "${PLATFORM}" == "pi" ]]; then
    # a simple hack, we want 3 kernels in one package so we source 3 different configs and build them all
    source $(pwd)/kernels/${PLATFORM}-${DISTRO}-v6
    prepare_build

    source $(pwd)/kernels/${PLATFORM}-${DISTRO}-v7
    prepare_build

    if [[ -f "$(pwd)/kernels/${PLATFORM}-${DISTRO}-v7l" ]]; then
        source $(pwd)/kernels/${PLATFORM}-${DISTRO}-v7l
        prepare_build
    fi
fi

copy_overlay
package

post_processing

# Show cache stats
ccache -s
