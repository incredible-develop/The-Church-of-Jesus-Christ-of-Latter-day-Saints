# Quote - Block Quote

Create a block quote

## Props

- `text` - string, text to display in quote
- `citation` - string, displays reference to quote in smaller text below quote. Publisher adds `<p>` tags.
- `image` - object, optional image. Requires `"type": "titan-image"`, `titanId` and `renditions` array. Publisher uses the `titanId` to pull the rest of the information.

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details
- `pageGlobals` - Look at the comment for the `pageGlobals` variable in the component [index.js](/src/components/index.js) file

## Dev Details

- "" quotes and other special characters require `withKnobs({htmlEscape: false})`.
