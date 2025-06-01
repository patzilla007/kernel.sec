#!/bin/bash
# OS Version: Ubuntu 24.04

# Set default installation path
DEFAULT_PATH="$HOME/Desktop"
# DEFAULT_PATH="/mnt/hgfs/kernel.sec/fuzzing"

# Get installation path at the start
read -p "Please enter syzkaller kernel fuzzing pro path [default: $DEFAULT_PATH]: " SYZKALLER_PATH
if [ -z "$SYZKALLER_PATH" ]; then
    SYZKALLER_PATH="$DEFAULT_PATH"
else
    # Convert relative path to absolute path if necessary
    case "$SYZKALLER_PATH" in
        /*) ;; # Already absolute path
        *) SYZKALLER_PATH="$PWD/$SYZKALLER_PATH" ;; # Convert to absolute path
    esac
fi

# Create the directory if it doesn't exist
mkdir -p "$SYZKALLER_PATH"
echo "Will use installation path: $SYZKALLER_PATH"
pause

pause() {
    echo -e "\n\033[1;33m[!] Press Enter to continue...\033[0m"
    read
}


# format print function
print_step() {
    echo -e "\n\033[1;34m[+] $1\033[0m"
}

# Check if directory exists and handle
check_and_handle_directory() {
    local target_dir="$1"
    if [ -d "$target_dir" ]; then
        read -p "Directory $target_dir already exists, do you want to download again? (Y/N): " choice
        case "$choice" in 
            [yY]|[yY][eE][sS])
                print_step "Deleting old directory..."
                rm -rf "$target_dir"
                return 0
                ;;
            *)
                print_step "Skipping download, using existing directory..."
                return 1
                ;;
        esac
    fi
    return 0
}

# Restart terminal function
restart_terminal() {
    print_step "Restarting terminal..."
    # Wait 2 seconds for user to see the message
    sleep 2
    # Close current terminal and open new terminal
    gnome-terminal -- bash -c "cd $SYZKALLER_PATH; exec bash" || \
    xterm -e "cd $SYZKALLER_PATH; exec bash" || \
    konsole -e "cd $SYZKALLER_PATH; exec bash" || \
    echo "Unable to automatically restart terminal, please manually open a new terminal and execute: cd $SYZKALLER_PATH"
    exit 0
}

# Function to install system dependencies
install_dependencies() {
    print_step "Installing system dependencies..."
    sudo apt install git curl make gcc g++ python3 python3-pip -y
    sudo apt install -y build-essential libelf-dev libssl-dev -y
    sudo apt install -y flex bison libssl-dev libelf-dev qemu-kvm debootstrap bc libstdc++-13-dev glibc-source
}

# Function to install Go environment
install_go() {
    print_step "Note: Go version 1.23+ is required for syzkaller"
    read -p "Do you want to install Go environment? (Y/N): " go_choice
    case "$go_choice" in
        [yY]|[yY][eE][sS])
            print_step "Installing Go environment..."
            wget https://dl.google.com/go/go1.23.6.linux-amd64.tar.gz -O /tmp/go1.23.6.linux-amd64.tar.gz
            sudo tar -C /usr/local -xzf /tmp/go1.23.6.linux-amd64.tar.gz
            export PATH=$PATH:/usr/local/go/bin
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            ;;
        *)
            print_step "Skipping Go installation..."
            ;;
    esac
}

# Function to install and build syzkaller
install_syzkaller() {
    print_step "Installing syzkaller..."
    SYZKALLER_DIR="$SYZKALLER_PATH/syzkaller"
    if check_and_handle_directory "$SYZKALLER_DIR"; then
        git clone https://github.com/google/syzkaller "$SYZKALLER_DIR"
    fi

    read -p "Do you want to change to syzkaller directory and build? (Y/N): " build_choice
    case "$build_choice" in
        [yY]|[yY][eE][sS])
            print_step "Changing to syzkaller directory..."
            cd "$SYZKALLER_DIR" || { echo "Failed to change directory"; exit 1; }
            git config --global --add safe.directory "$SYZKALLER_DIR"
            print_step "Cleaning previous build..."
            make clean
            print_step "Building syzkaller..."
            make all && make bin/syz-extract && cd ..
            ;;
        *)
            print_step "Skipping directory change and build..."
            ;;
    esac
}

# Function to install QEMU
install_qemu() {
    print_step "Installing qemu&qemu-system..."
    sudo apt install qemu-user-static qemu-system -y
}

# Function to create QEMU image
create_qemu_image() {
    print_step "Compiling syzkaller's qemu image..."
    cp syzkaller/tools/create-image.sh .
    sudo chmod +x create-image.sh
    sudo ./create-image.sh
}

# Main menu function
show_menu() {
    clear
    echo "=== Syzkaller Setup Menu ==="
    echo "Installation Path: $SYZKALLER_PATH"
    echo "=========================="
    echo "1. Install System Dependencies"
    echo "2. Install Go Environment"
    echo "3. Install and Build Syzkaller"
    echo "4. Install QEMU"
    echo "5. Create QEMU Image"
    echo "0. Exit"
    echo "=========================="
    echo "Enter numbers separated by spaces (e.g., '1 2 3') to run multiple steps"
    echo "Or enter a single number to run one step"
}

# Function to execute selected steps
execute_steps() {
    local steps=("$@")
    for step in "${steps[@]}"; do
        case $step in
            1) install_dependencies ;;
            2) install_go ;;
            3) install_syzkaller ;;
            4) install_qemu ;;
            5) create_qemu_image ;;
            7)
                install_dependencies
                install_go
                install_syzkaller
                install_qemu
                create_qemu_image
                ;;
            0) 
                print_step "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid choice: $step"
                ;;
        esac
    done
}

# Main script
while true; do
    show_menu
    read -p "Enter your choice(s): " choices
    if [ -z "$choices" ]; then
        echo "No choice made. Please try again."
        continue
    fi
    # Convert space-separated string to array
    choices_array=($choices)
    execute_steps "${choices_array[@]}"
    read -p "Press Enter to continue..."
done