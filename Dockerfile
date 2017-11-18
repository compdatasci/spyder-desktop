# Builds a Docker image for Spyder and Jupyter Notebook
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM compdatasci/petsc-desktop:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ADD image/home $DOCKER_HOME

# Install system packages, Scipy, and jupyter-notebook
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
          git \
          python3-dev \
          python3-pip \
          pandoc \
          libnss3 \
          libdpkg-perl \
          ttf-dejavu \
          swig3.0 \
          \
          python3-spyder spyder3 \
          python3-mpi4py \
          python3-petsc4py \
          python3-slepc4py \
          \
          python3-notebook jupyter-notebook \
          python3-flake8 \
          python3-progressbar \
          python3-widgetsnbextension && \
    apt-get clean && \
    apt-get autoremove && \
    \
    pip3 install -U \
         autopep8 \
         PyDrive \
         jupyter_latex_envs && \
    jupyter-nbextension install --py --system \
        latex_envs && \
    jupyter-nbextension enable --py --system \
        latex_envs && \
    jupyter-nbextension install --system \
        https://bitbucket.org/ipre/calico/downloads/calico-spell-check-1.0.zip && \
    jupyter-nbextension install --system \
        https://bitbucket.org/ipre/calico/downloads/calico-document-tools-1.0.zip && \
    jupyter-nbextension install --system \
        https://bitbucket.org/ipre/calico/downloads/calico-cell-tools-1.0.zip && \
    jupyter-nbextension enable --system \
        calico-spell-check && \
    \
    curl -L https://github.com/hbin/top-programming-fonts/raw/master/install.sh | bash && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    \
    touch $DOCKER_HOME/.log/jupyter.log && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
