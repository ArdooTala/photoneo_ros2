FROM osrf/ros:jazzy-desktop-full

RUN apt update \
    && apt -y upgrade \
    && apt -y --no-install-recommends install \
        cmake make g++ gcc git wget unzip tmux lsb-release gnupg curl software-properties-common

# Install NeoVim
RUN add-apt-repository -y ppa:neovim-ppa/unstable \
    && apt update \
    && apt -y install ripgrep xclip neovim

ADD https://raw.githubusercontent.com/ArdooTala/kickstart.nvim/refs/heads/master/init.lua /root/.config/nvim/

RUN apt -y install avahi-daemon libqt5gui5 libavahi-client-dev

COPY ./PhotoneoPhoXiControlInstaller-1.15.0-Ubuntu24-STABLE.run /root/PhotoNeoControl/

ENV PHOXI_CONTROL_PATH="/opt/Photoneo/PhoXiControl"

RUN /root/PhotoNeoControl/PhotoneoPhoXiControlInstaller-1.15.0-Ubuntu24-STABLE.run --accept ${PHOXI_CONTROL_PATH}

RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc

WORKDIR /ros2_ws

COPY ./setup_dbus.sh /root/

RUN chmod +x /root/setup_dbus.sh

#ENTRYPOINT ["/bin/sh", "-c", "/root/setup_dbus.sh"]

RUN cat /root/setup_dbus.sh >> ~/.bashrc

CMD [ "bash" ]
