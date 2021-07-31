CudaToolchainInfo = provider(
    doc = "Information about invoking nvcc",
    fields = [
        "nvcc_path"
        "builtin_include_directories",
        "libraries",
        "features",
    ],
)

def _cuda_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        cuda_info = CudaToolchainInfo(
            nvcc_path = ctx.attr.config[CudaToolchainConfigInfo].nvcc_path,
            builtin_include_directories = ctx.attr.builtin_cuda_include_directories,
            libraries = ctx.attr.libraries,
            features = ctx.attr.config[CudaToolchainConfigInfo].features,
        ),
    )
    return [toolchain_info]

cuda_toolchain = rule(
    implementation = _cuda_toolchain_impl,
    attrs = {
        "config": attr.label(
            mandatory = True,
            doc = "CudaToolchainConfigInfo provider",
            providers = [CudaToolchainConfigInfo],
        ),
        "builtin_cuda_include_directories": attr.string_list(
            default = [],
            doc = "Directories containing core cuda includes. Ex. /usr/local/cuda/include",
        ),
        "libraries": attr.label_list(
            default = [],
            doc = "Core CUDA libraries like cudart to be linked with host compiler.",
        ),
    },
)

def _cuda_library_impl(ctx):
    pass

cuda_library = rule(
    implementation = _cuda_library_impl,
    attrs = {
        "_cc_toolchain": attr.label(
            default = Label("@rules_cc//cc:current_cc_toolchain"),
            doc = "Host compiler",
        ),
        "deps": attr.label_list(
            doc = "The list of other libraries to be linked in to the binary target.",
            default = [],
        ),
        "srcs": attr.label_list(

        )
    },
    toolchains = [
        "//:toolchain_type",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
    provides = [CcInfo],
    incompatible_use_toolchain_transition = True,
)
