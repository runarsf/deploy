# deploy
[![Build Status](https://travis-ci.org/runarsf/deploy.svg?branch=master)](https://travis-ci.org/runarsf/deploy)

A bash script made for deploying and managing [dotfiles](https://github.com/runarsf/dotfiles) from a folder or git repo.<br />
Deploy is under active development and currently capable of deploying all (dot)files from a folder (see [Folder structure](https://github.com/runarsf/deploy#folder-structure)), and packages from a json file (see [Package file](https://github.com/runarsf/deploy#package-file)).

### Installation

```bash
# Simple ver.
cd /path/to/dotfiles
git clone https://github.com/runarsf/deploy
cd deploy
./deploy.sh --dotfiles ../ --packages ../packages.json

# Using submodules, easier updates
cd /path/to/dotfiles
git submodule add https://github.com/runarsf/deploy
cd deploy
./deploy.sh --dotfiles ../ --packages ../packages.json
# Updating submodule
git submodule update --init --recursive
```

### Usage
```bash
./deploy.sh --help
```

### Folder structure
`dotfiles/` represents the root of the dotfiles repository.<br />
`->` represents a symbolic link.<br />
`!>` represents ignored entries.<br />
No suffix represents no action.

```bash
dotfiles/
├── ./ !>
├── ../ !>
├── .git/ !>
├── .gitignore !>
├── README.md !>
├── deploy*.json !>
├── .travis.yml !>
├── .sharenix.json !>
├── deploy/ !> submodule
├── file -> /home/user/file
├── folder/
│   ├── folder/
│   └── file -> /home/user/folder/file
└── root/
    ├── folder/
    │   ├── folder/
    │   └── file -> /folder/file
    └── file -> /file
```

### Package file
```json
{
  "update": "apt update",
  "prefix": "apt install -y",
  "suffix": "--no-install-recommends",
  "packages": [
    {"package": "zsh"},
    {"package": "git"},
    {"package": "curl"},
    {"package": "firefox"},
    {
      "package": "thefuck",
      "prefix": "DEBIAN_FRONTEND=noninteractive apt-get install -y",
      "suffix": "--install-recommends"
    }
  ]
}
```

> **deploy** © [runarsf](https://github.com/runarsf) · Author and maintainer.<br>
> Released under the [OSL-3.0](https://opensource.org/licenses/OSL-3.0) [License](https://github.com/runarsf/deploy/blob/master/LICENSE).
