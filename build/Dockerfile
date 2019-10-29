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

RUN sudo apt-get update \
 && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
    git \
    curl \
 && sudo rm -rf /var/lib/apt/lists/*

COPY --chown=deploy build /home/$DOCKER_USER/dotfiles
COPY --chown=deploy . /home/$DOCKER_USER/dotfiles/deploy
WORKDIR /home/$DOCKER_USER/dotfiles/deploy
RUN sudo /home/$DOCKER_USER/dotfiles/deploy/deploy.sh --dotfiles ../ --packages ../deploy.json full

#RUN mkdir -p /home/$DOCKER_USER/git \
  #&& git clone https://github.com/runarsf/dotfiles /home/$DOCKER_USER/git/dotfiles \
  #&& cd /home/$DOCKER_USER/git/dotfiles \
  #&& git submodule update --init --recursive \
  #&& /home/$DOCKER_USER/git/dotfiles/deploy/deploy.sh --dotfiles . --packages deploy-ubuntu.json full
