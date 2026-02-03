# CustomRC

**Breakdown massive rc files like bashrc or zshrc into manageable modules and easily control which modules to be loaded on startup.**

- [Overview](#overview)
- [Features](#features)
- [FAQs](#faqs)
- [Installation](#installation)

## Overview

RC stands for "run command". It is a file that contains commands to be executed. Usually, it contains the commands to be executed when the shell is started.

This project allows you to split your monolithic shell configuration into smaller, organized files based on functionality or operating system.

Reference: [Wiki/RUNCOM](https://en.wikipedia.org/wiki/RUNCOM)

## Features

- **Modular Configuration**: Break down large `.zshrc` or `.bashrc` files into smaller, maintainable modules.
- **Platform Specific Loading**: Automatically load modules based on your OS (Global, Darwin, Linux).
- **Startup Control**: Easily manage which modules are loaded when your shell starts.
- **Performance Optimized**: Modules use lazy loading, caching, and conditional loading for fast shell startup. See [Writing Optimized Modules](docs/optimized-modules.md).

## FAQs

#### Is this safe to use on my machine?
Notice that the rc file in this repository is for personal use. Some modules/tools may not work in your environment or may conflict with your existing setup. You should take a look at the modules in `~/.customrc/Global`, `~/.customrc/Darwin` and `~/.customrc/Linux` before using it to ensure compatibility.

## Installation

Clone the repository:

```bash
git clone --recurse-submodules https://github.com/OnCloud125252/CustomRC.git ~/.customrc
```

Add the configuration to your shell profile (e.g., `~/.zshrc`):

```bash
cat << 'EOF' >> ~/.zshrc
# CustomRC
export CUSTOMRC_PATH="$HOME/.customrc"
source $CUSTOMRC_PATH/customrc.sh
# CustomRC End
EOF
```
