FROM nvcr.io/nvidia/tensorrt:21.06-py3

LABEL Name=kalman-cuda Version=0.0.1

# Install essentials
RUN apt update && apt upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt install -y wget \
    lsb-release \
    software-properties-common \
    build-essential \
    manpages-dev

# Install clang-12
RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 11
RUN apt install -y libc++-11-dev libc++abi-11-dev libunwind-dev

# Install gcc-10
RUN apt install gcc-10 g++-10 -y

RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.9.0/bazelisk-linux-amd64 -O /usr/local/bin/bazel
RUN chmod u+x /usr/local/bin/bazel
RUN wget https://github.com/bazelbuild/buildtools/releases/download/4.0.1/buildifier-linux-amd64 -O /usr/local/bin/buildifier
RUN chmod u+x /usr/local/bin/buildifier

CMD ["bash"]
