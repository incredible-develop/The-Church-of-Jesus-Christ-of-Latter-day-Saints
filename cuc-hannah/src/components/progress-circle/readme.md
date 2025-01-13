# Progress Circle

A circle where the border indicates progress. Automatically updates with the progress of the remote page if a wrapping `a` points to a page that has logged progress in `localStorage`. See drawers component for more details.

## Props

- `percent` - string, What percentage done the circle should be, represented as a number only, no `%` sign
- `color` - string, the color to display the progress circle in. Not currently exposed for publisher selection, but potentially in the future
