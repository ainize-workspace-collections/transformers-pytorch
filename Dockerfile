FROM nvidia/cuda:11.6.1-cudnn8-devel-ubuntu20.04

USER root

ENV \
    NB_USER=root \
    SHELL=/bin/bash \
    HOME="/${NB_USER}" \
    USER_GID=0 \
    DISPLAY=:1 \
    TERM=xterm \
    WORKSPACE_HOME=/workspace

# Copy a script that we will use to correct permissions after running certain commands
COPY scripts/clean-layer.sh  /usr/bin/clean-layer.sh
COPY scripts/fix-permissions.sh  /usr/bin/fix-permissions.sh
RUN \
    chmod a+rwx /usr/bin/clean-layer.sh && \
    chmod a+rwx /usr/bin/fix-permissions.sh 

# Install Ubuntu Package
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    apt-utils \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    ccache \
    cmake \
    curl \
    espeak-ng \
    ffmpeg \
    fonts-liberation \
    g++ \
    git \
    libaio-dev \
    libjpeg-dev \
    libjson-c-dev \
    libpng-dev \
    libsndfile1-dev \
    libssl-dev \
    libtool \
    libwebsockets-dev \
    locales \
    make \
    pandoc \
    pkg-config \
    run-one \
    sudo \
    tesseract-ocr \
    tini \
    unzip \
    vim \
    vim-common \
    wget && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    clean-layer.sh

ENV \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

# Layer cleanup script
COPY scripts/clean-layer.sh  /usr/bin/clean-layer.sh
COPY scripts/fix-permissions.sh  /usr/bin/fix-permissions.sh

# Make clean-layer and fix-permissions executable
RUN chmod a+rwx /usr/bin/clean-layer.sh && chmod a+rwx /usr/bin/fix-permissions.sh

RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
    # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
    echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# Install Python
# Configure environment
ARG PYTHON_VERSION=3.8
ENV CONDA_DIR=/opt/conda 
ENV PATH="${CONDA_DIR}/bin:${PATH}"

COPY scripts/initial-condarc "${CONDA_DIR}/.condarc"
WORKDIR /tmp

RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
    # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
    arch="64"; \
    fi && \
    wget -qO /tmp/micromamba.tar.bz2 \
    "https://micromamba.snakepit.net/api/micromamba/linux-${arch}/latest" && \
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2 && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    # Install the packages
    ./micromamba install \
    --root-prefix="${CONDA_DIR}" \
    --prefix="${CONDA_DIR}" \
    --yes \
    "${PYTHON_SPECIFIER}" \
    'mamba' && \
    rm micromamba && \
    # Pin major.minor version of python
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    mamba clean --all -f -y && \
    fix-permissions.sh "${CONDA_DIR}"

# Install Jupyter
RUN mamba install --quiet --yes \
    notebook \
    jupyterhub \
    jupyterlab \
    voila \
    jupyter_contrib_nbextensions \
    ipywidgets \
    autopep8 \
    yapf && \
    mamba clean --all -f -y && \
    npm cache clean --force && \
    jupyter contrib nbextension install --sys-prefix && \
    fix-permissions.sh $CONDA_ROOT && \
    clean-layer.sh

# Notebook Branding
COPY branding/logo.png /tmp/logo.png
COPY branding/favicon.ico /tmp/favicon.ico
RUN /bin/bash -c 'cp /tmp/logo.png $(python -c "import sys; print(sys.path[-1])")/notebook/static/base/images/logo.png'
RUN /bin/bash -c 'cp /tmp/favicon.ico $(python -c "import sys; print(sys.path[-1])")/notebook/static/base/images/favicon.ico'
RUN /bin/bash -c 'cp /tmp/favicon.ico $(python -c "import sys; print(sys.path[-1])")/notebook/static/favicon.ico'

## Install Visual Studio Code Server
RUN curl -fsSL https://code-server.dev/install.sh | sh && \
    clean-layer.sh

## Install ttyd. (Not recommended to edit)
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends libwebsockets-dev libjson-c-dev libssl-dev

RUN \
    wget https://github.com/tsl0922/ttyd/archive/refs/tags/1.6.2.zip \
    && unzip 1.6.2.zip \
    && cd ttyd-1.6.2 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make \
    && make install \
    && clean-layer.sh

# /workspace
# Make folders
RUN \
    if [ -e $WORKSPACE_HOME ] ; then \
    chmod a+rwx $WORKSPACE_HOME; \
    else \
    mkdir $WORKSPACE_HOME && chmod a+rwx $WORKSPACE_HOME; \
    fi
ENV HOME=$WORKSPACE_HOME
WORKDIR $WORKSPACE_HOME

# Install package from environment.yml ( conda )
COPY environment.yml ./environment.yml
RUN mamba env update --name root --file environment.yml && \
    rm environment.yml && \
    clean-layer.sh

### Start Ainize Worksapce ###
COPY start.sh /scripts/start.sh
RUN ["chmod", "+x", "/scripts/start.sh"]
CMD "/scripts/start.sh"