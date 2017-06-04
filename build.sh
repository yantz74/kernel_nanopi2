#!/bin/bash
#########################################################################
# Configure these
#########################################################################

MAKE_CONFIG_FILE="yantz_defconfig"
export KBUILD_BUILD_USER="yantz"
export KBUILD_BUILD_HOST="xda"
export CROSS_COMPILE=/opt/FriendlyARM/toolchain/4.9.3/bin/arm-linux-
export USE_CCACHE=1
STRIP=/opt/FriendlyARM/toolchain/4.9.3/bin/arm-linux-strip
#########################################################################
# End config
#########################################################################

export ARCH=arm
export SUBARCH=arm

OUT_DIR="out"
KERNEL_DIR=$PWD
FINAL_DIR=${KERNEL_DIR}/yantz
KERN_IMG=${OUT_DIR}/arch/arm/boot/uImage
NR_CPUS=$(grep -c ^processor /proc/cpuinfo)
BUILD_START=$(date +"%s")
modord="${KERNEL_DIR}/${OUT_DIR}/modules.order"
cpmod="${FINAL_DIR}/modules.txt"
buildtimestamp="-$(date +"%Y%m%d_%H%M")"

blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo -e "$red Cleaning previous build $nocol";

if [ -e ${FINAL_DIR}/kernel/uImage ]; then
	rm ${FINAL_DIR}/kernel/uImage
fi
if [ -e ${FINAL_DIR}/modules.txt ]; then
	rm ${FINAL_DIR}/modules.txt
fi
rm -rf ${FINAL_DIR}/modules
mkdir ${FINAL_DIR}/modules
if [ -d ${OUT_DIR} ]; then
	rm -rf ${OUT_DIR}
fi
mkdir ${OUT_DIR}

echo -e "$cyan Make config (${MAKE_CONFIG_FILE}) $nocol";
make O=${OUT_DIR} ${MAKE_CONFIG_FILE}

echo -e "$cyan Build kernel using ${NR_CPUS} cores $nocol";
ccache make O=${OUT_DIR} -j${NR_CPUS} LOCALVERSION="-${buildtimestamp}" uImage modules

if ! [ -a $KERN_IMG ]; then
	echo -e "$red Kernel Compilation failed! Fix the errors! $nocol";
	exit 1
fi

echo -e "$cyan Copy kernel $nocol";
name="${FINAL_DIR}/kernel/uImage_${buildtimestamp}"
cp ${KERN_IMG} ${name}
cd ${FINAL_DIR}

echo -e "$cyan Copy external modules $nocol";
cp $modord $cpmod
sed -i "s/^kernel//g" $cpmod
count=0
while read -r line || [[ -n "$line" ]]; do
  name="${KERNEL_DIR}/${OUT_DIR}$line"
  cp "$name" "${FINAL_DIR}/modules"
  let count+=1
done < "$cpmod"
${STRIP} --strip-unneeded ${FINAL_DIR}/modules/*.ko
echo "$count modules copied and stripped"

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol";
echo -e "Kernel uImage at ${FINAL_DIR}/kernel";
echo -e "Kernel modules at ${FINAL_DIR}/modules";

