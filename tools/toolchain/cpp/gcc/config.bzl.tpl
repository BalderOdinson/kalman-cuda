"""
This module contains config for clang/llvm toolchain
"""

load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "tool_path",
)
load("@%{name}//:features.bzl", "features")

def get_tool_paths():
    return [
        tool_path(
            name = "ld",
            path = "%{ld_executable}",
        ),
        tool_path(
            name = "cpp",
            path = "%{cpp_executable}",
        ),
        tool_path(
            name = "dwp",
            path = "%{dwp_executable}",
        ),
        tool_path(
            name = "gcov",
            path = "%{gcov_executable}",
        ),
        tool_path(
            name = "nm",
            path = "%{nm_executable}",
        ),
        tool_path(
            name = "objcopy",
            path = "%{objcopy_executable}",
        ),
        tool_path(
            name = "objdump",
            path = "%{objdump_executable}",
        ),
        tool_path(
            name = "strip",
            path = "%{strip_executable}",
        ),
        tool_path(
            name = "gcc",
            path = "%{gcc_executable}",
        ),
        tool_path(
            name = "ar",
            path = "%{ar_executable}",
        ),
    ]

def get_cxx_builtin_include_directories():
    return [
        %{cxx_builtin_include_directories}
    ]

def _impl(ctx):
    """
    Provides CcToolchainConfigInfo for gcc toolchain

    Returns:
        CcToolchainConfigInfo for gcc toolchain
    """

    cxx_builtin_include_directories = get_cxx_builtin_include_directories()

    tool_paths = get_tool_paths()

    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(out, "Fake executable")
    return [
        cc_common.create_cc_toolchain_config_info(
            ctx = ctx,
            features = features(),
            action_configs = [],
            artifact_name_patterns = [],
            cxx_builtin_include_directories = cxx_builtin_include_directories,
            toolchain_identifier = "gcc",
            host_system_name = "x86_64",
            target_system_name = "x86_64-unknown-linux-gnu",
            target_cpu = "k8",
            target_libc = "glibc_unknown",
            compiler = "gcc",
            abi_version = "gcc",
            abi_libc_version = "glibc_unknown",
            tool_paths = tool_paths,
            make_variables = [],
            cc_target_os = None,
        ),
        DefaultInfo(
            executable = out,
        ),
    ]

cc_toolchain_config = rule(
    executable = True,
    provides = [CcToolchainConfigInfo],
    implementation = _impl,
)
