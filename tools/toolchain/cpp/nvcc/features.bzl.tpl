"""
This module contains features available for clang-linux compiler
"""

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "feature_set",
    "with_feature_set",
)
load("@%{host_compiler}//:features.bzl", _host_features = "features")
load(
    "@%{host_compiler}//:toolchain_config.bzl",
    _host_tool_paths = "get_tool_paths",
)

def get_tool_path_by_name(name):
    for tool in _host_tool_paths():
        if tool.name == name:
            return tool.path
    fail("Tool {} not found".format(name))


def features():
    """
    Helper function that returns all available features.

    Returns:
        Returns all features available for clang-linux compiler.
    """
    all_compile_actions = [
        ACTION_NAMES.c_compile,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.assemble,
        ACTION_NAMES.preprocess_assemble,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.clif_match,
        ACTION_NAMES.lto_backend,
    ]

    all_cpp_compile_actions = [
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.clif_match,
    ]

    preprocessor_compile_actions = [
        ACTION_NAMES.c_compile,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.preprocess_assemble,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.clif_match,
    ]

    codegen_compile_actions = [
        ACTION_NAMES.c_compile,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.assemble,
        ACTION_NAMES.preprocess_assemble,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.lto_backend,
    ]

    all_link_actions = [
        ACTION_NAMES.cpp_link_executable,
        ACTION_NAMES.cpp_link_dynamic_library,
        ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ]

    system_include_directories = [
        %{system_include_directories}
    ]

    nvcc_default_link_flags_feature = feature(
        name = "nvcc_default_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-forward-unknown-to-host-linker",
                            "-L%{lib_path}",
                            "-l:libcublas",
                            "-l:libcudart",
                            "-l:libcufft",
                            "-l:libcurand",
                        ],
                    ),
                ],
            ),
        ],
    )

    nvcc_default_compile_flags_feature = feature(
        name = "nvcc_default_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wall",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = all_compile_actions,
                flag_groups = [flag_group(flags = ["-g", "-fstandalone-debug"])],
                with_features = [with_feature_set(features = ["dbg"])],
            ),
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-g0",
                            "-O2",
                            "-DNDEBUG",
                        ],
                    ),
                ],
                with_features = [with_feature_set(features = ["opt"])],
            ),
            flag_set(
                actions = all_cpp_compile_actions,
                flag_groups = [flag_group(flags = [
                    "-std=%{cpp_standard}",
                    "-forward-unknown-to-host-compiler",
                    "-ccbin={}".format(get_tool_path_by_name("gcc")),
                    "-arbin={}".format(get_tool_path_by_name("ar")),
                ])],
            ),
        ],
    )

#    native_arch_feature = feature(
#         name = "native_arch",
#         enabled = False,
#         flag_sets = [
#            flag_set(
#                actions = all_compile_actions,
#                flag_groups = [
#                    flag_group(
#                        flags = ["-march=native"]
#                    )
#                ],
#            ),
#        ],
#    )

    nvcc_system_includes_paths_feature = feature(
        name = "nvcc_system_includes_paths",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = preprocessor_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-isystem" + include_path for include_path in system_include_directories],
                    ),
                ],
            ),
        ],
    )

    nvcc_compiler_input_flags_feature = feature(
        name = "compiler_input_flags",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_codegen,
                ],
                flag_groups = [
                    flag_group(
                        expand_if_available = "source_file",
                        flags = ["%{source_file}"],
                    ),
                ],
            ),
        ],
    )

    test_feature = feature(
        name = "test_flags",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["%{source_file}"],
                    ),
                ],
            ),
        ],
    )

    test_feature_one = feature(
        name = "test_flags_one",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["%{source_file}"],
                    ),
                ],
            ),
        ],
    )

    return [test_feature, test_feature_one]

    return _host_features() + [
        nvcc_compiler_input_flags_feature,
        nvcc_default_link_flags_feature,
        nvcc_default_compile_flags_feature,
        nvcc_system_includes_paths_feature,
        # native_arch_feature,
    ]
