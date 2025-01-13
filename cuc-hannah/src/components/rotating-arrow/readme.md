# Rotating Arrow

Arrow that rotates when clicked

## Props

- `label` - string, label that appears next to the rotating arrow.
- `alignment` - string, alignment of the arrow with the arrow. Can be vertically aligned or horizontally aligned.
- `iconType` - string, type of arrow. Can be a "condensed" arrow or a "normal" arrow.
- `cssClasses` - array`<string>`, css classes that can be passed from a parent component. You can include postcss classes like `styles.autocomplete` because postcss classes return strings ("parent-component-autocomplete").
- `htmlAttrs` - array`<string>`, a list of HTML attributes that can be passed to the button element. The attribute and value should be included in the same string. For example: `['autocomplete-options', 'access-key="o"']`
