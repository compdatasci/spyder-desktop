# Builds a Docker image for development environment
# with Ubuntu, LXDE, and user numgeom.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/ubuntu:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

########################################################
# Customization for user and location
########################################################

ENV NG_USER=numgeom

# Set up user so that we do not run as root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
          python3-requests \
          build-essential \
          bash-completion && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mv /home/$DOCKER_USER /home/$NG_USER && \
    useradd -m -s /bin/bash -G sudo,docker_env $NG_USER && \
    echo "$NG_USER:docker" | chpasswd && \
    echo "$NG_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    sed -i "s/$DOCKER_USER/$NG_USER/" /home/$NG_USER/.config/pcmanfm/LXDE/desktop-items-0.conf && \
    chown -R $NG_USER:$NG_USER /home/$NG_USER

ENV DOCKER_USER=$NG_USER \
    DOCKER_GROUP=$NG_USER \
    DOCKER_HOME=/home/$NG_USER \
    HOME=/home/$NG_USER

WORKDIR $DOCKER_HOME

USER root
ENTRYPOINT ["/sbin/my_init","--quiet","--","/sbin/setuser","numgeom","/bin/bash","-l","-c"]
CMD ["/bin/bash","-l","-i"]
