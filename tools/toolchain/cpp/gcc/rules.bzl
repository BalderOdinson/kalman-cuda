"""
Repository rules for including gcc toolchain
"""

def _gcc_toolchain_impl(repository_ctx):
    substitutions = {
        "%{lib_path}": repository_ctx.attr.lib_path,
        "%{cpp_standard}": repository_ctx.attr.cpp_standard,
        "%{cxx_builtin_include_directories}": ("\n" + 8 * " ").join(
            ["\"%s\"," % d for d in repository_ctx.attr.cxx_builtin_include_directories]),
        "%{ld_executable}": repository_ctx.attr.ld_executable,
        "%{cpp_executable}": repository_ctx.attr.cpp_executable,
        "%{dwp_executable}": repository_ctx.attr.dwp_executable,
        "%{gcov_executable}": repository_ctx.attr.gcov_executable,
        "%{nm_executable}": repository_ctx.attr.nm_executable,
        "%{objcopy_executable}": repository_ctx.attr.objcopy_executable,
        "%{objdump_executable}": repository_ctx.attr.objdump_executable,
        "%{strip_executable}": repository_ctx.attr.strip_executable,
        "%{gcc_executable}": repository_ctx.attr.gcc_executable,
        "%{ar_executable}": repository_ctx.attr.ar_executable,
        "%{system_include_directories}": ("\n" + 8 * " ").join(
            ["\"%s\"," % d for d in repository_ctx.attr.system_include_directories]),
        "%{name}": repository_ctx.name,
    }

    repository_ctx.template(
        "features.bzl",
        Label("//tools/toolchain/cpp/gcc:features.bzl.tpl"),
        substitutions
    )

    repository_ctx.template(
        "toolchain_config.bzl",
        Label("//tools/toolchain/cpp/gcc:config.bzl.tpl"),
        substitutions
    )

    repository_ctx.template(
        "BUILD.bazel",
        Label("//tools/toolchain/cpp/gcc:BUILD.bazel.tpl"),
        substitutions
    )

gcc_toolchain = repository_rule(
    attrs = {
        "lib_path": attr.string(
            mandatory = True,
            doc = "Path to gcc libs folder.",
        ),
        "sysroot": attr.string(
            mandatory = True,
            doc = ("System path used to indicate the set of files that form the sysroot for the compiler."),
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
        "ld_executable": attr.string(
            mandatory = True,
            doc = "Path to ld executable.",
        ),
        "cpp_executable": attr.string(
            mandatory = True,
            doc = "Path to cpp exexutable.",
        ),
        "dwp_executable": attr.string(
            mandatory = True,
            doc = "Path to dwp exexutable.",
        ),
        "gcov_executable": attr.string(
            mandatory = True,
            doc = "Path to gcov exexutable.",
        ),
        "nm_executable": attr.string(
            mandatory = True,
            doc = "Path to nm exexutable.",
        ),
        "objcopy_executable": attr.string(
            mandatory = True,
            doc = "Path to objcopy exexutable.",
        ),
        "objdump_executable": attr.string(
            mandatory = True,
            doc = "Path to objdump exexutable.",
        ),
        "strip_executable": attr.string(
            mandatory = True,
            doc = "Path to strip exexutable.",
        ),
        "gcc_executable": attr.string(
            mandatory = True,
            doc = "Path to gcc exexutable.",
        ),
        "ar_executable": attr.string(
            mandatory = True,
            doc = "Path to ar exexutable.",
        ),
    },
    local = True,
    implementation = _gcc_toolchain_impl,
)
