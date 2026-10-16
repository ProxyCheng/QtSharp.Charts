# QtSharp.Charts

Qt Charts for .NET, bound with [QtSharp](https://github.com/ProxyCheng/QtSharp).

It is an **extension module**: a separate assembly and a separate package that sits beside
`QtSharp.Api` rather than inside it, exactly the way `PyQt6-Charts` sits beside `PyQt6` and
`PySide6-Addons` beside `PySide6`.

```xml
<ItemGroup>
  <PackageReference Include="QtSharp.Api" Version="0.1.0" />
  <PackageReference Include="QtSharp.Charts" Version="0.1.0" />
</ItemGroup>
```

```csharp
using QtSharp.Api;
using QtSharp.Charts;

var series = new QSplineSeries();
series.SetName("spline");
series.Append(0.0, 6.0);
series.Append(3.0, 8.0);
series.Append(10.0, 5.0);

var chart = new QChart();
chart.AddSeries(series);
chart.SetTitle("Simple spline chart");
chart.CreateDefaultAxes();

var view = new QChartView(chart);
view.Resize(400, 300);
view.Show();
```

`QChart` derives from the core binding's `QGraphicsWidget` and `QChartView` from its
`QGraphicsView`, so a chart is a widget you can put in a layout like any other.

## Why it is a separate package

**Qt Charts is GPLv3-or-commercial, not LGPL.** Keeping it out of `QtSharp.Api` is what stops
everyone who uses the core binding from inheriting that license. See `NOTICE.md` - and read Qt's
own terms before you ship.

## What is bound

`QChart`, `QChartView`, `QPolarChart`; the series families (`QXYSeries`/`QLineSeries`/
`QSplineSeries`/`QScatterSeries`/`QAreaSeries`, the bar family with `QBarSet`, `QPieSeries` with
`QPieSlice`); the axes (`QValueAxis`, `QCategoryAxis`, `QBarCategoryAxis`, `QDateTimeAxis`,
`QLogValueAxis`); and the legend with its markers. 23 classes in all - the list is
`model/qtsharp.charts.json` (the checked-in API model) and the table in the core repository's
`gen/ApiModel.cs`.

## Building

Prerequisites are the ones QtSharp needs (Windows x64, .NET 10, a Visual Studio with C++ tools, and
a Qt 6.11 kit), plus **the Qt Charts module** in that kit: `include\QtCharts`, `lib\Qt6Charts.lib`
and `bin\Qt6Charts.dll`. QtSharp's `tools/build-qt-kit.ps1` fetches it with the rest of the kit.

```
# the core package this depends on, into packages\ (see nuget.config)
.\scripts\Fetch-Core.ps1

dotnet build src\QtSharp.Charts.csproj -c Release      # the managed binding
powershell -File build-native.ps1                      # the native glue
dotnet pack src\QtSharp.Charts.csproj -c Release -o out\packages
```

`native/QtSharpApiRuntime.h` is the ABI contract between generated glue and the core runtime (the
`QsApiDispatch` typedef the wrappers are built on). It is a copy of the one in the QtSharp
repository, pinned to the core package version this repository builds against - the same way the
generated files are pinned to the model.

`src/QtSharp.Charts.cs` and `src/QtSharp.Charts.native.cpp` are **generated and checked in**: the
generator lives in the QtSharp repository and needs clang, and there is no reason for this
repository to drag that in. To regenerate them, from a QtSharp clone:

```
qtgen extract2 model\qtsharp.charts.json --module charts
qtgen codegen  model\qtsharp.charts.json out\charts --module charts
```

and copy the two files into `src\`. `.github/workflows/ci.yml` checks that the checked-in files are
what the model says they should be.

## Tests

`tests/` ports Qt's own `examples/charts` to C# - `splinechart` to begin with - and asserts on what
the binding produced rather than on a screenshot: the points a series carries, the title, the axes
`createDefaultAxes()` built, the range set through `QValueAxis`, and the ink the chart actually
draws when it is rendered off-screen.
