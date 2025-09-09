#!/bin/bash
# Function to check if a command exists

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print section header
print_header() {
    echo
    echo "**************************************"
    echo "* $1"
    echo "**************************************"
    echo
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_header "WARNING: Not running as root!"
    echo "Some operations may fail."
    echo "Run with sudo for complete installation."
    echo
    sleep 3
fi

# Initialize variables
JAVA_INSTALLED=0
MAVEN_INSTALLED=0
GIT_INSTALLED=0
NEED_PATH_UPDATE=0
JAVA_HOME_PATH=""
MAVEN_HOME_PATH=""
CURRENT_DIR=$(pwd)
STELLAR_PROJECT_DIR="$CURRENT_DIR/stellar-sample-project"

# Check Java Installation
check_java() {
    if command_exists java; then
        JAVA_INSTALLED=1
        show_java_info
    else
        install_java
    fi
}

show_java_info() {
    print_header "JDK ALREADY INSTALLED"
    java -version

    # Try to find JAVA_HOME
    if [ -z "$JAVA_HOME" ]; then
        # Check common installation locations
        if [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
            JAVA_HOME_PATH="/usr/lib/jvm/java-21-openjdk-amd64"
        elif [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
            JAVA_HOME_PATH="/usr/lib/jvm/java-11-openjdk-amd64"
        elif [ -d "/usr/lib/jvm/default-java" ]; then
            JAVA_HOME_PATH="/usr/lib/jvm/default-java"
        fi

        if [ -n "$JAVA_HOME_PATH" ]; then
            NEED_PATH_UPDATE=1
            echo "Found Java installation at: $JAVA_HOME_PATH"
        fi
    else
        echo "JAVA_HOME is already set to: $JAVA_HOME"
    fi
}

install_java() {
    print_header "INSTALLING JDK 21"
    echo "Updating package list..."
    apt-get update >/dev/null

    echo "Installing JDK 21..."
    apt-get install -y openjdk-21-jdk

    if command_exists java; then
        JAVA_HOME_PATH=$(update-alternatives --list java | head -n 1 | sed 's|/bin/java||')
        NEED_PATH_UPDATE=1
        echo
        echo "JDK 21 installed successfully!"
    else
        echo
        echo "JDK installation failed"
        exit 1
    fi
}

# Check Maven Installation
check_maven() {
    if command_exists mvn; then
        MAVEN_INSTALLED=1
        show_maven_info
    else
        install_maven
    fi
}

show_maven_info() {
    print_header "MAVEN ALREADY INSTALLED"
    mvn --version

    # Try to find MAVEN_HOME
    if [ -z "$MAVEN_HOME" ]; then
        # Check common installation locations
        MAVEN_PATH=$(which mvn)
        if [ -n "$MAVEN_PATH" ]; then
            MAVEN_HOME_PATH=$(dirname $(dirname "$MAVEN_PATH"))
            NEED_PATH_UPDATE=1
            echo "Found Maven installation at: $MAVEN_HOME_PATH"
        fi
    else
        echo "MAVEN_HOME is already set to: $MAVEN_HOME"
    fi
}

install_maven() {
    print_header "INSTALLING MAVEN"
    echo "Updating package list..."
    apt-get update >/dev/null

    echo "Installing Maven..."
    apt-get install -y maven

    if command_exists mvn; then
        MAVEN_HOME_PATH=$(dirname $(dirname $(which mvn)))
        NEED_PATH_UPDATE=1
        echo
        echo "Maven installed successfully!"
        echo "Installed version:"
        mvn --version
    else
        echo
        echo "Maven installation failed"
        exit 1
    fi
}

# Check Git Installation
check_git() {
    if command_exists git; then
        GIT_INSTALLED=1
        show_git_info
    else
        install_git
    fi
}

show_git_info() {
    print_header "GIT ALREADY INSTALLED"
    git --version
}

install_git() {
    print_header "INSTALLING GIT"
    echo "Updating package list..."
    apt-get update >/dev/null

    echo "Installing Git..."
    apt-get install -y git

    if command_exists git; then
        echo
        echo "Git installed successfully!"
        
        # Configure Git
        echo "Configuring Git..."
        read -p "Enter your Git user name: " git_username
        read -p "Enter your Git email: " git_email
        
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase true
        
        echo "Git configured successfully!"
    else
        echo
        echo "Git installation failed"
        exit 1
    fi
}

# Update environment variables
update_environment() {
    if [ $NEED_PATH_UPDATE -eq 1 ]; then
        print_header "UPDATING ENVIRONMENT VARIABLES"

        # Update .bashrc for current user
        BASHRC_FILE="$HOME/.bashrc"

        if [ -n "$JAVA_HOME_PATH" ]; then
            echo "Setting JAVA_HOME to $JAVA_HOME_PATH"
            echo "export JAVA_HOME=$JAVA_HOME_PATH" >> "$BASHRC_FILE"
            echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> "$BASHRC_FILE"
        fi

        if [ -n "$MAVEN_HOME_PATH" ]; then
            echo "Setting MAVEN_HOME to $MAVEN_HOME_PATH"
            echo "export MAVEN_HOME=$MAVEN_HOME_PATH" >> "$BASHRC_FILE"
            echo "export PATH=\$PATH:\$MAVEN_HOME/bin" >> "$BASHRC_FILE"
        fi

        # Source the updated .bashrc
        source "$BASHRC_FILE"
        echo "Environment variables updated. You may need to restart your terminal or run 'source ~/.bashrc'"
    fi
}

# Clone Stellar project
clone_stellar_project() {
    print_header "CLONING STELLAR PROJECT"

    # Remove existing project if it exists
    if [ -d "$STELLAR_PROJECT_DIR" ]; then
        echo "Removing existing project..."
        rm -rf "$STELLAR_PROJECT_DIR"
    fi

    # Clone new project
    echo "Cloning fresh Stellar sample project..."
    git clone https://asadrazamahmood@bitbucket.org/stellar2/stellar-sample-project.git "$STELLAR_PROJECT_DIR"

    if [ $? -eq 0 ]; then
        echo
        echo "Project cloned successfully!"
        echo "Location: $STELLAR_PROJECT_DIR"
        
        # Show project structure
        echo
        echo "Project structure:"
        cd "$STELLAR_PROJECT_DIR"
        ls -la
    else
        echo
        echo "Error: Failed to clone project"
        echo "Please check your credentials and try again"
    fi
}

# Main execution
check_java
check_maven
check_git
update_environment

print_header "INSTALLATION SUMMARY"

echo "- JDK Status:"
if command_exists java; then
    echo "  JDK is working properly"
    java -version
else
    echo "  JDK not working properly"
fi

echo
echo "- Maven Status:"
if command_exists mvn; then
    echo "  Maven is working properly"
    mvn --version
else
    echo "  Maven not working properly"
fi

echo
echo "- Git Status:"
if command_exists git; then
    echo "  Git is working properly"
    git --version
else
    echo "  Git not working properly"
fi

echo
echo "Environment variables set:"
[ -n "$JAVA_HOME_PATH" ] && echo "  JAVA_HOME: $JAVA_HOME_PATH"
[ -n "$MAVEN_HOME_PATH" ] && echo "  MAVEN_HOME: $MAVEN_HOME_PATH"

# Clone Stellar project if Git is available
if command_exists git; then
    clone_stellar_project
else
    echo "Skipping project cloning - Git not available"
fi

echo
echo "Next steps:"
echo "1. cd stellar-sample-project"
echo "2. mvn clean test"
echo

read -p "Press enter to continue..."