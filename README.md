> # ⚰️ This repository has moved
>
> **QtSharp.Charts is now developed, tested and released in the main
> [ProxyCheng/QtSharp](https://github.com/ProxyCheng/QtSharp) repository.**
>
> QtSharp follows PyQt6's package shape, and all binding packages are built from that one
> repository: `QtSharp.Api` (ten base modules), `QtSharp.Runtime`, `QtSharp.Qt6`,
> `QtSharp.Charts` + `QtSharp.Charts.Qt6`, and `QtSharp.Qt3D` + `QtSharp.Qt3D.Qt6`.
> The Charts model, the assembly, the native glue and the 38 official Qt Charts examples
> (570 assertions) live there and run in its gate, CI and release workflows.
>
> This repository is **archived and read-only**. Do not open issues or pull requests here; use
> the main repository instead.
>
> Install the package from a QtSharp release:
>
> ```xml
> <ItemGroup>
>   <PackageReference Include="QtSharp.Charts" Version="0.1.0" />
> </ItemGroup>
> ```
>
> - [Charts package README](https://github.com/ProxyCheng/QtSharp/blob/master/nuget/QtSharp.Charts/README.md)
> - [Module and package architecture](https://github.com/ProxyCheng/QtSharp/blob/master/docs/module-architecture.md)
> - [Qt Charts examples ported as conformance tests](https://github.com/ProxyCheng/QtSharp/tree/master/demos.charts)
>
> Qt Charts is GPLv3-or-commercial, not LGPL; keeping it in its own package is why it is not
> part of `QtSharp.Api`. See the main repository's `NOTICE.md` and Qt's own terms.

---

# QtSharp.Charts (archived)

This repository was the original standalone home of the Qt Charts extension for QtSharp. Its
model, native glue, package and the ported official examples have moved into
[ProxyCheng/QtSharp](https://github.com/ProxyCheng/QtSharp); the history here is kept for
reference only. The GitHub Releases and package files published from this repository remain
available, but no further versions will be produced here.
