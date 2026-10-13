#!/usr/bin/env python3
"""Patch haxebullet/hl/bullet.cpp so its hand-written btIntArray/btFloatArray
section matches what the generated Haxe bindings expect.

Usage: python3 fix_bullet_cpp.py /path/to/haxebullet/hl/bullet.cpp
Makes a backup (bullet.cpp.orig) the first time it runs. Safe to run twice.
"""
import os
import shutil
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "bullet.cpp"
if not os.path.exists(path + ".orig"):
    shutil.copyfile(path, path + ".orig")

with open(path) as f:
    lines = f.read().split("\n")

out = []
for line in lines:
    # 1) the custom arrays take/return 32-bit ints in the C code, so register
    #    them as _I32 instead of _I16
    if "DEFINE_PRIM" in line and ("btIntArray" in line or "btFloatArray" in line):
        line = line.replace("_I16", "_I32")
    out.append(line)
    # 2) add the missing raw setters right after the existing raw getters
    for cls, ctype in (("btIntArray", "int"), ("btFloatArray", "float")):
        marker = "DEFINE_PRIM(_BYTES, %s_get_raw, _IDL);" % cls
        setter = "%s_set_raw" % cls
        if line.strip() == marker and not any(setter in l for l in lines):
            out.extend([
                "",
                "HL_PRIM %s* HL_NAME(%s)(_ref(%s)* _this, %s* value) {" % (ctype, setter, cls, ctype),
                "\t_unref(_this)->raw = value;",
                "\treturn value;",
                "}",
                "DEFINE_PRIM(_BYTES, %s, _IDL _BYTES);" % setter,
            ])

with open(path, "w") as f:
    f.write("\n".join(out))
print("patched", path)
