FROM ubuntu:18.04

MAINTAINER runarsf <root@runarsf.dev>

ENV DOCKER_USER deploy

RUN apt-get update \
 && apt-get install -y --no-install-recommends sudo \
 && adduser --disabled-password --gecos '' "$DOCKER_USER" \
 && adduser "$DOCKER_USER" sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
 && touch /home/$DOCKER_USER/.sudo_as_admin_successful \
 && rm -rf /var/lib/apt/lists/*

USER "$DOCKER_USER"
WORKDIR "/home/$DOCKER_USER"

#RUN yes | sudo unminimize \
RUN sudo apt-get update \
 && sudo apt-get install -y \
    git \
    curl \
 && sudo rm -rf /var/lib/apt/lists/*

RUN mkdir /home/$DOCKER_USER/git \
 && git clone https://github.com/runarsf/dotfiles /home/$DOCKER_USER/git/dotfiles \
 && cd /home/$DOCKER_USER/git/dotfiles \
 && git submodule update --recursive --init \
 && cd /home/$DOCKER_USER/git/dotfiles/deploy \
 && ./deploy.sh --dotfiles ../ --packages ../deploy-ubuntu.json