 /$$    /$$ /$$    /$$ /$$$$$$/$$$$   /$$$$$$  /$$$$$$$ 
|  $$  /$$/|  $$  /$$/| $$_  $$_  $$ |____  $$| $$__  $$
 \  $$/$$/  \  $$/$$/ | $$ \ $$ \ $$  /$$$$$$$| $$  \ $$
  \  $$$/    \  $$$/  | $$ | $$ | $$ /$$__  $$| $$  | $$
   \  $/      \  $/   | $$ | $$ | $$|  $$$$$$$| $$  | $$
    \_/        \_/    |__/ |__/ |__/ \_______/|__/  |__/

A vibecoded minimal Python virtual environment manager for Linux. Create, activate, list and delete venvs from a single shell function.

## Features

- Activate a venv instantly by typing its name: no `source` required
- Create a new venv with a single command
- List all envs with creation date and Python version; optionally show installed package count
- Delete a venv with a confirmation prompt
- Uninstall the tool cleanly, including the `.bashrc` entry

## Requirements

- Bash
- Python 3.x

## Install

```bash
git clone https://github.com/amperclock/vvman.git
cd vvman
bash install.sh            # installs to ~/.vvman (default)
bash install.sh /my/path   # or a custom path
```

Then reload your shell:

```bash
source ~/.bashrc
```

The installer will:
1. Create the install directory (default `~/.vvman`)
2. Copy `vv.sh` into it
3. Append a `source` line to `~/.bashrc`

## Usage

```bash
vv add myenv          # create a new venv named "myenv"
vv myenv              # activate it
vv list               # list all envs
vv list -v            # list with package counts
vv remove myenv       # delete a venv
deactivate            # deactivate the current venv (built-in)
```

Env names are restricted to letters, numbers, `-` and `_`.

## Uninstall

```bash
vv uninstall
```

This will:
1. Back up `~/.bashrc` to `~/.bashrc.before_removing_vvman`
2. Show and confirm the exact source line to remove
3. Delete the install directory and all venvs inside it
