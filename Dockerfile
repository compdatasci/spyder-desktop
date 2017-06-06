# Builds a Docker image for Spyder.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/desktop:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ENV PYENV_ROOT=/usr/local/pyenv \
    PYENV_VERSION=3.6.1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
          git \
          pandoc \
          ttf-dejavu \
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
    rm -rf /var/lib/apt/lists/*

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
          numpy \
          matplotlib \
          sympy \
          scipy \
          pandas \
          nose \
          sphinx \
          autopep8 \
          flake8 \
          pylint \
          flufl.lock \
          ply \
          pytest \
          six \
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
        calico-spell-check && \
    \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    \
    touch $DOCKER_HOME/.log/jupyter.log && \
    \
    echo '@spyder' >> $DOCKER_HOME/.config/lxsession/LXDE/autostart && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
