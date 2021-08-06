#!/bin/bash

setup_windows() {
    echo "Downloading bazel tools for Windows..."
    curl -kLSs "https://github.com/bazelbuild/bazelisk/releases/download/v1.10.1/bazelisk-windows-amd64.exe" -o "bazel.exe"
    curl -kLSs "https://github.com/bazelbuild/buildtools/releases/download/4.0.1/buildifier-windows-amd64.exe" -o "buildifier.exe"
}

setup_linux() {
    echo "Downloading bazel tools for Linux..."
    curl -kLSs "https://github.com/bazelbuild/bazelisk/releases/download/v1.9.0/bazelisk-linux-amd64" -o bazel
    chmod u+x bazel
    curl -kLSs "https://github.com/bazelbuild/buildtools/releases/download/4.0.1/buildifier-linux-amd64" -o buildifier
    chmod u+x buildifier
}

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    setup_linux
elif [[ "$OSTYPE" == "cygwin" ]]; then
    setup_windows
elif [[ "$OSTYPE" == "msys" ]]; then
    setup_windows
else
    echo "OS not supported. Feel free to add support!"
fi
