# Builds a Docker image for development environment
# with Ubuntu, LXDE, and user unifem.
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

ENV UE_USER=unifem

# Set up user so that we do not run as root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
          python3-requests \
          build-essential \
          bash-completion \
          bsdtar && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN usermod -l $UE_USER $DOCKER_USER && \
    groupmod -n $UE_USER $DOCKER_USER && \
    echo "$UE_USER:docker" | chpasswd && \
    echo "$UE_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    sed -i "s/$DOCKER_USER/$UE_USER/" /home/$UE_USER/.config/pcmanfm/LXDE/desktop-items-0.conf && \
    chown -R $UE_USER:$UE_USER /home/$UE_USER

ENV DOCKER_USER=$UE_USER \
    DOCKER_GROUP=$UE_USER \
    DOCKER_HOME=/home/$UE_USER \
    HOME=/home/$UE_USER

WORKDIR $DOCKER_HOME

USER root
ENTRYPOINT ["/sbin/my_init","--quiet","--","/sbin/setuser","unifem","/bin/bash","-l","-c"]
CMD ["/bin/bash","-l","-i"]
