CudaToolchainConfigInfo = provider(
    doc = "Config required to build CUDA toolchain",
    fields = [
        "tools",
        "features",
    ],
)

CudaToolchainInfo = provider(
    doc = "Information about invoking nvcc",
    fields = [
        "nvcc_path",
        "tools",
        "builtin_include_directories",
        "libraries",
        "features",
    ],
)

CudaInfo = provider(
    doc = "Contains information for compilation and linking of cuda_library rules",
    fields = ["linking_context"]
)
