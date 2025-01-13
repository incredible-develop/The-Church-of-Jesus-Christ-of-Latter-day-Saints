# Bold Display

Creates a display that houses bold text and a button to be used in CTAs and similar components.

## Props

- `heading` - string, the large bold text for the component
- `miniText` - string, small text that goes under the heading
- `fontFamily` - string, the font family for the heading
- `contentAlign` - string, changes the flex justification and alignment to move the content
- `color` - string, changes the color of the text
- `includeBtn` - boolean, when `true` a button will go above the heading
- `btnLabel` - string, the label for the button. When include button is `true` and `btnLabel` is not present, it will render a "play" icon instead of a primary button.
- `miniTextIcon` - string, will add an icon to the end of the miniText. Right now the only options are `"" || "play" || "chevron-right"`.
- `playIconAriaLabel` - string, will be the aria label for the button when no `btnLabel` is present
- `overlay` - boolean, adds an overlay between the text and background
- `maxLines` - number, sets the max number of lines displayed when in Mobile view
- `maxLinesDesktop` - number, sets the max number of lines displayed when in Desktop view
- `fitContainer` - boolean, when `true` the component will be `position: absolute;` and take up the whole area of the parent component.

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details
