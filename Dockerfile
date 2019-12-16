FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
ARG DOCKER_USER
ENV DOCKER_USER $DOCKER_USER
ARG DOTFILES_REPO
ENV DOTFILES_REPO $DOTFILES_REPO

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
 && sudo apt-get install -y git curl \
 && sudo rm -rf /var/lib/apt/lists/*

#COPY --chown=deploy build /home/$DOCKER_USER/dotfiles
#COPY --chown=deploy . /home/$DOCKER_USER/dotfiles/deploy
#WORKDIR /home/$DOCKER_USER/dotfiles/deploy
#RUN sudo /home/$DOCKER_USER/dotfiles/deploy/deploy.sh --dotfiles ../ --packages ../deploy.json full

RUN git clone $DOTFILES_REPO /home/$DOCKER_USER/dotfiles

COPY . /home/$DOCKER_USER/deploy
