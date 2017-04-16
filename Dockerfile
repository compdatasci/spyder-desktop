# Builds a Docker image for development environment
# with Ubuntu, LXDE, and Jupyter Notebook.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/ubuntu:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ENV PYENV_ROOT=/usr/local/pyenv \
    PYENV_VERSION=3.6.1

# Set up user so that we do not run as root
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    add-apt-repository ppa:eugenesan/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
          git \
          build-essential \
          bash-completion \
          pandoc \
          ttf-dejavu \
          git \
          bsdtar \
          \
          gdb \
          ddd \
          meld \
          smartgit \
          emacs24 \
          \
          libbz2-dev \
          libssl-dev \
          libreadline-dev \
          libsqlite3-dev \
          tk-dev \
          libpng-dev \
          libfreetype6-dev \
          \
          libnss3 \
          libxslt1.1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PATH=$PYENV_ROOT/versions/$PYENV_VERSION/bin:$PATH

# Install jupyter
RUN git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT && \
    PYTHON_CONFIGURE_OPTS="--enable-shared" \
    $PYENV_ROOT/bin/pyenv install $PYENV_VERSION && \
    pip3 install -U\
        pip \
        setuptools \
        dev && \
    pip3 install -U \
        flufl.lock \
        numpy \
        ply \
        pytest \
        scipy \
        sympy \
        matplotlib \
        six \
        autopep8 \
        PyQt5 \
        spyder \
        urllib3 \
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
