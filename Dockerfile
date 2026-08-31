FROM osrf/ros:jazzy-desktop

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
COPY ./PhotoneoPhoXiControlInstaller-1.16.1-Ubuntu24-STABLE.run /root/PhotoNeoControl/
ENV PHOXI_CONTROL_PATH="/opt/Photoneo/PhoXiControl"
ENV PATH=${PATH}:${PHOXI_CONTROL_PATH}/bin
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${PHOXI_CONTROL_PATH}/API/lib
ENV CPATH=${CPATH}:${PHOXI_CONTROL_PATH}/API/include
RUN /root/PhotoNeoControl/PhotoneoPhoXiControlInstaller-1.16.1-Ubuntu24-STABLE.run --accept ${PHOXI_CONTROL_PATH}

# Install aist-phoxi-camera ros package deps
RUN apt -y install nlohmann-json3-dev
RUN --mount=type=bind,source=photoneo_ros2,target=/temp_pkgs bash -c "source /opt/ros/jazzy/setup.bash && apt update && rosdep update --rosdistro=jazzy && rosdep install -yir --from-paths /temp_pkgs"

# DEV ENV
# Install dev packages
RUN apt -y install \
    sudo less bash-completion tmux tree gdb fzf ripgrep xclip python3-neovim

# NeoVim
RUN bash -c "bash <(curl -fsSL https://raw.githubusercontent.com/ArdooTala/my-nvim-config/refs/heads/main/neovim_setup.sh)"

# tmux
ENV TERM=tmux-256color

# Configs
RUN echo 'DOCKER-DEV' > /etc/hostname

RUN << EOT cat >> /root/.bashrc

if [ -f  ~/.config/bash/.bashrc_custom ]; then
    . ~/.config/bash/.bashrc_custom
fi

EOT

RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc

COPY ./launch_dbus.sh /root/launch_dbus.sh
COPY ./entrypoint.sh /root/entrypoint.sh
RUN echo "if [ -f /tmp/dbus_session_address ]; then source /tmp/dbus_session_address; fi" >> ~/.bashrc
ENTRYPOINT ["/root/entrypoint.sh"]
# COPY ./dbus-config/setup_dbus.sh /root/dbus-config/
# COPY ./setup_dbus.sh /root/
# RUN chmod +x /root/dbus/setup_dbus.sh
# RUN cat /root/dbus-config/setup_dbus.sh >> ~/.bashrc

WORKDIR /root/ros2_dev

CMD [ "tmux" ]
