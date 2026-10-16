using System;
using System.Collections.Generic;
using QtSharp.Api;

namespace QtSharp.Charts.Tests
{
    /// <summary>
    /// The ported Qt examples, and the one place that maps a name to one of them. QtSharp's own
    /// conformance suite works the same way: the list comes from the library, so a new example is
    /// covered as soon as it is registered here.
    /// </summary>
    public static class ChartsDemos
    {
        static readonly (string Name, Func<QApplication, int> Run)[] Runners =
        {
            ("splinechart", SplineChart.Run),
            ("linechart", LineChart.Run),
        };

        public static IReadOnlyList<string> Names
        {
            get
            {
                var names = new List<string>();
                foreach (var runner in Runners)
                    names.Add(runner.Name);
                return names;
            }
        }

        public static string Usage
        {
            get
            {
                var text = new System.Text.StringBuilder();
                text.AppendLine("Qt Charts examples ported from Qt's own examples/charts:");
                foreach (var runner in Runners)
                    text.AppendLine("    " + runner.Name);
                return text.ToString();
            }
        }

        /// <summary>Runs one of them, or reports that the name is unknown.</summary>
        public static bool TryRun(string name, QApplication app, out int exitCode)
        {
            foreach (var runner in Runners)
            {
                if (runner.Name != name)
                    continue;
                exitCode = runner.Run(app);
                return true;
            }
            exitCode = 0;
            return false;
        }
    }
}
