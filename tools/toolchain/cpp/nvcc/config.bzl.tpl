"""
This module contains config for clang/llvm toolchain
"""

load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "tool_path",
)
load("@%{name}//:features.bzl", "features")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain")
load("@%{host_compiler}//:features.bzl", _host_features = "features")
load(
    "@%{host_compiler}//:toolchain_config.bzl",
    _host_tool_paths = "get_tool_paths",
    _host_cxx_builtin_include_directories = "get_cxx_builtin_include_directories",
)

def get_tool_paths():
    return [tool_path(name = "gcc", path = "%{nvcc_executable}") if tool.name == "gcc" else tool for tool in _host_tool_paths()]

def get_cxx_builtin_include_directories():
    return [
        %{cxx_builtin_include_directories}
    ] + _host_cxx_builtin_include_directories()

def _impl(ctx):
    """
    Provides CcToolchainConfigInfo for nvcc toolchain

    Returns:
        CcToolchainConfigInfo for nvcc toolchain
    """

    cxx_builtin_include_directories = get_cxx_builtin_include_directories()

    tool_paths = get_tool_paths()

    cc_toolchain = find_cc_toolchain(ctx)

    print(cc_common.configure_features(ctx = ctx, cc_toolchain = cc_toolchain))


    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(out, "Fake executable")
    return [
        cc_common.create_cc_toolchain_config_info(
            ctx = ctx,
            features = features(),
            action_configs = [],
            artifact_name_patterns = [],
            cxx_builtin_include_directories = cxx_builtin_include_directories,
            toolchain_identifier = "nvcc",
            host_system_name = "x86_64",
            target_system_name = "x86_64-unknown-linux-gnu",
            target_cpu = "k8",
            target_libc = "glibc_unknown",
            compiler = "nvcc",
            abi_version = "nvcc",
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
    attrs = {
        "_cc_toolchain": attr.label(
            default = Label("@rules_cc//cc:current_cc_toolchain"),
            doc = "Host compiler",
        ),
    },
    toolchains = [
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
    executable = True,
    provides = [CcToolchainConfigInfo],
    implementation = _impl,
    fragments = ['cpp'],
    incompatible_use_toolchain_transition = True,
)
