# base
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND noninteractive

# set the github runner version
ARG RUNNER_VERSION="2.286.0"

# update the base packages
# RUN apt-get update -y && apt-get upgrade -y
RUN apt-get update -y
# add a non-sudo user
RUN useradd -m medium
#RUN mkdir /home/docker

# install python and the packages the your code depends on along with jq so we can parse JSON
# add additional packages as necessary
# RUN apt-get install -y curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev \
#    --no-install-suggests --no-install-recommends
RUN apt-get install -y --no-install-suggests --no-install-recommends \
    build-essential \
    git \
    curl \
    ca-certificates \
    jq \
    gnupg \
    lsb-release

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update -y
RUN apt-get install -y docker-ce docker-ce-cli containerd.io

RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# since the config and run script for actions are not allowed to be run by root,
# set the user to "docker" so all subsequent commands are run as the docker user
RUN usermod -aG docker medium
USER medium

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/medium && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

USER root
# change ownership to non-sudo user
#RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh
# install some additional dependencies
RUN /home/medium/actions-runner/bin/installdependencies.sh

# copy over the start.sh script
COPY start.sh start.sh

# make the script executable
RUN chmod a+x start.sh

USER medium
# add whatever packages your repository needs (so they don't have to be redownloaded over and over again)


# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
