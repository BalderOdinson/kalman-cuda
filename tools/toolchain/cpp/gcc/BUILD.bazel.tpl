load("@%{name}//:toolchain_config.bzl", "cc_toolchain_config")
load("@rules_cc//cc:defs.bzl", "cc_toolchain")

package(
    default_visibility = ["//visibility:public"],
)

cc_toolchain_config(
    name = "gcc_config",
)

filegroup(
    name = "empty",
    srcs = [],
)

cc_toolchain_alias(name = "gcc_toolchain")

cc_toolchain(
    name = "gcc",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 1,
    toolchain_config = "gcc_config",
)

toolchain(
    name = "cc-toolchain",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    toolchain = ":gcc",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
