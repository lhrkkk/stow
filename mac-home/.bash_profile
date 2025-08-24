# bash bootstrap to use ~/.config/bash/bash_profile
if [ -f "$HOME/.config/bash/bash_profile" ]; then
  . "$HOME/.config/bash/bash_profile"
fi
