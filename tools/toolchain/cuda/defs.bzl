load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain")
load("@rules_cc//cc:action_names.bzl", "CPP_COMPILE_ACTION_NAME")
load("//:providers.bzl",
    "CudaToolchainConfigInfo",
    "CudaToolchainInfo",
    "CudaInfo",
)
load("//:common.bzl", "cuda_common")
load("//:action_names.bzl", "CUDA_ACTION_NAMES")
load("//:private/rules/utils.bzl",
    "preprocess_inputs",
    "process_features",
    "is_static_input",
)

def _cuda_toolchain_impl(ctx):
    nvcc_path = None
    for tool in ctx.attr.config[CudaToolchainConfigInfo].tools:
        if tool.basename in ["nvcc", "nvcc.exe"]:
            nvcc_path = tool.path
    if nvcc_path == None:
        fail("Could not find nvcc executable inside provided tools")


    toolchain_info = platform_common.ToolchainInfo(
        cuda_info = CudaToolchainInfo(
            nvcc_path = nvcc_path,
            tools = depset(ctx.attr.config[CudaToolchainConfigInfo].tools),
            builtin_include_directories = ctx.attr.builtin_cuda_include_directories,
            libraries = ctx.files.libraries,
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
            allow_files = True,
        ),
    },
)

def _cuda_library_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    cuda_toolchain = ctx.toolchains["@rules_cuda//:toolchain_type"].cuda_info

    inputs = preprocess_inputs(ctx, 'cuda_library')

    host_features = process_features(ctx.attr.host_features)
    device_features = process_features(ctx.attr.features)

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = host_features.requested_features,
        unsupported_features = host_features.unsupported_features,
    )

    use_pic = cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "pic"
    )

    host_compiler_path = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
    )

    host_compile_variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        system_include_directories = depset(inputs.local_system_include_paths),
        quote_include_directories = depset(inputs.local_quote_include_paths),
        include_directories = depset(inputs.local_include_paths),
        preprocessor_defines = depset(inputs.local_defines + inputs.defines),
        user_compile_flags = ctx.attr.copts,
        use_pic = use_pic,
    )

    host_args = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
        variables = host_compile_variables,
    )

    host_env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
        variables = host_compile_variables,
    )

    cuda_features = cuda_common.configure_features(
        ctx = ctx,
        cuda_toolchain = cuda_toolchain,
        requested_features = device_features.requested_features,
        unsupported_features = device_features.unsupported_features,
    )

    objs = []
    nvcc_path = cuda_common.get_nvcc_tool_path(cuda_toolchain)

    for src in inputs.source_files:
        obj = ctx.actions.declare_file("_objs/" + ctx.attr.name + "/" + src.basename.rpartition(".")[0] + ".pic.o" if use_pic else ".o")
        objs.append(obj)
        cuda_compile_variables = cuda_common.create_compile_variables(
            source_file = src,
            output_file = obj,
            host_compiler_executable = host_compiler_path,
            host_compiler_arguments = host_args,
            gpu_arch = ctx.attr.gpu_arch,
            gpu_codes = ctx.attr.gpu_codes,
            max_reg_count = ctx.attr.max_reg_count,
        )
        cuda_compile_args = ctx.actions.args().add_all(
            cuda_common.get_memory_inefficient_command_line(
                cuda_toolchain = cuda_toolchain,
                action_name = CUDA_ACTION_NAMES.compile,
                feature_configuration = cuda_features,
                variables = cuda_compile_variables,
            ) + ctx.attr.dcopts
        )
        ctx.actions.run(
            executable = nvcc_path,
            arguments = [cuda_compile_args],
            env = host_env,
            inputs = depset(
                [src] + inputs.private_header_files + inputs.public_header_files,
                transitive = [cc_toolchain.all_files, cuda_toolchain.tools],
            ),
            outputs = [obj],
            mnemonic = "Compiling",
            use_default_shell_env = True,
        )

    # Create CudaInfo
    cuda_info = CudaInfo(
        linking_context = cuda_common.create_linking_context(
            object_files = objs + inputs.object_files,
            static_libraries = inputs.static_inputs,
            dynamic_libraries = inputs.dynamic_inputs,
        )
    )

    if objs:
        device_obj = ctx.actions.declare_file("_objs/" + ctx.attr.name + "/" + ctx.attr.name + ".gpu.pic.o" if use_pic else ".gpu.o")
        cuda_link_variables = cuda_common.create_link_variables(
            host_compiler_executable = host_compiler_path,
            host_compiler_arguments = host_args,
            objects = objs + inputs.object_files,
            static_libraries = inputs.static_inputs,
            shared_libraries = inputs.dynamic_inputs,
            output_file = device_obj,
        )
        cuda_link_args = ctx.actions.args().add_all(
            cuda_common.get_memory_inefficient_command_line(
                cuda_toolchain = cuda_toolchain,
                action_name = CUDA_ACTION_NAMES.link,
                feature_configuration = cuda_features,
                variables = cuda_link_variables,
            ) + ctx.attr.dlinkopts
        )
        ctx.actions.run(
            executable = nvcc_path,
            arguments = [cuda_link_args],
            env = host_env,
            inputs = depset(
                objs + inputs.object_files + inputs.static_inputs + inputs.dynamic_inputs,
                transitive = [cc_toolchain.all_files, cuda_toolchain.tools],
            ),
            outputs = [device_obj],
            mnemonic = "LinkingDeviceCode",
            use_default_shell_env = True,
        )
        objs.append(device_obj)

    # Create compilation context for CcInfo
    compilation_context = cc_common.create_compilation_context(
        headers = depset(inputs.public_header_files),
        system_includes = depset(inputs.system_include_paths),
        includes = depset(inputs.include_paths),
        quote_includes = depset(inputs.quote_include_paths),
        defines = depset(inputs.defines),
        local_defines = depset(inputs.local_defines),
    )

    libraries_to_link = []

    # Link toolchain libraries
    for lib in cuda_toolchain.libraries:
        if is_static_input(lib):
            libraries_to_link.append(
                cc_common.create_library_to_link(
                    actions = ctx.actions,
                    feature_configuration = feature_configuration,
                    cc_toolchain = cc_toolchain,
                    static_library = lib,
                    alwayslink = ctx.attr.alwayslink,
                )
            )
        else:
            libraries_to_link.append(
                cc_common.create_library_to_link(
                    actions = ctx.actions,
                    feature_configuration = feature_configuration,
                    cc_toolchain = cc_toolchain,
                    dynamic_library = lib,
                    alwayslink = ctx.attr.alwayslink,
                )
            )
    # Link static libs from src
    for lib in inputs.static_inputs:
        libraries_to_link.append(
            cc_common.create_library_to_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                static_library = lib,
                alwayslink = ctx.attr.alwayslink,
            )
        )
    # Link shared libs from src
    for lib in inputs.dynamic_inputs:
        libraries_to_link.append(
            cc_common.create_library_to_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                dynamic_library = lib,
                alwayslink = ctx.attr.alwayslink,
            )
        )
    # Create linking context for dependencies
    dep_linker_input = cc_common.create_linker_input(
        owner = ctx.label,
        libraries = depset(libraries_to_link)
    )
    dep_linking_context = cc_common.create_linking_context(
        linker_inputs = depset([dep_linker_input])
    )

    # Create linking context for CcInfo
    compilation_outputs = cc_common.create_compilation_outputs(
        objects = depset(objs + inputs.object_files) if not use_pic else depset(),
        pic_objects = depset(objs + inputs.object_files) if use_pic else depset(),
    )

    linking_context, linking_output = cc_common.create_linking_context_from_compilation_outputs(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        compilation_outputs = compilation_outputs,
        user_link_flags = ctx.attr.linkopts,
        linking_contexts = [dep_linking_context],
        name = ctx.attr.name,
        alwayslink = ctx.attr.alwayslink,
        disallow_dynamic_library = ctx.attr.linkstatic,
    )

    # Create merged CcInfo
    cc_info = cc_common.merge_cc_infos(cc_infos = [
        CcInfo(compilation_context = compilation_context, linking_context = linking_context),
    ] + [dep[CcInfo] for dep in ctx.attr.deps])

    # Outputs
    output_files = []
    if linking_output.library_to_link != None:
        if linking_output.library_to_link.static_library != None:
            output_files.append(linking_output.library_to_link.static_library)
        if linking_output.library_to_link.pic_static_library != None:
            output_files.append(linking_output.library_to_link.pic_static_library)
        if linking_output.library_to_link.interface_library != None:
            output_files.append(linking_output.library_to_link.interface_library)
        if linking_output.library_to_link.dynamic_library != None:
            output_files.append(linking_output.library_to_link.dynamic_library)
        for obj in linking_output.library_to_link.objects:
            output_files.append(obj)
        for obj in linking_output.library_to_link.pic_objects:
            output_files.append(obj)

    return [
        DefaultInfo(files = depset(output_files)),
        cc_info,
        cuda_info,
    ]

cuda_library = rule(
    implementation = _cuda_library_impl,
    attrs = {
        "_cc_toolchain": attr.label(
            default = Label("@rules_cc//cc:current_cc_toolchain"),
            doc = "Host compiler",
        ),
        "srcs": attr.label_list(
            doc = "The list of C and C++ files that are processed to create the target. " + \
            "These are C/C++ source and header files, either non-generated (normal source code) or generated.",
            default = [],
            allow_files = True,
        ),
        "deps": attr.label_list(
            doc = "The list of other libraries to be linked in to the binary target.",
            default = [],
            allow_files = True,
        ),
        "hdrs": attr.label_list(
            doc = "The list of header files published by this library to be directly included by sources in dependent rules.",
            default = [],
            allow_files = True,
        ),
        "alwayslink": attr.bool(
            doc = "If True, any binary that depends (directly or indirectly) on this C++ library will link in all the object files for the files listed in srcs, " + \
            "even if some contain no symbols referenced by the binary",
            default = False,
        ),
        "copts": attr.string_list(
            doc = "Add these options to the host C++ compilation command. Subject to 'Make variable' substitution and Bourne shell tokenization.",
            default = [],
        ),
        "dcopts": attr.string_list(
            doc = "Add these options to the nvcc compilation command. Subject to 'Make variable' substitution and Bourne shell tokenization.",
            default = [],
        ),
        "defines": attr.string_list(
            doc = "List of defines to add to the compile line. Subject to 'Make variable' substitution and Bourne shell tokenization. " + \
            "Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line to this target, " + \
            "as well as to every rule that depends on it.",
            default = [],
        ),
        "include_prefix": attr.string(
            doc = "The prefix to add to the paths of the headers of this rule.",
            default = "",
        ),
        "includes": attr.string_list(
            doc = "List of include dirs to be added to the compile line.",
            default = [],
        ),
        "linkopts": attr.string_list(
            doc = "Add these flags to the host C++ linker command. Subject to 'Make variable' substitution, Bourne shell tokenization and label expansion.",
            default = [],
        ),
        "dlinkopts": attr.string_list(
            doc = "Add these flags to the nvcc linker command. Subject to 'Make variable' substitution, Bourne shell tokenization and label expansion.",
            default = [],
        ),
        "linkstatic": attr.bool(
            doc = "If linkstatic=True only static linking is allowed, so no .so will be produced.",
            default = False,
        ),
        "local_defines": attr.string_list(
            doc = "List of defines to add to the compile line. Subject to 'Make variable' substitution and Bourne shell tokenization.",
            default = [],
        ),
        "strip_include_prefix": attr.string(
            doc = "The prefix to strip from the paths of the headers of this rule.",
            default = "",
        ),
        "host_features": attr.string_list(
            doc = "The list of features to enable or disable for host compiler.",
            default = [],
        ),
        "gpu_arch": attr.string(
            doc = "Specify the name of the class of NVIDIA virtual GPU architecture for which the CUDA input files must be compiled.",
            default = "",
        ),
        "gpu_codes": attr.string_list(
            doc = "Specify the name of the NVIDIA GPU to assemble and optimize PTX for.",
            default = [],
        ),
        "max_reg_count": attr.int(
            doc = "Specify the maximum amount of registers that GPU functions can use.",
            default = 0,
        ),
    },
    toolchains = [
        "@rules_cuda//:toolchain_type",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
    provides = [CcInfo, CudaInfo],
    incompatible_use_toolchain_transition = True,
    fragments = ["cpp"],
)
