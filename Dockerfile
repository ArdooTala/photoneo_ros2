FROM osrf/ros:jazzy-desktop-full

RUN apt update \
    && apt -y upgrade \
    && apt -y --no-install-recommends install \
        cmake make g++ gcc git wget unzip tmux lsb-release gnupg curl software-properties-common

# Install NeoVim
RUN add-apt-repository -y ppa:neovim-ppa/unstable \
    && apt update \
    && apt -y install ripgrep xclip neovim

ENV TERM='xterm-256color'

ADD https://github.com/ArdooTala/my-nvim-config.git /root/.config/nvim/

# Install PhoXiControl
RUN apt -y install avahi-daemon libqt5gui5 libavahi-client-dev

COPY ./PhotoneoPhoXiControlInstaller-1.16.1-Ubuntu24-STABLE.run /root/PhotoNeoControl/

ENV PHOXI_CONTROL_PATH="/opt/Photoneo/PhoXiControl"
ENV PATH=${PATH}:${PHOXI_CONTROL_PATH}/bin
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${PHOXI_CONTROL_PATH}/API/lib
ENV CPATH=${CPATH}:${PHOXI_CONTROL_PATH}/API/include

RUN /root/PhotoNeoControl/PhotoneoPhoXiControlInstaller-1.16.1-Ubuntu24-STABLE.run --accept ${PHOXI_CONTROL_PATH}

# Install aist-phoxi-camera ros package deps
RUN apt -y install nlohmann-json3-dev

RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
WORKDIR /root/ros2_ws

RUN apt update && apt -y install dbus-x11
COPY ./entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
RUN echo "if [ -f /tmp/dbus_session_address ]; then source /tmp/dbus_session_address; fi" >> ~/.bashrc
ENTRYPOINT ["/root/entrypoint.sh"]
# COPY ./dbus-config/setup_dbus.sh /root/dbus-config/
# COPY ./setup_dbus.sh /root/
# RUN chmod +x /root/dbus/setup_dbus.sh
# RUN cat /root/dbus-config/setup_dbus.sh >> ~/.bashrc

CMD [ "bash" ]
