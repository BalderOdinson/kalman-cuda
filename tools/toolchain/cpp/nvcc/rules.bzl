"""
Repository rules for including gcc toolchain
"""

def _nvcc_toolchain_impl(repository_ctx):
    substitutions = {
        "%{lib_path}": repository_ctx.attr.lib_path,
        "%{cpp_standard}": repository_ctx.attr.cpp_standard,
        "%{cxx_builtin_include_directories}": ("\n" + 8 * " ").join(
            ["\"%s\"," % d for d in repository_ctx.attr.cxx_builtin_include_directories]),
        "%{nvcc_executable}": repository_ctx.attr.nvcc_executable,
        "%{system_include_directories}": ("\n" + 8 * " ").join(
            ["\"%s\"," % d for d in repository_ctx.attr.system_include_directories]),
        "%{name}": repository_ctx.name,
        "%{host_compiler}": str(repository_ctx.attr.host_compiler),
    }

    repository_ctx.template(
        "features.bzl",
        Label("//tools/toolchain/cpp/nvcc:features.bzl.tpl"),
        substitutions
    )

    repository_ctx.template(
        "toolchain_config.bzl",
        Label("//tools/toolchain/cpp/nvcc:config.bzl.tpl"),
        substitutions
    )

    repository_ctx.template(
        "BUILD.bazel",
        Label("//tools/toolchain/cpp/nvcc:BUILD.bazel.tpl"),
        substitutions
    )

nvcc_toolchain = repository_rule(
    attrs = {
        "lib_path": attr.string(
            mandatory = True,
            doc = "Path to CUDA libs folder.",
        ),
        "cpp_standard": attr.string(
            mandatory = True,
            doc = "Cpp standard to be used in compile.",
        ),
        "cxx_builtin_include_directories": attr.string_list(
            mandatory = True,
            doc = "Builtin include directories available to compiler.",
        ),
        "system_include_directories": attr.string_list(
            mandatory = True,
            doc = "Headers folder that will be available via system include.",
        ),
        "nvcc_executable": attr.string(
            mandatory = True,
            doc = "Path to nvcc exexutable.",
        ),
        "host_compiler": attr.string(
            mandatory = True,
            doc = "Workspace name of the host compiler used by nvcc.",
        ),
    },
    local = True,
    implementation = _nvcc_toolchain_impl,
)
