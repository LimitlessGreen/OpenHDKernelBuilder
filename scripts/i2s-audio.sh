#!/bin/bash

function fetch_i2s-audio_driver() {
    if [[ ! "$(ls -A rpi-i2s-audio)" ]]; then    
        echo "Download the rpi-i2s-audio driver"
        git clone ${I2SAUDIO_REPO}
    fi

    pushd rpi-i2s-audio
        git fetch
        git reset --hard
        git checkout ${I2SAUDIOU_BRANCH}
        git pull
    popd
}

function build_i2s-audio_driver() {
    if [[ "${PLATFORM}" == "pi" ]]; then
        pushd rpi-i2s-audio
            make clean
            make KSRC=${LINUX_DIR} -j $J_CORES M=$(pwd) modules || exit 1

            install -p -m 644 88x2bu.ko "${PACKAGE_DIR}/lib/modules/${KERNEL_VERSION}" || exit 1
        popd
    fi
}