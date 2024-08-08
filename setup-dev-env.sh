#!/bin/bash

# Neovim and development environment setup script for Debian-based Linux distributions
# This script installs the latest versions of Neovim and Node.js from source/official methods

set -e

FORCE=false
LOG_FILE="$HOME/.setup-dev-env.log"

# カラー出力用の関数
print_color() {
    local color=$1
    local message=$2
    echo -e "\033[${color}m${message}\033[0m"
}

# 関数: バックアップを作成
backup_file() {
    if [ -f "$1" ];then
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

# スクリプトが既に実行されたかどうかをチェック
check_already_run() {
    if [ -f "$LOG_FILE" ] && ! $FORCE; then
        print_color "32" "This script has already been executed on this server. Use --force to run it again."
        exit 0
    fi
}

# sudoチェック
if [ "$EUID" -eq 0 ]; then
    print_color "31" "Please run this script as a normal user, not as root or with sudo."
    exit 1
fi

# forceオプションのチェック
for arg in "$@"; do
    case $arg in
        --force)
        FORCE=true
        shift
        ;;
    esac
done

# 実行済みチェック
check_already_run

# ユーザー確認
print_color "33" "This script will install Neovim, Node.js, tmux, and related tools. Do you want to continue? (y/n)"
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
install_package build-essential

# クリップボードプロバイダーのインストール
print_color "36" "Installing clipboard provider..."
install_package xclip || install_package xsel

# Neovim の最新バージョンをインストール
install_neovim() {
    print_color "36" "Installing the latest version of Neovim..."
    
    # 依存関係のインストール
    sudo apt-get install -y ninja-build gettext cmake unzip curl || { print_color "31" "Failed to install dependencies"; exit 1; }
    
    # ソースコードのダウンロードとビルド
    git clone https://github.com/neovim/neovim || { print_color "31" "Failed to clone Neovim repository"; exit 1; }
    cd neovim
    git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=/usr/local || { print_color "31" "Error: Neovim build failed."; exit 1; }
    sudo make install || { print_color "31" "Error: Neovim install failed."; exit 1; }
    cd ..
    rm -rf neovim
    
    # Neovimのインストールチェック
    if ! command -v nvim &> /dev/null; then
        print_color "31" "Error: Neovim installation failed."
        exit 1
    fi
    
    # Neovimのバージョンチェック
    NVIM_VERSION=$(nvim --version | head -n1 | cut -d ' ' -f2)
    if [ "$(printf '%s\n' "0.8.0" "$NVIM_VERSION" | sort -V | head -n1)" = "0.8.0" ]; then
        print_color "32" "Neovim version $NVIM_VERSION installed successfully."
    else
        print_color "31" "Error: Installed Neovim version ($NVIM_VERSION) is lower than required (0.8.0)."
        exit 1
    fi
}

# Neovim のインストールチェックと条件付きインストール
check_and_install_neovim() {
    if command -v nvim &> /dev/null; then
        NVIM_VERSION=$(nvim --version | head -n1 | cut -d ' ' -f2)
        if [ "$(printf '%s\n' "0.8.0" "$NVIM_VERSION" | sort -V | head -n1)" = "0.8.0" ];then
            print_color "32" "Neovim version $NVIM_VERSION is already installed and meets the minimum requirement."
            return
        else
            print_color "33" "Installed Neovim version ($NVIM_VERSION) is lower than required (0.8.0)."
            print_color "36" "Do you want to upgrade Neovim? (y/n)"
            read -r upgrade_nvim
            if [[ ! $upgrade_nvim =~ ^[Yy]$ ]]; then
                print_color "33" "Skipping Neovim upgrade. Some features may not work correctly."
                return
            fi
        fi
    fi

    install_neovim
}

# Node.js の最新 LTS バージョンをインストール
install_nodejs() {
    print_color "36" "Installing the latest LTS version of Node.js..."
    
    # nvm（Node Version Manager）のインストール
    if ! command -v nvm &> /dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash || { print_color "31" "Failed to install nvm"; exit 1; }
        # nvm を現在のシェルで使用可能にする
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        echo 'export NVM_DIR="$HOME/.nvm"' >> "$(get_shell_config_file)"
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$(get_shell_config_file)"
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$(get_shell_config_file)"
    else
        print_color "32" "nvm is already installed."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    # 最新の LTS バージョンの Node.js をインストール
    nvm install --lts || { print_color "31" "Failed to install Node.js LTS"; exit 1; }
    nvm use --lts
    
    # Node.js のインストールチェック
    if ! command -v node &> /dev/null; then
        print_color "31" "Error: Node.js installation failed."
        exit 1
    fi
    
    # Node.js のバージョンチェック
    NODE_VERSION=$(node --version)
    print_color "32" "Node.js version $NODE_VERSION installed successfully."
}

# Node.js のインストールチェックと条件付きインストール
check_and_install_nodejs() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_color "32" "Node.js version $NODE_VERSION is already installed."
        print_color "36" "Do you want to install the latest LTS version of Node.js? (y/n)"
        read -r install_node
        if [[ ! $install_node =~ ^[Yy]$ ]]; then
            print_color "33" "Skipping Node.js installation."
            return
        fi
    fi

    install_nodejs
}

# 既存の設定ファイルの処理
handle_existing_config() {
    local config_file="$1"
    local config_name="$2"

    if [ -f "$config_file" ]; then
        print_color "33" "Existing $config_name configuration detected."
        print_color "36" "Do you want to overwrite it? (y/n)"
        read -r overwrite_config
        if [[ ! $overwrite_config =~ ^[Yy]$ ]]; then
            print_color "33" "Keeping existing $config_name configuration."
            return 1
        fi
    fi
    return 0
}

# シェルの設定ファイルを選択
get_shell_config_file() {
    case "$SHELL" in
        */zsh)
            echo "$HOME/.zshrc"
            ;;
        */bash)
            echo "$HOME/.bashrc"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Neovim のインストール
check_and_install_neovim

# Node.js のインストール
check_and_install_nodejs

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

# Check for existing Vim plugins
if [ -d "${HOME_DIR}/.vim/plugged/coc.nvim" ] || [ -d "${HOME_DIR}/.vim/plugged/copilot.vim" ]; then
    print_color "33" "Existing Vim plugins (coc.nvim and/or copilot.vim) detected."
    print_color "33" "These may interfere with Neovim setup."
    print_color "36" "Do you want to remove these Vim plugins? (y/n)"
    read -r remove_response
    if [[ $remove_response =~ ^[Yy]$ ]]; then
        print_color "36" "Removing Vim plugins..."
        sudo -u $REAL_USER rm -rf "${HOME_DIR}/.vim/plugged/coc.nvim" "${HOME_DIR}/.vim/plugged/copilot.vim"
        print_color "32" "Vim plugins removed."
    else
        print_color "33" "Vim plugins will be kept. Note that this might cause conflicts with Neovim setup."
    fi
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

# init.vim の作成 (Neovim専用の設定)
if handle_existing_config "${HOME_DIR}/.config/nvim/init.vim" "Neovim"; then
    sudo -u $REAL_USER bash -c "cat << EOF > ${HOME_DIR}/.config/nvim/init.vim
call plug#begin(stdpath('data') . '/plugged')
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': 'yarn install --frozen-lockfile'}
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

\" Disable compatibility with vi
set nocompatible

\" General settings
set nobackup
set autoindent
set ul=0
set showmode
set report=1
set showmatch
set suffixes=.log,.aux,.dvi,.o,.bak,.swp

\" Tab and indentation settings
set tabstop=4
set noexpandtab
set smartindent
set smarttab
set shiftwidth=4
set expandtab
set smarttab

\" Interface settings
set wildmenu
set nowrapscan
set winheight=5
set history=50
set laststatus=1
set ruler
set incsearch
set modeline
set nobomb

\" Key mappings
map <C-g> :buffers<CR>
map <C-k> :bdelete<CR>
map <C-x>o <C-w><C-w><C-w>_

\" Insert mode mappings
inoremap <C-h> <BS>

\" UTF-8 settings
set ambiwidth=double
set fileencoding=utf-8
set encoding=utf-8
set fileencodings=utf-8,euc-jp,japan,shift-jis,iso-2022-jp,cp932,utf-16,ucs-2-internal,ucs-2
set termencoding=utf-8

\" Additional key mappings
map Q gq

\" クリップボードとの統合
set clipboard+=unnamedplus

\" 視覚モードでの選択領域をクリップボードにコピーするキーマッピング
vnoremap <C-c> \"+y

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
    print_color "32" "Created Neovim-specific init.vim"
fi

# coc-settings.json の作成
if handle_existing_config "${HOME_DIR}/.config/nvim/coc-settings.json" "coc.nvim"; then
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
fi

# プラグインのインストール
if [ -f "${HOME_DIR}/.config/nvim/init.vim" ]; then
    print_color "36" "Do you want to install/update Neovim plugins? (y/n)"
    read -r install_plugins
    if [[ $install_plugins =~ ^[Yy]$ ]]; then
        print_color "36" "Installing Neovim plugins..."
        sudo -u $REAL_USER nvim +PlugInstall +qall || { print_color "31" "Failed to install Neovim plugins"; exit 1; }
        print_color "32" "Installed Neovim plugins"
    else
        print_color "33" "Skipping Neovim plugin installation/update."
    fi
fi

# Coc 拡張機能のインストール
if command -v node &> /dev/null && [ -f "${HOME_DIR}/.config/nvim/coc-settings.json" ]; then
    print_color "36" "Do you want to install/update Coc extensions? (y/n)"
    read -r install_coc
    if [[ $install_coc =~ ^[Yy]$ ]]; then
        print_color "36" "Installing Coc extensions..."
        sudo -u $REAL_USER nvim +CocInstall coc-json coc-tsserver coc-pyright coc-html coc-css +qall || { print_color "31" "Failed to install Coc extensions"; exit 1; }
        print_color "32" "Installed Coc extensions"
    else
        print_color "33" "Skipping Coc extensions installation/update."
    fi
fi

# tmux の設定
if handle_existing_config "${HOME_DIR}/.tmux.conf" "tmux"; then
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

set-option -g history-limit 10000
set-window-option -g mode-keys vi
EOF"
    print_color "32" "Created tmux.conf"
fi

# 所有権の確認と修正
sudo chown -R $REAL_USER:$REAL_USER "${HOME_DIR}/.config/nvim" "${HOME_DIR}/.local/share/nvim" "${HOME_DIR}/.tmux.conf"

# スクリプトの実行履歴を保存
echo "Script executed on: $(date)" > "$LOG_FILE"

print_color "32" "開発環境のセットアップが完了しました。"
print_color "33" "既存の設定ファイルがある場合、.bak 拡張子を付けてバックアップしました。"
print_color "36" "Neovim を起動し、:checkhealth コマンドを実行して、追加の依存関係をチェックしてください。"

# GitHub Copilot 認証プロセスの案内
print_color "36" "To use GitHub Copilot, you need to complete the authentication process."
print_color "36" "1. Open Neovim and run ':Copilot auth' to initiate the authentication process."
print_color "36" "2. Follow the instructions in the browser to authorize GitHub Copilot."

print_color "36" "Node.js を使用するには、新しいターミナルセッションを開始するか、'source ~/.bashrc'（または適切なシェル設定ファイル）を実行してください。"

