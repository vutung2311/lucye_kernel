#!/bin/bash
# kernel build script by Tkkg1994 v0.5 (optimized from apq8084 kernel source)

export ARCH=arm64
export BUILD_CROSS_COMPILE=$HOME/opt/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-elf/bin/aarch64-elf-
export BUILD_JOB_NUMBER=`nproc`
export KBUILD_BUILD_USER=BuildUser
export KBUILD_BUILD_HOST=BuildHost
export KERNEL_ROOT=$(pwd)

RDIR=${KERNEL_ROOT}
KERNEL_DEFCONFIG=lucye_nao_us-perf_defconfig

FUNC_BUILD_KERNEL()
{
	rm -rf arch/${ARCH}/boot/dts/*.dtb

	echo ""
        echo "=============================================="
        echo "START : FUNC_BUILD_KERNEL"
        echo "=============================================="
        echo ""
        echo "build common config="$KERNEL_DEFCONFIG ""

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			$KERNEL_DEFCONFIG || exit -1

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
	
	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_KERNEL"
	echo "================================="
	echo ""
}

FUNC_BUILD_RAMDISK()
{
	rm -f ${RDIR}/ramdisk/split_img/boot.img-zImage
	cp ${RDIR}/arch/$ARCH/boot/Image.gz-dtb ${RDIR}/ramdisk/split_img/boot.img-zImage
	cd ${RDIR}/ramdisk/
	./repackimg.sh
}

FUNC_BUILD_ZIP()
{
	cd ${RDIR}
	rm -f ${RDIR}/build/boot.img ${RDIR}/build/system/lib/modules/*.ko
	mv -f ${RDIR}/ramdisk/image-new.img ${RDIR}/build/boot.img
	find -name "*.ko" -not -path "./build/system/lib/modules*" -exec cp {} $RDIR/build/system/lib/modules \;
	cd ${RDIR}/build
	zip kernel_package.zip -r -FS boot.img system/ META-INF
}

# MAIN FUNCTION
rm -rf ./build.log
(
	START_TIME=`date +%s`

	FUNC_BUILD_KERNEL
	FUNC_BUILD_RAMDISK
	FUNC_BUILD_ZIP

	END_TIME=`date +%s`
	
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time was $ELAPSED_TIME seconds"

) 2>&1 | tee -a ./build.log