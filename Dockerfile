# Builds a Docker image for development environment with
# Ubuntu, LXDE, Atom, and Jupyter Notebook.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM numgeom/desktop-base:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
          python3-pip \
          python3-dev \
          pandoc \
          ttf-dejavu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install jupyter
RUN pip3 install -U pip setuptools && \
    pip3 install -U \
          numpy \
          matplotlib \
          sympy \
          scipy \
          pandas \
          nose \
          sphinx \
          autopep8 \
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
    rm -rf /tmp/* /var/tmp/*

########################################################
# Customization for user
########################################################
ENV OLD_USER=$DOCKER_USER \
    UE_USER=unifem
ENV DOCKER_USER=$UE_USER \
    DOCKER_GROUP=$UE_USER \
    DOCKER_HOME=/home/$UE_USER \
    HOME=/home/$UE_USER

RUN usermod -l $DOCKER_USER -d $DOCKER_HOME -m $OLD_USER && \
    groupmod -n $DOCKER_USER $OLD_USER && \
    echo "$DOCKER_USER:docker" | chpasswd && \
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "export OMP_NUM_THREADS=\$(nproc)" >> $DOCKER_HOME/.profile && \
    apm install \
        language-cpp14 \
        language-matlab \
        language-fortran \
        language-docker \
        autocomplete-python \
        autocomplete-fortran \
        git-plus \
        merge-conflicts \
        split-diff \
        gcc-make-run \
        intentions \
        busy-signal \
        linter-ui-default \
        linter \
        linter-gcc \
        linter-gfortran \
        linter-pylint \
        linter-matlab \
        dbg \
        output-panel \
        dbg-gdb \
        python-autopep8 \
        clang-format && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME

USER root
ENTRYPOINT ["/sbin/my_init","--quiet","--","/sbin/setuser","unifem","/bin/bash","-l","-c"]
CMD ["/bin/bash","-l","-i"]
