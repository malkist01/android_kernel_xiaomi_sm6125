#!/bin/sh

# Kernel Build Script by Mahiroo aka Yudaa

trap 'echo -e "\n\033[91m[!] Build dibatalkan oleh user.\033[0m"; tg_channelcast "⚠️ <b>Build kernel dibatalkan oleh user!</b>"; cleanup_files; exit 1' INT
exec > >(tee -a build.log) 2>&1

# ============================
# Setup
# ============================
PHONE="Ginkgo"
DEFCONFIG="vendor/trinket-perf_defconfig"
CONFIG="vendor/xiaomi-trinket.config vendor/ginkgo.config"
CLANG="Aosp Clang 23.0"
ZIPNAME="KernelTest-Ginkgo-$(date '+%Y%m%d-%H%M').zip"
BOT_TOKEN="8691384652:AAHbKtOpbMp-Kc9JvKyil4aPsMfo5hdA-F8"
CHAT_ID="-5173179904"
COMPILERDIR="$(pwd)/../aosp-clang"
EXTRA_FOLDER="$(pwd)/../extra"
export KBUILD_BUILD_USER="Mahiroo"
export KBUILD_BUILD_HOST="HiraTeam"
IN_DTBO="out/arch/arm64/boot/dts/xiaomi/ginkgo-trinket-overlay.dtbo"
mkdir -p "out/arch/arm64/boot/dts/xiaomi/.ginkgo-trinket-overlay.dtbo.qcom-base"

# ============================
# Variabel Telegram dan Device Info
# ============================
DEVICE="Redmi Note 8"
DISTRO="$(lsb_release -d | awk -F'\t' '{print $2}')"
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
COMMIT_POINT="$(git rev-parse HEAD)"
CPU_NAME="$(lscpu | grep 'Model name' | awk -F': ' '{print $2}')"
PROCS="$(nproc --all)"
TOTAL_RAM_GB="$(free -g | awk '/^Mem:/{print $2}')"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"
MESSAGE_ERROR="Error Build untuk $PHONE Dibatalkan!"
kernel="out/arch/arm64/boot/Image.gz"
dtbo="out/arch/arm64/boot/dtbo.img"

# ============================
# Warna output
# ============================
cyan="\033[96m"
green="\033[92m"
red="\033[91m"
reset="\033[0m"

function install_dependencies() {
    echo -e "${cyan}==> Instalasi dependensi...${reset}"
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends python3-pip git zip unzip gcc g++ make ninja-build file bc bison flex libfl-dev libssl-dev libelf-dev wget build-essential python3-dev python3-setuptools rsync ccache llvm-dev libncurses6 libfdt-dev binwalk
}

function clang() {
if [ -d $COMPILERDIR ] ; then
echo -e " "
echo -e "\n$green[!] Lets's Build UwU...\033[0m \n"
else
echo -e " "
echo -e "\n$red[!] clang Dir Not Found!!!\033[0m \n"
sleep 2
echo -e "$green[+] Wait.. Cloning clang...\033[0m \n"
sleep 2
git clone --depth=1 https://github.com/TheSillyOk/kernel_extra -b main $EXTRA_FOLDER
wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/747f0cceb48f48bf7cf497a3e01af1389266904b/clang-r614150.tar.gz -O clang.tar.gz
    rm -rf $COMPILERDIR 
    mkdir $COMPILERDIR 
    tar -xvf clang.tar.gz -C $COMPILERDIR
    rm -rf clang.tar.gz
sleep 1
echo
echo -e "\n$green[!] Lets's Build UwU...\033[0m \n"
sleep 1
fi
}

function verify_toolchain_versions() {
    echo -e "${green}🔧 Clang  : $(${CLANG_DIR}/bin/clang --version | head -n 1)${reset}"
}

function tg_channelcast() {
    local msg=""
    for POST in "$@"; do
        msg+="${POST}"$'\n'
    done
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d disable_web_page_preview=true \
        -d parse_mode=HTML \
        -d text="${msg}"
}

function send_initial_message() {
    tg_channelcast \
        "🚀 <b>Kernel Build Dimulai!</b>" \
        "📱 <b>Device :</b> <code>$DEVICE</code>" \
        "🛠️ <b>Compiler :</b> <code>$CLANG</code>" \
        "🌿 <b>Branch :</b> <code>$PARSE_BRANCH</code>" \
        "📝 <b>Commit :</b> $COMMIT_POINT" \
        "🧠 <b>CPU :</b> <code>$CPU_NAME ($PROCS cores)</code>" \
        "💾 <b>RAM :</b> <code>$TOTAL_RAM_GB GB</code>" \
        "📅 <b>Date :</b> <code>$DATE</code>" \
        "⌛️ Build berjalan..."
}

function send_success_message() {
    tg_channelcast \
        "✅ <b>Build Sukses!</b>" \
        "📱 <b>Device :</b> <code>$DEVICE</code>" \
        "📦 <b>ZIP:</b> <code>$ZIPNAME</code>" \
        "🕒 <b>Durasi:</b> <code>$((DIFF / 60)) menit $((DIFF % 60)) detik</code>"
}

function send_log() {
    curl -s -F "chat_id=${CHAT_ID}" -F "document=@log.txt" -F "caption=${MESSAGE_ERROR}" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" > /dev/null
}

function clean() {
    echo -e "${red}[!] Clean...${reset}"
    rm -rf log.txt full-build.log out/full_defconfig "$ZIPNAME"
}

function clean_out_dir() {
    echo -e "${red}[!] Bersihkan out/...${reset}"
    [ -d out ] && rm -rf out/* || mkdir out
}

function cleanup_files() {
    echo -e "${red}[!] Cleanup akhir...${reset}"
    [ -f "$ZIPNAME" ] && rm -f "$ZIPNAME"
    [ -f log.txt ] && rm -f log.txt
    [ -f full-build.log ] && rm -f full-build.log
    [ -f out/full_defconfig ] && rm -f out/full_defconfig
}

function build_kernel() {
    export PATH="$COMPILERDIR/bin:$PATH"
    make -j$(nproc --all) O=out ARCH=arm64 ${DEFCONFIG} ${CONFIG}
    if [ $? -ne 0 ]
then
    echo -e "\n"
    echo -e "$red [!] BUILD FAILED \033[0m"
    echo -e "\n"
else
    echo -e "\n"
    echo -e "$green==================================\033[0m"
    echo -e "$green= [!] START BUILD ${DEFCONFIG} {CONFIG}\033[0m"
    echo -e "$green==================================\033[0m"
    echo -e "\n"
fi

# Speed up build process
MAKE="./makeparallel"

# Build Start Here

   make -j$(nproc --all) \
    O=out \
    ARCH=arm64 \
    DTC_PREBUILT=true \
    DTC=$EXTRA_FOLDER/dtc \
    DTC_OVERLAY_TEST_EXT=$EXTRA_FOLDER/ufdt_apply_overlay \
    MKDTIMG=$EXTRA_FOLDER/mkdtimg \
    CC="ccache clang" \
    LD=ld.lld \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1 | tee full-build.log

    grep -Ei "(error|warning)" full-build.log > log.txt

    if grep -q "error:" full-build.log || [ ! -f out/arch/arm64/boot/Image ]; then
        echo -e "${red}[!] Build gagal${reset}"
        send_log
        cleanup_files
        return 1
    fi

    echo -e "${green}[+] Build sukses! Packing ZIP...${reset}"

    [ ! -d AnyKernel3 ] && git clone -q https://github.com/malkist01/AnyKernel3.git -b ginkgo
    cp -f "$kernel" "$dtbo" AnyKernel3/
    [ -f "$dtbo" ] && cp -f "$dtbo" AnyKernel3/
    cd AnyKernel3 || return 1
    zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
    cd .. && rm -rf AnyKernel3

    make O=out ARCH=arm64 savedefconfig
    mv out/ out/full_defconfig

    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))

    echo -e "${green}🕒 Durasi Build : $((DIFF / 60)) menit $((DIFF % 60)) detik${reset}"
    upload_zip
    upload_fullbuild_log
    upload_defconfig
    send_success_message
    cleanup_files
}

function upload_zip() {
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" -F document=@"$ZIPNAME" -F chat_id="$CHAT_ID" > /dev/null
}

function upload_fullbuild_log() {
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" -F document=@"full-build.log" -F caption="Full Build Log - $ZIPNAME" -F chat_id="$CHAT_ID" > /dev/null
}

function upload_defconfig() {
    [ -f out/full_defconfig ] || return
    cp out/full_defconfig trinket-perf_defconfig
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" -F document=@"surya_defconfig" -F caption="Full Defconfig - $ZIPNAME" -F chat_id="$CHAT_ID" > /dev/null
    rm -f trinket-perf_defconfig
}

# ============================
# Eksekusi utama
# ============================
BUILD_START=$(date +"%s")
install_dependencies
clean
clang
send_initial_message
build_kernel
