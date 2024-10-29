<div align="center">
<h1>CustomRC</h1>
Breakdown the massive rc files like bashrc or zshrc into manageable modules and easily control which modules to be loaded on startup.
<br>
</div>

---

### What is a rc file?
RC stands for "run command". It is a file that contains commands to be executed. Usually, it contains the commands to be executed when the shell is started.

Ref: [Wiki/RUNCOM](https://en.wikipedia.org/wiki/RUNCOM)

# Installation

```bash
git clone https://github.com/OnCloud125252/CustomRC.git ~/.customrc
```

```bash
cat << 'EOF' >> ~/.zshrc
# CustomRC
export CUSTOMRC_PATH="$HOME/.customrc"
source $CUSTOMRC_PATH/customrc.sh
# CustomRC End
EOF
```