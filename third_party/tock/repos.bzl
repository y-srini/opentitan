# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("@//rules:repo.bzl", "bare_repository", "http_archive_or_local")
load("@//rules:rust.bzl", "crate_build")
load("@python3//:defs.bzl", "interpreter")
load("@rules_python//python:pip.bzl", "pip_install")

# Exports the kernel_layout.ld file so it can be used in opentitan rules.
_KERNEL_LAYOUT = """
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "kernel_layout",
    srcs = ["kernel_layout.ld"],
)
"""

# Exports the libtock_layout.ld file so it can be used in opentitan rules.
_LIBTOCK_LAYOUT = """
filegroup(
    name = "layout",
    srcs = ["libtock_layout.ld"],
)
"""

# Exports the earlgrey-cw310 crate sources so we can build a local copy
# of the upstream kernel.
_EARLGREY_CW310_BUILD = """
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "kernel_srcs",
    srcs = glob(["**/*.rs"]),
)
"""

def tock_repos(tock = None, libtock = None, elf2tab = None):
    bare_repository(
        name = "tock",
        local = tock,
        strip_prefix = "tock-1a111a3e748815117b0ef939ab730b31d77a409d",
        url = "https://github.com/tock/tock/archive/1a111a3e748815117b0ef939ab730b31d77a409d.tar.gz",
        sha256 = "9b146f28dea14e51e77736e781745dfd140f71afb963e35b52795edf7e72b0d3",
        additional_files_content = {
            "BUILD": """exports_files(glob(["**"]))""",
            "arch/riscv/BUILD": crate_build(
                name = "riscv",
                deps = [
                    "//kernel",
                    "//libraries/tock-register-interface:tock-registers",
                    "//libraries/riscv-csr",
                ],
            ),
            "arch/rv32i/BUILD": crate_build(
                name = "rv32i",
                deps = [
                    "//arch/riscv",
                    "//kernel",
                    "//libraries/tock-register-interface:tock-registers",
                    "//libraries/riscv-csr",
                ],
            ),
            "boards/BUILD": _KERNEL_LAYOUT,
            "boards/components/BUILD": crate_build(
                name = "components",
                deps = [
                    "//kernel",
                    "//capsules/core:capsules-core",
                    "//capsules/extra:capsules-extra",
                ],
            ),
            "boards/opentitan/earlgrey-cw310/BUILD": _EARLGREY_CW310_BUILD,
            "capsules/aes_gcm/BUILD": crate_build(
                name = "capsules-aes-gcm",
                deps = [
                    "//kernel",
                    "//libraries/enum_primitive",
                    "//libraries/tickv",
                    "@tock_index//:ghash",
                ],
            ),
            "capsules/core/BUILD": crate_build(
                name = "capsules-core",
                deps = [
                    "//kernel",
                    "//libraries/enum_primitive",
                    "//libraries/tickv",
                ],
            ),
            "capsules/extra/BUILD": crate_build(
                name = "capsules-extra",
                deps = [
                    "//kernel",
                    "//libraries/enum_primitive",
                    "//libraries/tickv",
                    "//capsules/core:capsules-core",
                ],
            ),
            "chips/earlgrey/BUILD": crate_build(
                name = "earlgrey",
                deps = [
                    "//chips/lowrisc",
                    "//arch/rv32i",
                    "//kernel",
                ],
            ),
            "chips/lowrisc/BUILD": crate_build(
                name = "lowrisc",
                deps = [
                    "//arch/rv32i",
                    "//kernel",
                ],
            ),
            "libraries/enum_primitive/BUILD": crate_build(
                name = "enum_primitive",
            ),
            "libraries/riscv-csr/BUILD": crate_build(
                name = "riscv-csr",
                deps = [
                    "//libraries/tock-register-interface:tock-registers",
                ],
            ),
            "libraries/tickv/BUILD": crate_build(
                name = "tickv",
            ),
            "libraries/tock-cells/BUILD": crate_build(
                name = "tock-cells",
            ),
            "libraries/tock-tbf/BUILD": crate_build(
                name = "tock-tbf",
            ),
            "libraries/tock-register-interface/BUILD": crate_build(
                name = "tock-registers",
                crate_features = [
                    "default",
                    "register_types",
                ],
            ),
            "kernel/BUILD": crate_build(
                name = "kernel",
                deps = [
                    "//libraries/tock-register-interface:tock-registers",
                    "//libraries/tock-cells",
                    "//libraries/tock-tbf",
                ],
            ),
        },
    )

    bare_repository(
        name = "libtock",
        local = libtock,
        strip_prefix = "libtock-rs-49779965a9575b03ef96df703bd2fc4b2f080a0c",
        url = "https://github.com/tock/libtock-rs/archive/49779965a9575b03ef96df703bd2fc4b2f080a0c.tar.gz",
        sha256 = "51355f3fd2361b10d37c7af0af0635ecb9645c1f03a19024f9f8427471d31971",
        additional_files_content = {
            "BUILD": crate_build(
                name = "libtock",
                deps = [
                    "//apis/adc",
                    "//apis/air_quality",
                    "//apis/alarm",
                    "//apis/ambient_light",
                    "//apis/buttons",
                    "//apis/buzzer",
                    "//apis/console",
                    "//apis/gpio",
                    "//apis/leds",
                    "//apis/low_level_debug",
                    "//apis/ninedof",
                    "//apis/proximity",
                    "//apis/sound_pressure",
                    "//apis/temperature",
                    "//panic_handlers/debug_panic",
                    "//platform",
                    "//runtime",
                ],
            ),
            "apis/adc/BUILD": crate_build(
                name = "adc",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/air_quality/BUILD": crate_build(
                name = "air_quality",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/alarm/BUILD": crate_build(
                name = "alarm",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/ambient_light/BUILD": crate_build(
                name = "ambient_light",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/buttons/BUILD": crate_build(
                name = "buttons",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/buzzer/BUILD": crate_build(
                name = "buzzer",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/console/BUILD": crate_build(
                name = "console",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/gpio/BUILD": crate_build(
                name = "gpio",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/leds/BUILD": crate_build(
                name = "leds",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/low_level_debug/BUILD": crate_build(
                name = "low_level_debug",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/ninedof/BUILD": crate_build(
                name = "ninedof",
                crate_name = "libtock_{name}",
                deps = [
                    "//platform",
                    "@tock_index//:libm",
                ],
            ),
            "apis/proximity/BUILD": crate_build(
                name = "proximity",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/sound_pressure/BUILD": crate_build(
                name = "sound_pressure",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "apis/temperature/BUILD": crate_build(
                name = "temperature",
                crate_name = "libtock_{name}",
                deps = ["//platform"],
            ),
            "panic_handlers/debug_panic/BUILD": crate_build(
                name = "debug_panic",
                crate_name = "libtock_{name}",
                deps = [
                    "//apis/console",
                    "//apis/low_level_debug",
                    "//platform",
                    "//runtime",
                ],
            ),
            "panic_handlers/small_panic/BUILD": crate_build(
                name = "small_panic",
                crate_name = "libtock_{name}",
                deps = [
                    "//apis/low_level_debug",
                    "//platform",
                    "//runtime",
                ],
            ),
            "platform/BUILD": crate_build(
                name = "platform",
                crate_name = "libtock_{name}",
            ),
            "runtime/BUILD": crate_build(
                name = "runtime",
                crate_name = "libtock_{name}",
                crate_features = ["no_auto_layout"],
                deps = [
                    "//platform",
                ],
                additional_build_file_content = _LIBTOCK_LAYOUT,
            ),
        },
    )

    http_archive_or_local(
        name = "elf2tab",
        local = elf2tab,
        url = "https://github.com/tock/elf2tab/archive/ede1c658a3892d21b076fb2c9df6328ec4c9011e.tar.gz",
        sha256 = "350514dcd2711fb45fdd38087862055f6006638881d6c0866fadb346bb1b3be9",
        strip_prefix = "elf2tab-ede1c658a3892d21b076fb2c9df6328ec4c9011e",
        build_file = Label("//third_party/tock:BUILD.elf2tab.bazel"),
    )

    pip_install(
        name = "tockloader_deps",
        python_interpreter_target = interpreter,
        requirements = "//:third_party/tock/tockloader_requirements.txt",
    )
