# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# ExecEnvInfo provider fields and whether the field is required.
_FIELDS = {
    "design": ("attr.design", True),
    "exec_env": ("attr.exec_env", False),
    "lib": ("attr.lib", True),
    "linker_script": ("attr.linker_script", False),
    "rsa_key": ("attr.rsa_key", False),
    "spx_key": ("attr.spx_key", False),
    "manifest": ("file.manifest", False),
    "rom": ("file.rom", False),
    "otp": ("file.otp", False),
    "bitstream": ("file.bitstream", False),
    "args": ("attr.args", False),
    "test_cmd": ("attr.test_cmd", False),
    "param": ("attr.param", False),
    "data": ("attr.data", False),
    #"extract_sw_logs": ("executable.extract_sw_logs", False),
    "_opentitantool": ("executable._opentitantool", True),
}

ExecEnvInfo = provider(
    doc = "Execution Environment Info",
)

_unbound = struct(unbound = True)

def getattr_path(obj, path, defval = _unbound):
    """Gets a named item from an object hierarchy.

    This function is like `getattr`, but it walks an object path instead of
    retrieving a single item.

    Args:
      obj: The root of an object hierarchy.
      path: An object path to the desired attribute (e.g. attr.srcs).
      defval: An optional default value if the item is not found.
    Returns:
      The requested object or defval.
    """
    path = path.split(".")
    item = path.pop(-1)
    for p in path:
        obj = getattr(obj, p, None)
    val = getattr(obj, item, defval)
    if val == _unbound:
        fail("Item '{}' not found in object".format(path))
    return val

def exec_env_as_dict(ctx):
    """Initialize provider fields, possibly inheriting from a base provider.

    This function will return a dict of ExecEnvInfo provider fields, preferring
    the values in the `ctx` object and falling back to the base provider (if given).

    Args:
      ctx: The rule context.
    Returns:
      dict: A dict of items to initialize in the ExecEnvInfo provider.
    """
    base = ctx.attr.base
    if base:
        base = base[ExecEnvInfo]
    result = {}
    for field, (path, required) in _FIELDS.items():
        val = getattr_path(ctx, path)
        if not val and base:
            # If the value doesn't exist in the context object, get the value
            # from the base provider (if present).
            val = getattr(base, field)

        if required and not val:
            fail("No value for required field {} in {}".format(field, ctx.attr.name))
        result[field] = val
    return result

def exec_env_common_attrs(**kwargs):
    """Common attributes for rules creating ExecEnvInfo providers."""
    return {
        "base": attr.label(
            default = kwargs.get("base"),
            providers = [ExecEnvInfo],
            doc = "Base execution environment used to initialize this environment",
        ),
        "design": attr.string(
            default = kwargs.get("design", ""),
            doc = "Top-level hardware design name (e.g. `earlgrey`)",
        ),
        "exec_env": attr.string(
            default = kwargs.get("exec_env", "{name}"),
            doc = "Name of the execution environment (e.g. `fpga_cw310`)",
        ),
        "lib": attr.label(
            default = kwargs.get("lib"),
            providers = [CcInfo],
            doc = "Library providing environment-specific constants",
        ),
        "linker_script": attr.label(
            default = kwargs.get("linker_script"),
            providers = [CcInfo],
            doc = "Library providing the environment-specific linker script",
        ),
        "rsa_key": attr.label_keyed_string_dict(
            default = kwargs.get("rsa_key", {}),
            allow_files = True,
            doc = "RSA key to sign images",
        ),
        "spx_key": attr.label_keyed_string_dict(
            default = kwargs.get("spx_key", {}),
            allow_files = True,
            doc = "SPX key to sign images",
        ),
        "manifest": attr.label(
            default = kwargs.get("manifest"),
            allow_single_file = True,
            doc = "Manifest used when signing images",
        ),
        "rom": attr.label(
            default = kwargs.get("rom"),
            allow_single_file = True,
            doc = "ROM image to use in this environment",
        ),
        "otp": attr.label(
            default = kwargs.get("otp"),
            allow_single_file = True,
            doc = "OTP image to use in this environment",
        ),
        "bitstream": attr.label(
            default = kwargs.get("bitstream"),
            allow_single_file = True,
            doc = "Bitstream to use in this environment",
        ),
        "args": attr.string_list(
            default = kwargs.get("args", []),
            doc = "Pre-test_cmd arguments in this environment",
        ),
        "test_cmd": attr.string(
            default = kwargs.get("test_cmd", ""),
            doc = "Command to execute a test in this environment",
        ),
        "param": attr.string_dict(
            default = kwargs.get("param", {}),
            doc = "Additional parameters for this environment or test",
        ),
        "data": attr.label_list(
            default = kwargs.get("data", []),
            allow_files = True,
            doc = "Additonal dependencies for this environment or test",
        ),
        # FIXME(cfrantz): This should work, but when we try to use this executable
        # in the opentitan_{binary,test} rules, the runfiles aren't present.
        # Somehow, bazel ends up building only the py_binary launcher script but
        # doesn't construct the runfiles directory.  If we place this label in the
        # opentitan_{binary,test} attrs, then the runfiles get created.
        #
        # Talk to the bazel team and determine whether or not this is a bazel bug.
        #"extract_sw_logs": attr.label(
        #    #default = kwargs.get("extract_sw_logs"),
        #    default = "//util/device_sw_utils:extract_sw_logs_db",
        #    executable = True,
        #    cfg = "exec",
        #),
        "_opentitantool": attr.label(
            default = "//sw/host/opentitantool:opentitantool",
            executable = True,
            cfg = "exec",
        ),
    }
