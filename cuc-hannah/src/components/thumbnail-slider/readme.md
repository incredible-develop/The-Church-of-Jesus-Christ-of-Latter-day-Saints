# Thumbnail Slider

A horizontal list of media items with horizontal scrolling and a selector. Data from the selected media item is retrieved by listening to a custom event.

## Props

- `outsetArrows` - boolean, allows the scrollable area of the component to fit to 100% on desktop and mobile and positions the arrows outside of its parent container.
- `invertTextColor` - boolean, true will make the text a lighter color and darken the hover color of the arrows
- `highlightColor` - string, the color of the thumbnail border when an item is selected
- `thumbnailBgColor` - string, the background color of the thumbnails
- `aspectRatio` - string, is currently hard coded, but could potentially be updated
- `galleryItems` - array, a list of media items
  - `image` - object, requires `"type": "titan-image"`, `titanId` and `renditions` array. Publisher uses the `titanId` to pull the rest of the information
  - `caption` - string, the text that goes below the image. It should be less than 5 or 10 words.
  - `icon` - string, the name of an icon from the "std" package
  - `galleryId` string, a unique id that will be added to the media item as `data-gallery-id=${galleryId}`. It can be retrieved when a user selects a media item via a custom event, "gallery-item-select". The value can be retrieved from another component by adding an eventListener and extracting the `galleryId` from the `detail` of the generated event object. See Dev Details.
  - `sliderWidth` - string, makes the width of the slider small, medium or large compared to its parent element _TODO: update when new layout is ready_
- `thumbnailShape` - string, select whether each thumbnail is square or circular
- `isNumbered` - boolean, when true the thumbnails will be numbered instead of having pictures
- `hideCaptions` - boolean, true will hide the captions on the thumbnails although captions will be used for aria-labels. So include the captions even if you aren't visibly using them for accessibility reasons.
- `selectFirstItem` - boolean, When the Inline Component Gallery is loaded - if true the first item will be selected, if false no item will be selected
- `bottomIsPadded` - boolean, Adds extra padding to the bottom of the component

## Dev Details

- To retrieve the `galleryId` that was selected, you will need to set up an event listener to _this component's outermost container_. This prevents mix-ups if multiple components are on the same page. In the browser.js of a parent component, you could add a script like this:

```javascript
parentComponent
  .querySelector('[data-type="thumbnail-slider"]')
  .addEventListener("gallery-item-select", e => {
    const selectedId = event.detail.galleryId;
    handleSelectedId(selectedId);
    // do stuff with the extracted galleryId
  });
```

- In storybook it is possible to select multiple items and select items while dragging. This is because the `init()` from browser.js is running multiple times. If you reload the frame and DON'T set the event listener or change the knobs, it will scroll and select as it will in production where the browser.js only runs one time.
