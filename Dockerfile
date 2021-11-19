# Base Image For Ainize Workspace ( https://github.com/ainize-team/ainize-workspace-base-images )
FROM byeongal/ubuntu20.04-cuda11.3.1-python3.8.10-dev

USER root
## Basic Env
ENV \
    SHELL="/bin/bash" \
    HOME="/root"  \
    USER_GID=0
WORKDIR $HOME

# Install package from requirements.txt
COPY requirements.txt ./requirements.txt
RUN pip install -r ./requirements.txt && rm requirements.txt

# Install Apex
RUN git clone https://github.com/NVIDIA/apex
RUN cd apex && \
    python setup.py install && \
    pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./

# Conda 
ENV WORKSPACE_HOME="/workspace"
WORKDIR $WORKSPACE_HOME

COPY start.sh /scripts/start.sh
RUN ["chmod", "+x", "/scripts/start.sh"]
ENTRYPOINT "/scripts/start.sh"