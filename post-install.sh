#!/bin/bash
set -e

ZSH_CUSTOM=$HOME/.oh-my-zsh/custom

#
# Functions
#

install() {
  sudo dnf install -y $1
}

#
# System Settings
#

# Update system
sudo dnf upgrade -y --refresh
sudo dnf install "dnf-command(config-manager)" -y

# DNF Speedup
echo 'fastestmirror=1' | sudo tee -a /etc/dnf/dnf.conf
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf

# RPM Fusion
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf groupupdate core -y

# Set GNOME night light
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000

#
# Utilities
#

sudo dnf install -y bat fzf bleachbit flatpak gnome-tweaks gnome-extensions-app zsh fira-code-fonts golang kitty wl-clipboard
flatpak install -y flatseal
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Pokemon color scripts
git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git --depth=1
cd pokemon-colorscripts
sudo ./install.sh

# OhMyZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

#
# Work Programs
#

# GitHub CLI
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
install gh

# Docker
sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo usermod -aG docker $USER

# Kubectl
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
install kubectl

# Krew
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

# Kubectl/Krew plugins
$HOME/.krew/bin/kubectl-krew install ctx
$HOME/.krew/bin/kubectl-krew install ns

# Lens IDE
sudo dnf config-manager --add-repo https://downloads.k8slens.dev/rpm/lens.repo
install lens

# Helm
install helm

# nvm, NodeJS, npm and Yarn
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
source ~/.bashrc
nvm install --lts
npm install -g yarn

# Deno
curl -fsSL https://deno.land/x/install/install.sh | sh

# aws-cli and awsp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
yarn global add awsp

#
# Applications
#

install discord

sudo flatpak install -y flathub com.spotify.Client

sudo flatpak install -y flathub com.opera.Opera

sudo flatpak install -y flathub com.bitwarden.desktop

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat <<EOF | sudo tee /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo dnf update -y
install code

#
# ZSH and OhMyZSH configuration
#

# Spaceship theme
sudo git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
sudo ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

# ZSH plugins
git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions --depth=1
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions --depth=1
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting --depth=1

# Copying dotfiles
cp ./zsh/.zshrc $HOME/.zshrc

# Setting default shell
# Please type: /bin/zsh
sudo lchsh $USER

### Now you should logout
