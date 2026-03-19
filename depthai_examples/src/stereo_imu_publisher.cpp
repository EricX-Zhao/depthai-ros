#include <cstdint>
#include <cstdio>
#include <depthai/common/CameraBoardSocket.hpp>
#include <depthai/pipeline/node/StereoDepth.hpp>
#include <depthai/rtabmap/RTABMapSLAM.hpp>
#include <rclcpp/executors.hpp>
#include <rclcpp/logging.hpp>
#include <rclcpp/rate.hpp>

#include "depthai/device/Device.hpp"
#include "depthai/pipeline/Pipeline.hpp"
#include "depthai/pipeline/node/Camera.hpp"
#include "depthai/pipeline/node/IMU.hpp"
#include "depthai_bridge/BridgePublisher.hpp"
#include "depthai_bridge/ImuConverter.hpp"
#include "depthai_bridge/TFPublisher.hpp"
#include "depthai_bridge/depthaiUtility.hpp"
#include "depthai_bridge/ImageConverter.hpp"
#include "rclcpp/node.hpp"

std::vector<std::string> usbStrings = {"UNKNOWN", "LOW", "FULL", "HIGH", "SUPER", "SUPER_PLUS"};

int main(int argc, char** argv) {
    std::string tfPrefix = "oak";
    rclcpp::init(argc, argv);
    auto node = rclcpp::Node::make_shared(tfPrefix);

    RCLCPP_INFO(node->get_logger(), "No ip/ID specified, connecting to the next available device.");
    auto info = dai::Device::getAnyAvailableDevice();

    int32_t usb_speed = node->declare_parameter<int32_t>("usb_speed", 2);
    node->get_parameter<int32_t>("usb_speed", usb_speed);
    RCLCPP_INFO(node->get_logger(), "usb_speed : %d\n", usb_speed);

    auto device = std::make_shared<dai::Device>(std::get<1>(info), dai::UsbSpeed(usb_speed + 1));

    RCLCPP_INFO(node->get_logger(), "Driver with ID: %s and Name: %s connected!", device->getDeviceId().c_str(), device->getDeviceInfo().name.c_str());
    auto protocol = device->getDeviceInfo().getXLinkDeviceDesc().protocol;

    if(protocol != XLinkProtocol_t::X_LINK_TCP_IP) {
        auto speed = usbStrings[static_cast<int32_t>(device->getUsbSpeed())];
        RCLCPP_INFO(node->get_logger(), "USB SPEED: %s", speed.c_str());
    } else {
        RCLCPP_INFO(node->get_logger(),
                    "PoE device detected. Consider enabling low bandwidth for specific image topics (see "
                    "Readme->DepthAI ROS Driver->Specific device configurations).");
    }

    auto platform = device->getPlatform();
    auto boardID = device->readCalibration2().getEepromData().boardName;
    RCLCPP_DEBUG(node->get_logger(), "Board ID: %s", boardID.c_str());
    auto deviceName = device->getDeviceName();
    RCLCPP_INFO(node->get_logger(), "Device type: %s", deviceName.c_str());
    for(auto& sensor : device->getCameraSensorNames()) {
        RCLCPP_DEBUG(node->get_logger(), "Socket %d - %s", static_cast<int>(sensor.first), sensor.second.c_str());
    }

    dai::Pipeline pipeline(device);

    auto sockets = device->getConnectedCameras();
    for (const auto& sock : sockets) {
        RCLCPP_INFO(node->get_logger(), "Cam sock : %d", (int)sock);
    }

    int32_t width = node->declare_parameter<int32_t>("width", 640);
    int32_t height = node->declare_parameter<int32_t>("height", 480);
    int32_t fps = node->declare_parameter<int32_t>("fps", 20);
    int32_t imu_freq = node->declare_parameter<int32_t>("imu_freq", 200);

    node->get_parameter<int32_t>("width", width);
    node->get_parameter<int32_t>("height", height);
    node->get_parameter<int32_t>("fps", fps);
    node->get_parameter<int32_t>("imu_freq", imu_freq);

    RCLCPP_INFO(node->get_logger(), "Width : %d\n", width);
    RCLCPP_INFO(node->get_logger(), "Height : %d\n", height);
    RCLCPP_INFO(node->get_logger(), "fps : %d\n", fps);
    RCLCPP_INFO(node->get_logger(), "imu_freq : %d\n", imu_freq);

    auto left = pipeline.create<dai::node::Camera>()->build(dai::CameraBoardSocket::CAM_B, std::nullopt, fps);
    auto right = pipeline.create<dai::node::Camera>()->build(dai::CameraBoardSocket::CAM_C, std::nullopt, fps);
    auto imu = pipeline.create<dai::node::IMU>();

    imu->enableIMUSensor(dai::IMUSensor::ACCELEROMETER_RAW, imu_freq);
    imu->enableIMUSensor(dai::IMUSensor::GYROSCOPE_RAW, imu_freq);
    imu->setBatchReportThreshold(3);
    imu->setMaxBatchReports(10);
    auto imu_queue = imu->out.createOutputQueue(10, false);
    auto left_queue = left->requestOutput(std::make_pair(width, height), dai::ImgFrame::Type::GRAY8)->createOutputQueue(5, false);
    auto right_queue = right->requestOutput(std::make_pair(width, height), dai::ImgFrame::Type::GRAY8)->createOutputQueue(5, false);

    pipeline.start();

    // Create a bridge publisher for IMU
    depthai_bridge::ImuSyncMethod imuMode = depthai_bridge::ImuSyncMethod::COPY;
    auto imuConv = std::make_shared<depthai_bridge::ImuConverter>(depthai_bridge::getFrameName(tfPrefix, "imu_frame"), imuMode);
    imuConv->setUpdateRosBaseTimeOnToRosMsg(true);
    auto imuPub = std::make_unique<depthai_bridge::BridgePublisher<sensor_msgs::msg::Imu, dai::IMUData>>(
        imu_queue,
        node,
        "imu/data",
        [imuConv](std::shared_ptr<dai::IMUData> msg, std::deque<sensor_msgs::msg::Imu>& rosMsgs) { imuConv->toRosMsg(msg, rosMsgs); },
        20);

    imuPub->addPublisherCallback();

    // Create a bridge publisher for left images
    auto left_conv = std::make_shared<depthai_bridge::ImageConverter>(
        depthai_bridge::getOpticalFrameName(tfPrefix, depthai_bridge::getSocketName(dai::CameraBoardSocket::CAM_B, device->getDeviceName())), false);
    left_conv->setUpdateRosBaseTimeOnToRosMsg(true);
    auto calibrationHandler = device->readCalibration();
    auto left_cam_info = left_conv->calibrationToCameraInfo(calibrationHandler, dai::CameraBoardSocket::CAM_B, width, height);
    auto left_pub = std::make_unique<depthai_bridge::BridgePublisher<sensor_msgs::msg::Image, dai::ImgFrame>>(
        left_queue,
        node,
        "left/image_raw",
        [left_conv](std::shared_ptr<dai::ImgFrame> msg, std::deque<sensor_msgs::msg::Image>& rosMsgs) { left_conv->toRosMsg(msg, rosMsgs); },
        5,
        left_cam_info,
        "left");
    left_pub->addPublisherCallback();
    
    // Create a bridge publisher for right images
    auto right_conv = std::make_shared<depthai_bridge::ImageConverter>(
        depthai_bridge::getOpticalFrameName(tfPrefix, depthai_bridge::getSocketName(dai::CameraBoardSocket::CAM_C, device->getDeviceName())), false);
    right_conv->setUpdateRosBaseTimeOnToRosMsg(true);

    auto right_cam_info = right_conv->calibrationToCameraInfo(calibrationHandler, dai::CameraBoardSocket::CAM_C, width, height);
    auto right_pub = std::make_unique<depthai_bridge::BridgePublisher<sensor_msgs::msg::Image, dai::ImgFrame>>(
        right_queue,
        node,
        "right/image_raw",
        [right_conv](std::shared_ptr<dai::ImgFrame> msg, std::deque<sensor_msgs::msg::Image>& rosMsgs) { right_conv->toRosMsg(msg, rosMsgs); },
        5,
        right_cam_info,
        "right");
    right_pub->addPublisherCallback();
    
    rclcpp::on_shutdown([&]() { pipeline.stop(); });
    
    rclcpp::Rate r(20.0);
    while(rclcpp::ok() && pipeline.isRunning()) {
        rclcpp::spin_some(node);
        r.sleep();
    }

    return 0;
}
