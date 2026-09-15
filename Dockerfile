FROM osrf/ros:jazzy-desktop AS base

RUN apt update \
    && apt -y upgrade \
    && apt -y --no-install-recommends install \
        cmake make g++ gcc git wget unzip tmux lsb-release gnupg curl software-properties-common

# Display stuff
RUN apt -y install x11-apps libxext-dev libxrender-dev libxtst-dev 

# Install CycloneDDS
RUN apt -y install ros-$ROS_DISTRO-rmw-cyclonedds-cpp
# ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Install PhoXiControl
RUN apt -y install avahi-daemon libqt5gui5 libavahi-client-dev dbus-x11
ENV PHOXI_CONTROL_PATH="/opt/Photoneo/PhoXiControl"
ENV PATH=${PATH}:${PHOXI_CONTROL_PATH}/bin
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${PHOXI_CONTROL_PATH}/API/lib
ENV CPATH=${CPATH}:${PHOXI_CONTROL_PATH}/API/include
RUN --mount=type=bind,source=PhoXiControl,target=/sources /sources/PhotoneoPhoXiControlInstaller-1.17.3-Ubuntu24.04-STABLE.run --accept ${PHOXI_CONTROL_PATH}

# Install aist-phoxi-camera ros package deps
RUN apt -y install nlohmann-json3-dev
RUN --mount=type=bind,source=photoneo_ros2,target=/temp_pkgs bash -c "source /opt/ros/jazzy/setup.bash && apt update && rosdep update --rosdistro=jazzy && rosdep install -yir --from-paths /temp_pkgs"

RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc

WORKDIR /root/ros2_dev
CMD [ "bash" ]


# INTERNAL PhoXiControl
FROM base AS standalone

COPY ./launch_dbus.sh /root/launch_dbus.sh
COPY ./entrypoint.sh /root/entrypoint.sh
RUN echo "if [ -f /tmp/dbus_session_address ]; then source /tmp/dbus_session_address; fi" >> ~/.bashrc

ENTRYPOINT ["/root/entrypoint.sh"]
CMD [ "bash" ]


# EXTERNAL PhoXiControl
FROM base AS host-dbus

ARG UID=1001
ARG USER=ross
RUN useradd --create-home --groups sudo -s /bin/bash --uid $UID --user-group $USER \
    && echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $USER


# Host PhoXi Prod
FROM host-dbus AS host-prod

WORKDIR /home/$USER/ros2_dev/ros2_ws
RUN --mount=type=bind,source=photoneo_ros2,target=src bash -c "source /opt/ros/jazzy/setup.bash && colcon build"
COPY --chmod=755 <<-"EOT" ~/entrypoint.sh
#!/bin/bash
source install/setup.bash
trap 'kill -2 $ROSLAUNCHPID && wait $ROSLAUNCHPID && exit' SIGINT SIGHUP SIGTERM
(ros2 launch aist_phoxi_camera launch.py $@) &
ROSLAUNCHPID=$!
while true; do sleep 1; done
EOT
ENTRYPOINT [ "~/entrypoint.sh" ]
CMD [ "id:=InstalledExamples-basic-example" ]


# DEV ENV
FROM host-dbus AS dev

USER root
RUN apt -y install sudo less bash-completion tmux tree gdb fzf ripgrep xclip python3-neovim
RUN bash -c "bash <(curl -fsSL https://raw.githubusercontent.com/ArdooTala/my-nvim-config/refs/heads/main/neovim_setup.sh)"
ENV TERM=tmux-256color
RUN echo 'DOCKER-DEV' > /etc/hostname

USER $USER
RUN << EOT cat >> ~/.bashrc

if [ -f  ~/.config/bash/.bashrc_custom ]; then
    . ~/.config/bash/.bashrc_custom
fi

EOT

WORKDIR /home/$USER/ros2_dev
CMD [ "tmux" ]
