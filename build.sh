#!/bin/bash

set -x
# ./build.sh -t DESKTOP -p "vins_estimator" -b RelWithDebInfo
# ./build.sh -t RK3588 -p "depthai_examples" -b RelWithDebInfo
# ./build.sh -t DESKTOP -p "device_manager" -b RelWithDebInfo

# export WORKSPACE="$(dirname "$(realpath "$BASH_SOURCE")")"
# export WORKSPACE="$(realpath "$BASH_SOURCE")"
export WORKSPACE="$(dirname "$0")"

TARGET_PLATFORM=""
BUILD_TYPE=Release
PACKAGE_UP_TO=""
TOOLCHAIN_FILE=""
INSTALL_METHOD="--merge-install"
CMAKE_FORCE_CONFIG=""

CMAKE_ARGS='-DBUILD_TESTING=OFF
    -DDEPTHAI_ENABLE_CURL=OFF 
    -DBUILD_SHARED_LIBS=ON
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON'

# if number of arguments is less than 2, add -h to list of args
if [ $# -lt 2 ]; then
    set -- "$@" -h
fi

usage() {
    echo "Usage: build.bash [-h] [-b <build_type>] -t <target_platform> -p <package> [-c] "
    echo "Options:"
    echo "  -h              : show this help text"
    echo "  -b <build_type> : build type to use (default is RelWithDebInfo for platform=PC and Release for others)"
    echo "  -t <target>     : platform to build for (DESKTOP/RK3588)"
    echo "  -p              : Build select package"
    echo "  -c              : Do a clean build"
    echo "  -f              : Force cmake configure"
    exit 0
}

# Parse the build options.
while getopts ":hb:t:p:m:f:d:l:c" opt; do
  case $opt in
    h) usage;;
    b) BUILD_TYPE="$OPTARG";;
    t) TARGET_PLATFORM="$OPTARG";;
    p) PACKAGE_UP_TO="--packages-up-to $OPTARG";;
    d) PRODUCT="$OPTARG";;
    c) CLEAN_BUILD="true";;
    f) CMAKE_FORCE_CONFIG="--cmake-force-configure";;
    l) INSTALL_METHOD='--symlink-install';;
    ?) usage;;
  esac
done

if [[ "${TARGET_PLATFORM}" = "" ]]; then
    echo "Please specify the platform to build for"
    exit 1
fi

CMAKE_ARGS+=" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON "

if [[ "${BUILD_TYPE}" = "" ]];then
    if [[ "${TARGET_PLATFORM}" = "PC" ]]; then
        BUILD_TYPE=RelWithDebInfo
    else
        BUILD_TYPE=Release
    fi
fi
CMAKE_ARGS+=" -DCMAKE_BUILD_TYPE=${BUILD_TYPE}"

if [[ ${CLEAN_BUILD} = "true" ]]; then
    rm -rf ${WORKSPACE}/output/${TARGET_PLATFORM}
fi

if [[ "${TARGET_PLATFORM}" = "RK3588" ]]; then
    # in rk3588_dev container
    TOOLCHAIN_FILE=/opt/cmake/rk3588.toolchain.cmake
    CMAKE_ARGS+=" -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}"
fi

export TARGET=${TARGET_PLATFORM}

INSTALL_DIR=${WORKSPACE}/output/${TARGET_PLATFORM}/install
BUILD_DIR=${WORKSPACE}/output/${TARGET_PLATFORM}/build
LOG_DIR=${WORKSPACE}/output/${TARGET_PLATFORM}/log

CMAKE_ARGS+=" -Ddepthai_DIR=/depthai_ws/src/depthai-core/build_arm64/vcpkg_installed/arm64-linux/lib/cmake/depthai"
CMAKE_ARGS+=" -Dlibnop_DIR=/depthai_ws/src/depthai-core/build_arm64/vcpkg_installed/arm64-linux/lib/cmake/libnop"
CMAKE_ARGS+=" -DXLink_DIR=/depthai_ws/src/depthai-core/build_arm64/vcpkg_installed/arm64-linux/lib/cmake/XLink"


echo "TARGET: ${TARGET_PLATFORM}"
echo "TOOLCHAIN_FILE: ${TOOLCHAIN_FILE}"
echo "PACKAGE_UP_TO: ${PACKAGE_UP_TO}"

MAKEFLAGS="-j8" colcon --log-base ${LOG_DIR} build \
       --build-base ${BUILD_DIR} \
       --install-base  ${INSTALL_DIR} \
       --parallel-workers 8 \
       ${INSTALL_METHOD} \
       ${PACKAGE_UP_TO} \
       ${CMAKE_FORCE_CONFIG} \
       --cmake-args \
       --no-warn-unused-cli \
       ${CMAKE_ARGS}


# cmake .. -DCMAKE_TOOLCHAIN_FILE=/opt/cmake/rk3588.toolchain.cmake -DCMAKE_INSTALL_PREFIX=/opt/ros/jazzy_aarch64


# cmake -B build_arm64 -S . \
#       -DVCPKG_TARGET_TRIPLET=arm64-linux \
#       -DCMAKE_SYSROOT=/opt/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu/ \
#       -DCMAKE_C_COMPILER=aarch64-none-linux-gnu-gcc \
#       -DCMAKE_CXX_COMPILER=aarch64-none-linux-gnu-g++

# cmake -B build_arm64 -S . \
#       -DCMAKE_BUILD_TYPE=Release \
#       -DCMAKE_TOOLCHAIN_FILE=/depthai_ws/src/depthai-core/cmake/vcpkg.cmake \
#       -DVCPKG_TARGET_TRIPLET=arm64-linux \
#       -DDEPTHAI_VCPKG_INTERNAL_ONLY=OFF \
#       -DDEPTHAI_ENABLE_APRIL_TAG=OFF \
#       -DDEPTHAI_ENABLE_PROTOBUF=OFF \
#       -DDEPTHAI_ENABLE_MP4V2=OFF \
#       -DDEPTHAI_BASALT_SUPPORT=OFF \
#       -DDEPTHAI_NEW_FIND_PYTHON=OFF \
#       -DDEPTHAI_JSON_EXTERNAL=ON


# cmake -B build -S . \
#     -DVCPKG_TARGET_TRIPLET=arm64-linux \
#     -DDEPTHAI_VCPKG_INTERNAL_ONLY=OFF \
#     -DDEPTHAI_ENABLE_APRIL_TAG=OFF \
#     -DDEPTHAI_ENABLE_PROTOBUF=OFF \
#     -DDEPTHAI_ENABLE_MP4V2=OFF \
#     -DDEPTHAI_BASALT_SUPPORT=OFF \
#     -DDEPTHAI_NEW_FIND_PYTHON=OFF \
#     -DDEPTHAI_JSON_EXTERNAL=OFF 