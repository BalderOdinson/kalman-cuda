load("@rules_cuda//:cuda_toolchain_config.bzl", "create_cuda_toolchain_config")

def _impl(ctx):
    return create_cuda_toolchain_config(ctx.files.tools)

cuda_toolchain_config = rule(
    attrs = {
        "tools": attr.label_list(
            mandatory = True,
            allow_files = True,
        )
    },
    implementation = _impl,
)
