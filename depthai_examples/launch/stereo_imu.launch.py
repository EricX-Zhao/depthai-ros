import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription, launch_description_sources  # noqa: E402
from launch.actions import GroupAction  # noqa: E402
from launch_ros.actions import Node  # noqa: E402
from launch.actions import IncludeLaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch.conditions import IfCondition, LaunchConfigurationEquals, LaunchConfigurationNotEquals


def generate_launch_description():
    
    vis         = LaunchConfiguration('vis', default = False)

    declare_enableRviz_cmd = DeclareLaunchArgument(
        'vis',
        default_value='false',
        description='When True create a RVIZ window.')

    oak_node = Node(
        package='depthai_examples',
        namespace='',
        executable='stereo_imu_publisher',
        name='stereo_imu_publisher',
        parameters=[
            {'width': 640},
            {'height': 480},
            {'fps': 15},
            {'imu_freq': 150},
            {'usb_speed': 2},
        ],
        output='both',
        respawn=True
    )

    vis_node = Node(
        package='rviz2',
        namespace='',
        executable='rviz2',
        name='rviz2',
        condition=IfCondition(vis)
    )

    ld = LaunchDescription()

    ld.add_action(declare_enableRviz_cmd)
    ld.add_action(oak_node)

    ld.add_action(vis_node)

    return ld
