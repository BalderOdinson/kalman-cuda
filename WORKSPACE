workspace(name = "kalman-cuda")

register_execution_platforms(
    "//tools/platforms:linux_x86_64",
    "//tools/platforms:linux_clang_x86_64",
)

load("//tools/toolchain/cpp/clang_linux:rules.bzl", "clang_toolchain")
load("//tools/toolchain/cpp/gcc:rules.bzl", "gcc_toolchain")
load("//tools/toolchain/cpp/nvcc:rules.bzl", "nvcc_toolchain")

clang_toolchain(
    name = "clang_linux",
    lib_path = "/usr/lib/llvm-11/lib",
    sysroot = "/",
    cpp_standard = "c++11",
    cxx_builtin_include_directories = [
        "/usr/include",
        "/usr/lib/clang/11.1.0/include",
        "/usr/lib/llvm-11/include/c++/v1",
    ],
    system_include_directories = [
        "/usr/lib/llvm-11/include/c++/v1",
    ],
    lld_executable = "/usr/bin/lld-11",
    ld_executable = "/usr/bin/ld",
    ld_lld_executable = "/usr/bin/ld.lld-11",
    ld_gold_executable = "/usr/bin/ld.gold",
    cpp_executable = "/usr/bin/clang-cpp-11",
    cplusplus_executable = "/usr/bin/clang++-11",
    dwp_executable = "/usr/bin/llvm-dwp-11",
    profdata_executable = "/usr/bin/llvm-profdata-11",
    nm_executable = "/usr/bin/llvm-nm-11",
    objcopy_executable = "/usr/bin/llvm-objcopy-11",
    objdump_executable = "/usr/bin/llvm-objdump-11",
    strip_executable = "/usr/bin/strip",
    clang_executable = "/usr/bin/clang-11",
    ar_executable = "/usr/bin/llvm-ar-11",
)

gcc_toolchain(
    name = "gcc-10",
    lib_path = "/usr/lib/gcc/x86_64-linux-gnu/10",
    sysroot = "/",
    cpp_standard = "c++11",
    cxx_builtin_include_directories = [
        "/usr/include",
        "/usr/lib/gcc/x86_64-linux-gnu/10/include",
        "/usr/include/c++/10/",
    ],
    system_include_directories = [
        "/usr/include/c++/10/",
    ],
    ld_executable = "/usr/bin/ld",
    cpp_executable = "/usr/bin/cpp-10",
    dwp_executable = "/usr/bin/dwp",
    gcov_executable = "/usr/bin/gcov-10",
    nm_executable = "/usr/bin/gcc-nm-10",
    objcopy_executable = "/usr/bin/objcopy",
    objdump_executable = "/usr/bin/objdump",
    strip_executable = "/usr/bin/strip",
    gcc_executable = "/usr/bin/gcc-10",
    ar_executable = "/usr/bin/gcc-ar-10",
)

nvcc_toolchain(
    name = "nvcc-gcc",
    lib_path = "/usr/local/cuda/lib64",
    cpp_standard = "c++17",
    cxx_builtin_include_directories = [
        "/usr/local/cuda/include",
    ],
    system_include_directories = [
        "/usr/local/cuda/include",
    ],
    nvcc_executable = "/usr/local/cuda/bin/nvcc",
    host_compiler = "gcc-10"
)

register_toolchains(
    "@clang_linux//:cc-toolchain",
    "@gcc-10//:cc-toolchain",
    "@nvcc-gcc//:cc-toolchain",
)

local_repository(
    name = "rules_cuda",
    path = "tools/toolchain/cuda",
)

load("@rules_cuda//:repository.bzl", "cuda_toolchain")

cuda_toolchain()
