"""
Repository rules for including clang/llvm toolchain
"""

def _clang_toolchain_impl(repository_ctx):
    substitutions = {
        "%{lib_path}": repository_ctx.attr.lib_path,
        "%{cpp_standard}": repository_ctx.attr.cpp_standard,
        "%{cxx_builtin_include_directories}": ("\n" + 8 * " ").join(
            ["\"%s\"," % d for d in repository_ctx.attr.cxx_builtin_include_directories]),
        "%{lld_executable}": repository_ctx.attr.lld_executable,
        "%{ld_executable}": repository_ctx.attr.ld_executable,
        "%{ld_lld_executable}": repository_ctx.attr.ld_lld_executable,
        "%{ld_gold_executable}": repository_ctx.attr.ld_gold_executable,
        "%{cpp_executable}": repository_ctx.attr.cpp_executable,
        "%{cplusplus_executable}": repository_ctx.attr.cplusplus_executable,
        "%{dwp_executable}": repository_ctx.attr.dwp_executable,
        "%{profdata_executable}": repository_ctx.attr.profdata_executable,
        "%{nm_executable}": repository_ctx.attr.nm_executable,
        "%{objcopy_executable}": repository_ctx.attr.objcopy_executable,
        "%{objdump_executable}": repository_ctx.attr.objdump_executable,
        "%{strip_executable}": repository_ctx.attr.strip_executable,
        "%{clang_executable}": repository_ctx.attr.clang_executable,
        "%{ar_executable}": repository_ctx.attr.ar_executable,
        "%{system_include_directories}": ("\n" + 8 * " ").join(
            ["\"%s\"," % d for d in repository_ctx.attr.system_include_directories]),
        "%{name}": repository_ctx.name,
    }

    repository_ctx.template(
        "features.bzl",
        Label("//tools/toolchain/cpp/clang_linux:features.bzl.tpl"),
        substitutions
    )

    repository_ctx.template(
        "toolchain_config.bzl",
        Label("//tools/toolchain/cpp/clang_linux:config.bzl.tpl"),
        substitutions
    )

    repository_ctx.template(
        "BUILD.bazel",
        Label("//tools/toolchain/cpp/clang_linux:BUILD.bazel.tpl"),
        substitutions
    )

clang_toolchain = repository_rule(
    attrs = {
        "lib_path": attr.string(
            mandatory = True,
            doc = "Path to LLVM libs folder.",
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
        "lld_executable": attr.string(
            mandatory = True,
            doc = "Path to lld executable.",
        ),
        "ld_executable": attr.string(
            mandatory = True,
            doc = "Path to ld executable.",
        ),
        "ld_lld_executable": attr.string(
            mandatory = True,
            doc = "Path to ld.lld executable.",
        ),
        "ld_gold_executable": attr.string(
            mandatory = True,
            doc = "Path to ld.gold executable.",
        ),
        "cpp_executable": attr.string(
            mandatory = True,
            doc = "Path to cpp exexutable.",
        ),
        "cplusplus_executable": attr.string(
            mandatory = True,
            doc = "Path to c++ exexutable.",
        ),
        "dwp_executable": attr.string(
            mandatory = True,
            doc = "Path to dwp exexutable.",
        ),
        "profdata_executable": attr.string(
            mandatory = True,
            doc = "Path to profdata exexutable.",
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
        "clang_executable": attr.string(
            mandatory = True,
            doc = "Path to clang exexutable.",
        ),
        "ar_executable": attr.string(
            mandatory = True,
            doc = "Path to ar exexutable.",
        ),
    },
    local = True,
    implementation = _clang_toolchain_impl,
)
