# Quote - Pull Quote

Create a pull quote

## Props

- `textJustification` - string, changes the horizontal alignment of the component
- `inverTextColor` - boolean, true will turn the text light. false turns the text dark.
- `text` - string, text to display in quote
- `Citation` - Displays reference to quote in smaller text below quote

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details

## Dev Details

- "" quotes and other special characters require `withKnobs({htmlEscape: false})`.
