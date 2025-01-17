#!/bin/bash
# Afaneh menu V2.0

# Variables
DIR=`readlink -f .`
PARENT_DIR=`readlink -f ${DIR}/..`

export CROSS_COMPILE=$PARENT_DIR/env/clang-r487747c/bin/aarch64-linux-gnu-
export CC=$PARENT_DIR/env/clang-r487747c/bin/clang

export PLATFORM_VERSION=14
export ANDROID_MAJOR_VERSION=s
export PATH=$PARENT_DIR/env/clang-r487747c/bin:$PATH
export PATH=$PARENT_DIR/env/build-tools/path/linux-x86:$PATH
export PATH=$PARENT_DIR/env/gas/linux-x86:$PATH
export TARGET_SOC=s5e9925
export LLVM=1 LLVM_IAS=1
export ARCH=arm64
KERNEL_MAKE_ENV="LOCALVERSION=-SilverCore"

# Color
ON_BLUE=`echo -e "\033[44m"`	# On Blue
RED=`echo -e "\033[1;31m"`	# Red
BLUE=`echo -e "\033[1;34m"`	# Blue
GREEN=`echo -e "\033[1;32m"`	# Green
Under_Line=`echo -e "\e[4m"`	# Text Under Line
STD=`echo -e "\033[0m"`		# Text Clear
 
# Functions
pause(){
  read -p "${RED}$2${STD}Press ${BLUE}[Enter]${STD} key to $1..." fackEnterKey
}

clang(){
  if [ ! -d $PARENT_DIR/env/clang-r487747c ]; then
    pause 'clone Android Clang/LLVM Prebuilts'
    git clone https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r487747c $PARENT_DIR/env/clang-r487747c
    . $DIR/build_menu
  fi
}

gas(){
  if [ ! -d $PARENT_DIR/env/gas/linux-x86 ]; then
    pause 'clone prebuilt binaries of GNU `as` (the assembler)'
    git clone https://android.googlesource.com/platform/prebuilts/gas/linux-x86 $PARENT_DIR/env/gas/linux-x86
    . $DIR/build_menu
  fi
}

build_tools(){
  if [ ! -d $PARENT_DIR/env/build-tools ]; then
    pause 'clone prebuilt binaries of build tools'
    git clone https://android.googlesource.com/platform/prebuilts/build-tools $PARENT_DIR/env/build-tools
    . $DIR/build_menu
  fi
}

variant(){
  findconfig=""
  findconfig=($(ls arch/arm64/configs/gki_defconfig))
  declare -i i=1
  shift 2
  for e in "${findconfig[@]}"; do
    echo "$i) $(basename $e | cut -d'_' -f2)"
    i=i+1
  done
  echo ""
  read -p "Select variant: " REPLY
  i="$REPLY"
  if [[ $i -gt 0 && $i -le ${#findconfig[@]} ]]; then
    export v="${findconfig[$i-1]}"
    export VARIANT=$(basename $v | cut -d'_' -f2)
    echo ${VARIANT} selected
    pause 'continue'
  else
    pause 'return to Main menu' 'Invalid option, '
    . $DIR/build_menu
  fi
}

clean(){
  echo "${GREEN}***** Cleaning in Progress *****${STD}"
  make clean
  make mrproper
  [ -d "out" ] && rm -rf out
  echo "${GREEN}***** Cleaning Done *****${STD}"
  pause 'continue'
}

build_kernel(){
  variant
  echo "${GREEN}***** Compiling kernel *****${STD}"
  [ ! -d "out" ] && mkdir out
  make -j$(nproc) -C $(pwd) $KERNEL_MAKE_ENV gki_defconfig
  make -j$(nproc) -C $(pwd) $KERNEL_MAKE_ENV

  [ -e arch/arm64/boot/Image.gz ] && cp arch/arm64/boot/Image.gz $(pwd)/out/Image.gz
  if [ -e arch/arm64/boot/Image ]; then
    cp arch/arm64/boot/Image $(pwd)/out/Image

    echo "${GREEN}***** Ready to Roar *****${STD}"
    pause 'continue'
  else
    pause 'return to Main menu' 'Kernel STUCK in BUILD!, '
  fi
}

anykernel3(){
  if [ ! -d $PARENT_DIR/AnyKernel3 ]; then
    pause 'clone AnyKernel3 - Flashable Zip Template'
    git clone https://github.com/osm0sis/AnyKernel3 $PARENT_DIR/AnyKernel3
  fi
  variant
  if [ -e $DIR/arch/arm64/boot/Image ]; then
    cd $PARENT_DIR/AnyKernel3
    git reset --hard
    cp $DIR/arch/arm64/boot/Image zImage
    sed -i "s/ExampleKernel by osm0sis @ xda-developers/${VARIANT} kernel by arsenals/g" anykernel.sh
    sed -i "s/device.name1=maguro/device.name1=marble/g" anykernel.sh
    sed -i "s/device.name2=toro/device.name2=marblein/g" anykernel.sh
    sed -i "s/device.name3=toroplus/device.name3=/g" anykernel.sh
    sed -i "s/device.name4=tuna/device.name4=/g" anykernel.sh
    sed -i "s/device.name5=/device.name5=/g" anykernel.sh
    zip -r9 $PARENT_DIR/${VARIANT}_kernel_`date '+%Y_%m_%d'`.zip * -x .git README.md *placeholder
    cd $DIR
    pause 'continue'
  else
    pause 'return to Main menu' 'Build kernel first, '
  fi
}

# Run once
clang
gas
build_tools

# Show menu
show_menus(){
  clear
  echo "${ON_BLUE} B U I L D - M E N U ${STD}"
  echo "1. ${Under_Line}B${STD}uild kernel"
  echo "2. ${Under_Line}C${STD}lean"
  echo "3. Make ${Under_Line}f${STD}lashable zip"
  echo "4. E${Under_Line}x${STD}it"
}

# Read input
read_options(){
  local choice
  read -p "Enter choice [ 1 - 4] " choice
  case $choice in
    1|b|B) build_kernel ;;
    2|c|C) clean ;;
    3|f|F) anykernel3;;
    4|x|X) exit 0;;
    *) pause 'return to Main menu' 'Invalid option, '
  esac
}

# Trap CTRL+C, CTRL+Z and quit singles
 
# Step # Main logic - infinite loop
while true
do
  show_menus
  read_options
done
