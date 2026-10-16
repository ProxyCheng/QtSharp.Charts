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

and copy the two files into `src\`. The two files and the model are checked in together, so a
regeneration is a reviewable diff; CI builds and runs them rather than regenerating them, because
that would mean putting clang and the whole Qt kit on the runner.

## Tests

`tests/` is a conformance suite: Qt's own examples ported to C#, run one process per example, each
asserting on **what the binding produced** rather than on a screenshot, so the suite works on a
machine with no display. Every run prints `[PASS]`/`[FAIL]` per assertion and exits non-zero if any
failed.

```
ChartsTests --list              # the example names, one per line
ChartsTests                     # the usage table
ChartsTests piechart            # run one
ChartsTests --list | % { ... }  # what CI does
```

| Example | From |
|---|---|
| `splinechart`, `linechart` | Qt's stand-alone examples of the same name |
| `barchart`, `stackedbarchart`, `lineandbar` | `chartsgallery` BarWidget / BarStackedWidget / LineAndBarWidget |
| `piechart`, `donutchart`, `nesteddonuts` | PieWidget / DonutWidget / NestedDonutsWidget |
| `scatterchart`, `areachart` | ScatterWidget / AreaWidget |
| `datetimeaxis`, `logvalueaxis`, `multiaxis` | DateTimeAxisWidget / LogAxisWidget / MultiAxisWidget |
| `polarchart` | PolarChartWidget |
| `legend`, `legendmarkers`, `selectedbar` | LegendWidget / LegendMarkersWidget / SelectedBarWidget |
| `dynamicspline`, `chartthemes`, `zoomlinechart` | DynamicSplineWidget / ThemeWidget / the zoomlinechart example |

In Qt 6.11 most of the stand-alone widget examples were folded into `examples/charts/chartsgallery`,
one widget per chart type - so the name without a suffix is the gallery widget it came from.

### What the port had to work around

These are the places where the binding's shape differs from the C++ the examples are written in.
They are worth knowing before you write your own charts code:

- **`chart.animationOptions()` and `series.markerShape()` are lower case.** When a `Q_PROPERTY`'s
  name collides with a nested enum of the same class (`QChart::AnimationOptions`,
  `QScatterSeries::MarkerShape`), the generated PascalCase property is dropped and the accessor keeps
  its C++ spelling. `SetAnimationOptions(...)` / `SetMarkerShape(...)` are unaffected.
- **A legend is shown and hidden through `AsQGraphicsItem()`.** `QLegend` derives from
  `QGraphicsWidget`, which the core binding models as a `QObject` plus a `QGraphicsItem` *view*
  rather than as an inheritance chain, so `legend->hide()` becomes
  `legend.AsQGraphicsItem().Hide()` - see `ChartsAssertions.HideLegend`.
- **`chart->axes(...).first()->setRange(0, 20)` goes through `QValueAxis`.** `QAbstractAxis::setRange`
  takes `QVariant`s (the axis may be any kind); the `qreal` overload the examples call belongs to
  `QValueAxis`, so the axis has to be viewed as one - see `ChartsAssertions.ValueAxis`.
- **`QPieSlice::percentage()` is a fraction, not a percentage** (2/15 is `0.1333`), and
  `QCategoryAxis::append(label, endValue)` closes a band at that value, so the *next* band starts
  there.
- **`QLegend` has no `setGeometry`.** The geometry spin boxes of the LegendWidget example are left
  out for that reason; the rest of the example is ported.
- **zoomlinechart's gesture half is not ported.** The example's `Chart` subclass handles pan and
  pinch in `sceneEvent()`/`gestureEvent()`; neither is part of the bound surface. The rubber band and
  the keyboard controls are, and the managed `ChartView` subclass proves the module's classes can be
  overridden from C#.
