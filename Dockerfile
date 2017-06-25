# Builds a Docker image for Spyder and Jupyter Notebook for Scipy
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/desktop:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install system packages, Scipy, and jupyter-notebook
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
          git \
          python3-dev \
          pandoc \
          ttf-dejavu && \
    apt-get clean && \
    \
    curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    pip3 install -U \
         setuptools \
         numpy \
         matplotlib \
         sympy \
         scipy \
         pandas \
         nose \
         sphinx \
         flufl.lock \
         ply \
         pytest \
         six \
         \
         urllib3 \
         requests \
         progressbar2 \
         PyDrive \
         \
         autopep8 \
         flake8 \
         PyQt5 \
         spyder \
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
