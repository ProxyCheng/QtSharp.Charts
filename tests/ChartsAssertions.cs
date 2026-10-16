using QtSharp.Api;

namespace QtSharp.Charts.Tests
{
    /// <summary>What the ported examples assert on, so each one does not invent its own.</summary>
    public static class ChartsAssertions
    {
        /// <summary>
        /// How much ink the plot carries, sampled every other pixel: the series colour is dark on a
        /// chart's white background, so this is "the chart drew something" without depending on the
        /// exact pixels a font or a renderer would produce.
        /// </summary>
        public static int InkSamples(QPixmap rendered)
        {
            if (rendered == null)
                return 0;
            using var image = rendered.ToImage();
            int ink = 0;
            for (int y = 0; y < image.Height(); y += 2)
                for (int x = 0; x < image.Width(); x += 2)
                {
                    uint pixel = image.Pixel(x, y);
                    if ((pixel & 0xFF) < 200)
                        ink++;
                }
            return ink;
        }
    }
}
