# Builds a Docker image for development environment
# with Ubuntu, LXDE, and Jupyter Notebook.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/ubuntu:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Set up user so that we do not run as root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
          build-essential \
          git \
          bash-completion \
          python3-pip \
          python3-dev \
          python3-flufl.lock \
          python3-ply \
          python3-pytest \
          python3-six \
          python3-urllib3 \          
          python3-numpy \
          python3-scipy \
          python3-sphinx \
          python3-matplotlib \
          build-essential \
          bash-completion \
          pandoc \
          ttf-dejavu \
          bsdtar \
          gdb \
          ddd \
          meld \
          emacs24 \
          spyder3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install jupyter
RUN pip3 install -U pip setuptools && \
    pip3 install -U \
         autopep8 \
         sympy \
         ipython \
         jupyter \
         ipywidgets && \
    jupyter nbextension install --py --system \
         widgetsnbextension && \
    jupyter nbextension enable --py --system \
         widgetsnbextension && \
    pip3 install -U \
        jupyter_latex_envs==1.3.8.4 && \
    jupyter nbextension install --py --system \
        latex_envs && \
    jupyter nbextension enable --py --system \
        latex_envs && \
    jupyter nbextension install --system \
        https://bitbucket.org/ipre/calico/downloads/calico-spell-check-1.0.zip && \
    jupyter nbextension install --system \
        https://bitbucket.org/ipre/calico/downloads/calico-document-tools-1.0.zip && \
    jupyter nbextension install --system \
        https://bitbucket.org/ipre/calico/downloads/calico-cell-tools-1.0.zip && \
    jupyter nbextension enable --system \
        calico-spell-check

########################################################
# Customization for user
########################################################
ENV UE_USER=unifem

RUN usermod -l $UE_USER -d /home/$UE_USER -m $DOCKER_USER && \
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
