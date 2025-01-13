# Max Lines

A CSS Variable driven class to cap the number of lines in an element.

This requires that a `--fontSize` `--lineHeight` and `--maxLines` CSS Variable be correctly set on some parent of this component. Without those the on the fly CSS `calc()` won't work. With those set, this should function through any `media-query` or `makeFit` based css changes.

If the content is less than the `--maxLines`, it will take up whatever height it needs to. If it is more than the `--maxLines`, it will set a `max-height` equivalent to the `font-size` and `line-height` of those lines and put a fade on the last visible line.

See the `.css` file for inline comments on how this works.

If you already have one or two wrappers around your content you can leverage them instead of having this component add even more wrappers but adding an attribute (not class) of `max-lines-wrapper` and `max-lines-fader` as appropriate. They will still inherit the CSS logic that leverages the CSS Variables.

## Props

- `content` - string, the content to put inside of the max lines
- `maxLines` - number, optional way to set the max number of lines on Mobile Mode so that it can potentially be set via LDSP instead of via component CSS if desired
- `maxLinesDesktop` - number, optional way to set the max number of lines on Desktop Mode so that it can potentially be set via LDSP instead of via component CSS if desired
