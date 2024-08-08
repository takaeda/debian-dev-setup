#!/bin/bash

# Neovim and development environment setup script for Debian-based Linux distributions
# This script is designed to work on systems that use the apt package manager.
# Tested on Ubuntu and Debian, but may work on other Debian derivatives.

set -e

# カラー出力用の関数
print_color() {
    local color=$1
    local message=$2
    echo -e "\033[${color}m${message}\033[0m"
}

# 関数: バックアップを作成
backup_file() {
    if [ -f "$1" ]; then
        timestamp=$(date +"%Y%m%d%H%M%S")
        print_color "33" "Backing up $1 to ${1}.${timestamp}.bak"
        mv "$1" "${1}.${timestamp}.bak"
    fi
}

# 関数: パッケージのインストール
install_package() {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        print_color "36" "Installing $1..."
        sudo apt install -y "$1" || { print_color "31" "Failed to install $1"; exit 1; }
    else
        print_color "32" "$1 is already installed."
    fi
}

# sudoチェック
if [ "$EUID" -eq 0 ]; then
    print_color "31" "Please run this script as a normal user, not as root or with sudo."
    exit 1
fi

# ユーザー確認
print_color "33" "This script will install Neovim, tmux, and related tools. Do you want to continue? (y/n)"
read -r response
if [[ ! $response =~ ^[Yy]$ ]]; then
    print_color "31" "Installation aborted."
    exit 1
fi

# 必要なパッケージのインストール
print_color "36" "Updating package list..."
sudo apt update
install_package curl
install_package git
install_package tmux
install_package neovim
install_package build-essential

# Node.js のインストール
if ! command -v node &> /dev/null; then
    print_color "36" "Node.js is not installed. Do you want to install Node.js 16.x? (y/n)"
    read -r node_response
    if [[ $node_response =~ ^[Yy]$ ]]; then
        print_color "36" "Installing Node.js 16.x and npm..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        install_package nodejs
    else
        print_color "33" "Skipping Node.js installation. Some features may not work without Node.js."
    fi
else
    print_color "32" "Node.js is already installed."
fi

# Neovimのインストールチェック
if ! command -v nvim &> /dev/null; then
    print_color "31" "Error: Neovim installation failed."
    exit 1
fi

# tmuxのインストールチェック
if ! command -v tmux &> /dev/null; then
    print_color "31" "Error: tmux installation failed."
    exit 1
fi

# Get the real user (even if script is run with sudo)
REAL_USER=${SUDO_USER:-$USER}
HOME_DIR=$(eval echo ~$REAL_USER)
if [ -z "$HOME_DIR" ] || [ ! -d "$HOME_DIR" ]; then
    HOME_DIR=$(getent passwd $REAL_USER | cut -d: -f6)
fi
if [ -z "$HOME_DIR" ] || [ ! -d "$HOME_DIR" ]; then
    print_color "31" "Error: Unable to determine home directory for $REAL_USER"
    exit 1
fi

# 既存の設定ファイルのバックアップ
sudo -u $REAL_USER bash -c "$(declare -f backup_file print_color); backup_file \"${HOME_DIR}/.config/nvim/init.vim\""
sudo -u $REAL_USER bash -c "$(declare -f backup_file print_color); backup_file \"${HOME_DIR}/.config/nvim/coc-settings.json\""
sudo -u $REAL_USER bash -c "$(declare -f backup_file print_color); backup_file \"${HOME_DIR}/.tmux.conf\""

# Vim-plug のインストール
sudo -u $REAL_USER sh -c "curl -fLo \"${HOME_DIR}/.local/share/nvim/site/autoload/plug.vim\" --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
print_color "32" "Installed vim-plug"

# Neovim の設定ディレクトリを作成
sudo -u $REAL_USER mkdir -p "${HOME_DIR}/.config/nvim"

# init.vim の作成
sudo -u $REAL_USER bash -c "cat << EOF > ${HOME_DIR}/.config/nvim/init.vim
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'sheerun/vim-polyglot'
Plug 'preservim/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm install' }
Plug 'github/copilot.vim'
Plug 'preservim/nerdtree'
call plug#end()

\" 基本設定
set number
set relativenumber
set expandtab
set tabstop=4
set shiftwidth=4
set smartindent
set clipboard+=unnamedplus
syntax on
filetype plugin indent on

\" キーマッピング
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-p> :Files<CR>

\" Coc.nvim の設定
inoremap <silent><expr> <TAB>
      \ pumvisible() ? \"\<C-n>\" :
      \ <SID>check_back_space() ? \"\<TAB>\" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? \"\<C-p>\" : \"\<C-h>\"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\\s'
endfunction
EOF"
print_color "32" "Created init.vim"

# coc-settings.json の作成
sudo -u $REAL_USER bash -c "cat << EOF > ${HOME_DIR}/.config/nvim/coc-settings.json
{
    \"suggest.noselect\": false,
    \"coc.preferences.formatOnSaveFiletypes\": [\"*\"],
    \"languageserver\": {
        \"coc-pyright\": {
            \"command\": \"pyright-langserver\",
            \"args\": [\"--stdio\"],
            \"filetypes\": [\"python\"],
            \"settings\": {
                \"python\": {
                    \"analysis\": {
                        \"typeCheckingMode\": \"off\"
                    }
                }
            }
        }
    }
}
EOF"
print_color "32" "Created coc-settings.json"

# プラグインのインストール
print_color "36" "Installing Neovim plugins..."
sudo -u $REAL_USER nvim +PlugInstall +qall || { print_color "31" "Failed to install Neovim plugins"; exit 1; }
print_color "32" "Installed Neovim plugins"

# Coc 拡張機能のインストール
if command -v node &> /dev/null; then
    print_color "36" "Installing Coc extensions..."
    sudo -u $REAL_USER nvim +CocInstall coc-json coc-tsserver coc-pyright coc-html coc-css +qall || { print_color "31" "Failed to install Coc extensions"; exit 1; }
    print_color "32" "Installed Coc extensions"
else
    print_color "33" "Skipping Coc extensions installation due to missing Node.js."
fi

# tmux の設定
sudo -u $REAL_USER bash -c "cat << EOF > ${HOME_DIR}/.tmux.conf
# マウス操作を有効にする
set -g mouse on

# ウィンドウのインデックスを1から始める
set -g base-index 1

# ペインのインデックスを1から始める
setw -g pane-base-index 1

# 256色端末を使用する
set -g default-terminal \"screen-256color\"

# ステータスバーの色を設定する
set -g status-fg white
set -g status-bg black
EOF"
print_color "32" "Created tmux.conf"

# 所有権の確認と修正
sudo chown -R $REAL_USER:$REAL_USER "${HOME_DIR}/.config/nvim" "${HOME_DIR}/.local/share/nvim" "${HOME_DIR}/.tmux.conf"

print_color "32" "開発環境のセットアップが完了しました。"
print_color "33" "既存の設定ファイルがある場合、.bak 拡張子を付けてバックアップしました。"
print_color "36" "Neovim を起動し、:checkhealth コマンドを実行して、追加の依存関係をチェックしてください。"
