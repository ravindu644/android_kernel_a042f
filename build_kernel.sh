#!/bin/bash
export ARCH=arm64
export RDIR="$(pwd)"
export KBUILD_BUILD_USER="@ravindu644"

#init ksu next
git submodule init && git submodule update

#export toolchain paths
export BUILD_CROSS_COMPILE="${RDIR}/toolchains/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-"
export BUILD_CC="${RDIR}/toolchains/clang-r383902/bin/clang"

#output dir
if [ ! -d "${RDIR}/out" ]; then
    mkdir -p "${RDIR}/out"
fi

#build dir
if [ ! -d "${RDIR}/build" ]; then
    mkdir -p "${RDIR}/build"
else
    rm -rf "${RDIR}/build" && mkdir -p "${RDIR}/build"
fi

#build options
export ARGS="
-C $(pwd) \
O=$(pwd)/out \
-j$(nproc) \
ARCH=arm64 \
CROSS_COMPILE=${BUILD_CROSS_COMPILE} \
CC=${BUILD_CC} \
CLANG_TRIPLE=aarch64-linux-gnu- \
KCFLAGS=-w \
CONFIG_SECTION_MISMATCH_WARN_ONLY=y \
"

#build kernel image
build_kernel(){
    make ${ARGS} clean && make ${ARGS} mrproper
    make ${ARGS} a04e_defconfig custom.config
    make ${ARGS} menuconfig
    make ${ARGS} || exit 1
    cp out/arch/arm64/boot/Image.gz $(pwd)/arch/arm64/boot/Image.gz
}

#build boot.img
build_boot() {    
    rm -f ${RDIR}/AIK-Linux/split_img/boot.img-kernel ${RDIR}/AIK-Linux/boot.img
    cp "${RDIR}/out/arch/arm64/boot/Image.gz" ${RDIR}/AIK-Linux/split_img/boot.img-kernel
    mkdir -p ${RDIR}/AIK-Linux/ramdisk/{debug_ramdisk,dev,metadata,mnt,proc,second_stage_resources,sys}
    cd ${RDIR}/AIK-Linux && ./repackimg.sh --nosudo && mv image-new.img ${RDIR}/build/boot.img
}

#build odin flashable tar
build_tar(){
    cd ${RDIR}/build
    tar -cvf "KernelSU-Next-SM-A04e.tar" boot.img && rm boot.img
    echo -e "\n[i] Build Finished..!\n" && cd ${RDIR}
}

build_kernel
build_boot
build_tar
