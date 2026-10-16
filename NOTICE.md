# Notices

`QtSharp.Charts` is released under the MIT License (see `LICENSE`). It is a *binding*, and it is
deliberately kept out of the core `QtSharp.Api` package because of what it binds:

- **Qt Charts is licensed under the GPLv3 or a commercial Qt license** - unlike qtbase, which is
  LGPLv3. Nothing here changes that: this package only makes the Qt Charts classes callable from C#.
- If you distribute a program that uses this package, **you are distributing Qt Charts**, and the
  GPLv3 applies to your program unless you hold a commercial Qt license. This is the same line
  PyQt6-Charts and PySide6-Addons draw, which is why they too are separate from their base packages.
- Qt itself is not included in this repository. The package copies the Qt Charts library from the
  kit you build against; obtain a compatible Qt distribution and comply with its license.

Nothing in this repository is legal advice - read the Qt licensing terms for your own distribution.
