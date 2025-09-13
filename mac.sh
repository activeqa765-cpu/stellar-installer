#!/bin/bash

# JDK 21, Maven, Git, and Stellar Project Setup Script

echo "Starting complete installation process..."

## Function to detect Mac architecture
detect_architecture() {
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        echo "Apple Silicon (M1/M2) detected"
        JDK_URL="https://download.oracle.com/java/21/latest/jdk-21_macos-aarch64_bin.dmg"
    else
        echo "Intel processor detected"
        JDK_URL="https://download.oracle.com/java/21/latest/jdk-21_macos-x64_bin.dmg"
    fi
}

## Function to check if JDK 21 is already installed
check_jdk_21_installed() {
    # Check if Java is installed and if it's version 21
    if type -p java >/dev/null 2>&1; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)
        if [[ "$JAVA_VERSION" == "21" ]]; then
            echo "JDK 21 is already installed"
            return 0
        else
            return 1
        fi
    else
        echo "No JDK found"
        return 1
    fi
}

## Function to check if Git is already installed
check_git_installed() {
    if type -p git >/dev/null 2>&1; then
        GIT_VERSION=$(git --version 2>&1 | awk '{print $3}')
        echo "Git is already installed (version $GIT_VERSION)"
        return 0
    else
        echo "Git is not installed"
        return 1
    fi
}

## Function to install Git using Xcode Command Line Tools (SIMPLIFIED)
install_git() {
    echo "Installing Git using Xcode Command Line Tools..."

    # Check if Xcode Command Line Tools already installed
    if xcode-select -p &>/dev/null; then
        echo "Xcode Command Line Tools already installed"
    else
        echo "Please install Xcode Command Line Tools..."
        echo "A dialog box will appear. Click 'Install' and agree to terms."

        # Trigger installation
        xcode-select --install

        # Wait for user to complete installation
        echo "Waiting for Xcode Command Line Tools installation to complete..."
        while ! xcode-select -p &>/dev/null; do
            sleep 5
            echo "Still waiting... Please complete the installation."
        done
    fi

    # Verify Git installation
    if type -p git >/dev/null 2>&1; then
        GIT_VERSION=$(git --version 2>&1 | awk '{print $3}')
        echo "Git installed successfully (version $GIT_VERSION)"
    else
        echo "Error: Git installation failed through Xcode Command Line Tools"
        echo "Please install Git manually: https://git-scm.com/download/mac"
        exit 1
    fi
}

## Function to check if Maven is already installed
check_maven_installed() {
    if type -p mvn >/dev/null 2>&1; then
        MAVEN_VERSION=$(mvn -version 2>&1 | awk -F ' ' '/Apache Maven/ {print $3}')
        echo "Maven is already installed (version $MAVEN_VERSION)"
        return 0
    else
        echo "Maven is not installed"
        return 1
    fi
}

## Function to install Maven
install_maven() {
    echo "Installing Maven..."
    MAVEN_VERSION="3.9.11"
    MAVEN_URL="https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"

    # Create directory and download Maven
    mkdir -p ~/maven
    curl -L "$MAVEN_URL" | tar xz -C ~/maven

    # Set environment variables
    echo "export M2_HOME=\$HOME/maven/apache-maven-${MAVEN_VERSION}" >> ~/.zshrc
    echo "export MAVEN_HOME=\$HOME/maven/apache-maven-${MAVEN_VERSION}" >> ~/.zshrc
    echo 'export PATH=$M2_HOME/bin:$PATH' >> ~/.zshrc

    # Apply changes immediately
    export M2_HOME="$HOME/maven/apache-maven-${MAVEN_VERSION}"
    export MAVEN_HOME="$HOME/maven/apache-maven-${MAVEN_VERSION}"
    export PATH=$M2_HOME/bin:$PATH

    echo "Maven installed successfully"
}

## Function to install JDK 21 (FORCED INSTALLATION)
install_jdk_21() {
    echo "Installing JDK 21 for your Mac architecture..."
    JDK_DMG="jdk-21.dmg"
    TMP_MOUNT="/Volumes/JDK21_TEMP"

    # Download JDK
    echo "Downloading JDK from: $JDK_URL"
    curl -L -o "$JDK_DMG" "$JDK_URL"

    # Mount the DMG
    echo "Mounting JDK installer..."
    hdiutil attach "$JDK_DMG" -mountpoint "$TMP_MOUNT" -nobrowse

    # Find the package file
    PKG_FILE=$(find "$TMP_MOUNT" -name "*.pkg")

    # Install JDK
    echo "Installing JDK 21..."
    sudo installer -pkg "$PKG_FILE" -target /

    # Unmount and cleanup
    hdiutil detach "$TMP_MOUNT"
    rm "$JDK_DMG"

    # Configure Java Home
    echo "Configuring JAVA_HOME..."
    echo "export JAVA_HOME=\$(/usr/libexec/java_home -v 21)" >> ~/.zshrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.zshrc

    echo "JDK 21 installed successfully"
}

## Function to clone Stellar sample project into current directory
clone_stellar_project() {
    PROJECT_URL="https://asadrazamahmood@bitbucket.org/stellar2/stellar-sample-project.git"
    CURRENT_DIR=$(pwd)
    BASE_NAME="stellar-sample-project"

    echo "Cloning Stellar sample project into current directory: $CURRENT_DIR"

    # Check if base directory already exists
    if [ -d "$CURRENT_DIR/$BASE_NAME" ]; then
        # Find the next available number
        COUNTER=1
        while [ -d "$CURRENT_DIR/${BASE_NAME}-$COUNTER" ]; do
            ((COUNTER++))
        done

        CLONE_DIR="$CURRENT_DIR/${BASE_NAME}-$COUNTER"
        echo "Project directory already exists. Creating new directory: $CLONE_DIR"
    else
        CLONE_DIR="$CURRENT_DIR/$BASE_NAME"
    fi

    # Clone the project
    git clone "$PROJECT_URL" "$CLONE_DIR"

    if [ $? -eq 0 ]; then
        echo "Stellar sample project ready at: $CLONE_DIR"
        cd "$CLONE_DIR"

        # Show project structure
        echo "Project structure:"
        ls -la
    else
        echo "Error: Failed to clone Stellar project"
        echo "Please check your credentials and try again"
        exit 1
    fi
}

## Main installation process
echo "=== GIT INSTALLATION ==="
if ! check_git_installed; then
    install_git
else
    echo "Git is already installed, skipping installation..."
fi

echo ""
echo "=== JDK INSTALLATION ==="
detect_architecture
if ! check_jdk_21_installed; then
    install_jdk_21
else
    echo "JDK 21 is already installed, skipping installation..."
fi

echo ""
echo "=== MAVEN INSTALLATION ==="
## Maven Installation (only if needed)
if ! check_maven_installed; then
    install_maven
else
    echo "Maven is already installed, skipping installation..."
fi

echo ""
echo "=== vSTELLAR PROJECT CLONING ==="
## Clone Stellar project
clone_stellar_project

## Apply changes
source ~/.zshrc

echo ""
echo "=== FINAL VERIFICATION ==="
## Final verification
echo "Installation verification:"
echo "Git version:"
git --version
echo "Java version:"
java -version
echo "Maven version:"
mvn -v

echo ""
echo "=== PROJECT INFORMATION ==="
echo "Stellar sample project location: $(pwd)"
echo ""
echo "To run the project:"
echo "cd $(pwd)"
echo "mvn clean test"

echo ""
echo "All components installed successfully!"
echo "System is ready for development with Git, JDK 21, Maven, and Stellar!"