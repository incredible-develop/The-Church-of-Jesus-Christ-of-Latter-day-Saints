# Caption Block

Description used under an image or video player that can contain a heading, caption, citation, download link, button, and action bar

## Props

- `heading` - string, heading
- `caption` - string, caption
- `citation` - string, citation
- `btn` - object, button caption and citation
  - `label` - string, the text inside the button
  - `link` - object
    - `URL` - string, the url that opens when clicking the link. urls with the same domain will open in the same window. urls outside the domain open in a new tab
  - `variant`- string, changes style properties of the button
  - `colorVariant` - string, changes additional color properties of the button
  - `icon` - string, the name of the icon. Icon will go before the label text
- `limitTextWidth` - boolean, true sets the width of the text content 60% rather than expanding the full width of the grid
- `downloadLabel` - string, label for the download button
- `invertTextColor` - string, specifies whether text/icons should be white
- `textAlign` - string, changes the alignment of the heading, caption and citation

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details
