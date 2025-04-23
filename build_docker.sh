
colcon build \
    --merge-install \
    --install-base depthai \
    --packages-up-to depthai_ros_driver vins_estimator \
    --cmake-force-configure \
    --cmake-args \
    --no-warn-unused-cli \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${RK3588_TOOLCHAIN_FILE} \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DBUILD_TESTING=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DDEPTHAI_ENABLE_CURL=OFF