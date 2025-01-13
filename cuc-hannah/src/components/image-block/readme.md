# ImageBlock

The component that gives an image block qualities

## Props

- `image` - object, requires `"type": "titan-image"`, `titanId` and `renditions` array. Publisher uses the `titanId` to pull the rest of the information. Object also can include `imageAlignment`, a string that changes the position of the image and `altText` which is string used for accessibility purposes as the `alt` attribute on the image tag
- `aspectRatio` - string, changes the height and width ratios for the image. Is defaulted to "16x9"
- `mobileAspectRatio` - string, changes the height and width ratio specifically for mobile devices.
- `borderRadius` - string, the border radius for the image
- `variant` - string, changes the style of the closest container to the image
- `pageGlobals` - Look at the comment for the `pageGlobals` variable in the component [index.js](/src/components/index.js) file

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details

## Dev Details

- Publisher marks this as depreciated to use by itself. We only use it to give height to Titan Images
- Caption, citation and other properties no longer work and are not listed above.
