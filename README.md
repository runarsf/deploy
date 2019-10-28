# deploy
[![Build Status](https://travis-ci.org/runarsf/deploy.svg?branch=master)](https://travis-ci.org/runarsf/deploy)

A bash script made for deploying and managing [dotfiles](https://github.com/runarsf/dotfiles) from a folder or git repo.

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
git submodule update --recursive --init
```

### Usage
```bash
./deploy.sh --help
./deploy.sh --dotfiles /path/to/dotfiles --packages /path/to/packages.json
```

### Folder structure
`dotfiles/` represents the root of the dotfiles repository.

```bash
dotfiles/
├── ./ -> ignored
├── ../ -> ignored
├── .git/ -> ignored
├── .gitignore -> ignored
├── README.md -> ignored
├── deploy*.json -> ignored
├── .travis.yml -> ignored
├── .sharenix.json -> ignored
├── deploy/ -> submodule, ignored
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

### `deploy.json`
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
      "suffix": "--install-recommends"
    }
  ]
}
```

### TODO
  - Add support for all listed packages (except zsh-theme, handled by zsh plugin manager); https://github.com/runarsf/dotfiles/blob/e34b75ec7d447cf948a7e42d488908a432f55553/packages.csv

> **deploy** © [runarsf](https://github.com/runarsf) · Author and maintainer.<br>
> Released under the [OSL-3.0](https://opensource.org/licenses/OSL-3.0) [License](https://github.com/runarsf/deploy/blob/master/LICENSE).
