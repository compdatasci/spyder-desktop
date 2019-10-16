# Builds a Docker image for Spyder and Jupyter Notebook with petsc4py and slepc4py
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM compdatasci/petsc-desktop:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ADD image/home $DOCKER_HOME

# Environment variables
ENV PETSC4PY_VERSION=3.7.0
ENV SLEPC4PY_VERSION=3.7.0

# Install system packages, Scipy, PyDrive, and jupyter-notebook
# Also installs jupyter extensions for latex environments and spellchecker
# https://stackoverflow.com/questions/39324039/highlight-typos-in-the-jupyter-notebook-markdown
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
          pkg-config \
          python3-dev \
          vim-python-jedi \
          doxygen \
          meld \
          pandoc \
          libnss3 \
          libdpkg-perl \
          ttf-dejavu \
          \
          swig3.0 \
          qt5dxcb-plugin \
          python3-mpi4py \
          python3-petsc4py="${PETSC4PY_VERSION}*" \
          python3-slepc4py="${SLEPC4PY_VERSION}*" && \
    apt-get clean && \
    apt-get autoremove && \
    curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    pip3 install -U \
          setuptools \
          matplotlib \
          sympy==1.1.1 \
          scipy \
          pandas \
          nose \
          sphinx \
          breathe \
          cython \
          \
          autopep8 \
          flake8 \
          pylint \
          flufl.lock \
          ply \
          pytest \
          six \
          PyQt5 \
          spyder \
          \
          urllib3 \
          requests \
          pylint \
          progressbar2 \
          PyDrive \
          \
          ipython \
          jupyter \
          jupyter_latex_envs \
          jupyter_contrib_nbextensions \
          ipywidgets && \
    jupyter nbextension install --py --system \
         widgetsnbextension && \
    jupyter nbextension enable --py --system \
         widgetsnbextension && \
    jupyter-nbextension install --py --system \
        latex_envs && \
    jupyter-nbextension enable --py --system \
        latex_envs && \
    jupyter contrib nbextension install --system && \
    jupyter nbextension enable spellchecker/main && \
    \
    curl -L https://github.com/hbin/top-programming-fonts/raw/master/install.sh | bash && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    \
    touch $DOCKER_HOME/.log/jupyter.log && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
