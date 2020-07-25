#!/usr/bin/env bash

mkdir -p /boot/overlays

# crude hack to avoid making people put fonts somewhere else
cp -a /usr/local/share/openhd/kernel/overlays/* /boot/overlays/
cp -a /usr/local/share/openhd/kernel/kernel.img /boot/
cp -a /usr/local/share/openhd/kernel/kernel7.img /boot/
cp -a /usr/local/share/openhd/kernel/kernel7l.img /boot/ > /dev/null 2>&1 || true
cp -a /usr/local/share/openhd/kernel/dtb/* /boot/

cp -a /usr/local/share/openhd/kernel/1to3b_x.elf /boot/ || true
cp -a /usr/local/share/openhd/kernel/1to3bup.dat /boot/ || true
cp -a /usr/local/share/openhd/kernel/zero_x.elf /boot/ || true
cp -a /usr/local/share/openhd/kernel/zeroup_x.dat /boot/ || true

depmod -a

mount -oremount,ro /boot || true

function add_module() {
    local module=$1
    
    grep "${module}" /etc/modules
    if [[ "$?" -ne 0 ]]; then
        echo "${module}" >> /etc/modules
    fi
}

add_module "i2c-dev"
add_module "rcio_core"
add_module "rcio_spi"