# deploy
[![Build Status](https://travis-ci.org/runarsf/deploy.svg?branch=master)](https://travis-ci.org/runarsf/deploy)

A bash script made for deploying and managing [dotfiles](https://github.com/runarsf/dotfiles) from a folder or git repo.<br />
Deploy is under active development and currently capable of deploying all (dot)files from a folder (see [Folder structure](https://github.com/runarsf/deploy#folder-structure)), and packages from a json file (see [Package file](https://github.com/runarsf/deploy#package-file)).

### Installation

```bash
# Simple ver.
git clone https://github.com/runarsf/deploy
cd deploy
./deploy.sh --dotfiles ~/dotfiles --packages ~/dotfiles/instructions.sh

# Using submodules, easier updates
cd dotfiles
git submodule add https://github.com/runarsf/deploy
cd deploy
./deploy.sh --dotfiles ../ --packages ../instructions.sh
# Updating submodule
git submodule update --init --recursive
```

### Usage
```bash
./deploy.sh --help
```

### Folder structure
`dotfiles/` represents the root of the dotfiles repository.<br />
`{from} -> {to}` represents a symbolic link.<br />
`{entry} !> {reason}` represents ignored entries.<br />
No suffix represents no action (recursive deployment).

```bash
dotfiles/
├── ./                  !> working directory
├── ../                 !> parent directory
├── .git/               !> git repository data
├── .gitignore          !> ignored git entries
├── README*             !> information file
├── *deploy*            !> used to deploy packages
├── instructions.sh     !> used to deploy packages
├── .travis.yml         !> travis-ci build file
├── .sharenix.json      !> contains private token
├── deploy/             !> submodule
├── Dockerfile          !> docker build information
├── docker-compose.y*ml !> docker-compose build information
├── file                -> ~/file
├── folder/
│   ├── folder/
│   │   └── folder/
│   └── file            -> ~/folder/file
└── root/
    ├── folder/
    │   ├── folder/
    │   └── file        -> /folder/file
    └── file            -> /file
```

> **deploy** © [runarsf](https://github.com/runarsf) · Author and maintainer.<br />
> Released under the [OSL-3.0](https://opensource.org/licenses/OSL-3.0) [License](https://github.com/runarsf/deploy/blob/master/LICENSE).
