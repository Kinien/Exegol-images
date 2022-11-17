#!/bin/bash

# Starting
# This procedure is supposed to be executed only once at the first startup, using a lockfile check

echo "This log file is the result of the execution of the official and personal customization script"
echo "[$(date +'%d-%m-%Y_%H-%M-%S')] ==== Loading custom setups (/.exegol/load_supported_setups.sh) ===="

# Root my-resources PATH
MY_Root_PATH="/opt/my-resources"
# Setup directory for user customization
MY_Setup_PATH="$MY_Root_PATH/setup"

# Deploying the /opt/my-resources/ folder if not already there
if [ -d "$MY_Root_PATH" ]; then
  # Setup basic structure
  [ -d "$MY_Setup_PATH" ] || (mkdir "$MY_Setup_PATH" && chmod 770 "$MY_Setup_PATH")
  [ -d "$MY_Root_PATH/bin" ] || (mkdir "$MY_Root_PATH/bin" && chmod 770 "$MY_Root_PATH/bin")
else
  echo "Exiting, 'my-resources' is disabled"
  exit 1
fi

# Copying README.md to /opt/my-resources/ (first use)
[ -f "$MY_Setup_PATH/README.md" ] || cp --preserve=mode /.exegol/skel/README.md "$MY_Setup_PATH/README.md"

##### TMUX deployment
if [ -d "$MY_Setup_PATH/tmux" ]; then
  # copy tmux/tmux.conf to ~/.tmux.conf
  [ -f "$MY_Setup_PATH/tmux/tmux.conf" ] && cp "$MY_Setup_PATH/tmux/tmux.conf" ~/.tmux.conf
else
  mkdir "$MY_Setup_PATH/tmux" && chmod 770 "$MY_Setup_PATH/tmux"
fi

##### VIM deployment
if [ -d "$MY_Setup_PATH/vim" ]; then
  # Copy vim/vimrc to ~/.vimrc
  [ -f "$MY_Setup_PATH/vim/vimrc" ] && cp "$MY_Setup_PATH/vim/vimrc" ~/.vimrc
  # Copy every subdir configs to ~/.vim directory
  for path in "$MY_Setup_PATH/vim/autoload" "$MY_Setup_PATH/vim/backup" "$MY_Setup_PATH/vim/colors" "$MY_Setup_PATH/vim/plugged" "$MY_Setup_PATH/vim/bundle"; do
    [ "$(ls -A $path)" ] && mkdir -p ~/.vim && cp -rf $path ~/.vim
  done
else
  # Create supported directories struct
  mkdir -p "$MY_Setup_PATH/vim/autoload" "$MY_Setup_PATH/vim/backup" "$MY_Setup_PATH/vim/colors" "$MY_Setup_PATH/vim/plugged" "$MY_Setup_PATH/vim/bundle"
  chmod 770 -R "$MY_Setup_PATH/vim"
fi

##### Install custom APT packages
if [ -d "$MY_Setup_PATH/apt" ]; then
  # Deploy custom apt repository
  cp "$MY_Setup_PATH/apt/sources.list" /etc/apt/sources.list.d/exegol_user_sources.list
  # Register custom repo's GPG keys
  mkdir /tmp/aptkeys
  grep -vE "^(\s*|#.*)$" <$MY_Setup_PATH/apt/keys.list | while IFS= read -r key_url; do
    wget -nv "$key_url" -O "/tmp/aptkeys/$(echo "$key_url" | md5sum | cut -d ' ' -f1).key"
  done
  if [ "$(ls /tmp/aptkeys/*.key 2>/dev/null)" ]; then
    gpg --no-default-keyring --keyring=/tmp/aptkeys/user_custom.gpg --batch --import /tmp/aptkeys/*.key && \
    gpg --no-default-keyring --keyring=/tmp/aptkeys/user_custom.gpg --batch --output /etc/apt/trusted.gpg.d/user_custom.gpg --export --yes && \
    chmod 644 /etc/apt/trusted.gpg.d/user_custom.gpg
  fi
  rm -r /tmp/aptkeys
  # Update package list from repos
  apt-get update
  # Install every packages listed in the file
  # shellcheck disable=SC2046
  apt-get install -y $(grep -vE "^(\s*|#.*)$" "$MY_Setup_PATH/apt/packages.list" | tr "\n" " ")
else
  # Import file template
  mkdir "$MY_Setup_PATH/apt" && chmod 770 "$MY_Setup_PATH/apt"
  cp --preserve=mode /.exegol/skel/apt/sources.list "$MY_Setup_PATH/apt/sources.list"
  cp --preserve=mode /.exegol/skel/apt/sources.list "$MY_Setup_PATH/apt/keys.list"
  cp --preserve=mode /.exegol/skel/apt/packages.list "$MY_Setup_PATH/apt/packages.list"
fi

##### Install custom PIP3 packages
if [ -d "$MY_Setup_PATH/python3" ]; then
  # Install every pip3 packages listed in the requirements.txt file
  python3 -m pip install -r "$MY_Setup_PATH/python3/requirements.txt"
else
  # Import file template
  mkdir "$MY_Setup_PATH/python3" && chmod 770 "$MY_Setup_PATH/python3"
  cp --preserve=mode /.exegol/skel/python3/requirements.txt "$MY_Setup_PATH/python3/requirements.txt"
fi


# Executing user setup (or create the file)
if [ -f "$MY_Setup_PATH/load_user_setup.sh" ]; then
  echo "[$(date +'%d-%m-%Y_%H-%M-%S')] ==== Loading user setup ($MY_Setup_PATH/load_user_setup.sh) ===="
  $MY_Setup_PATH/load_user_setup.sh
else
  echo "[$(date +'%d-%m-%Y_%H-%M-%S')] ==== User setup loader missing, deploying it ($MY_Setup_PATH/load_user_setup.sh) ===="
  cp /.exegol/skel/load_user_setup.sh "$MY_Setup_PATH/load_user_setup.sh"
  chmod 760 "$MY_Setup_PATH/load_user_setup.sh"
fi

echo "[$(date +'%d-%m-%Y_%H-%M-%S')] ==== End of custom setups loading ===="
exit 0
