# Make Fit

Script that will dynamically apply classes based upon comparing the size of one element to another

## Props

- `sizeClasses` - string, list of classes to apply to the element to modify styles
- `fitWithin` - element, the element that the target element needs to fit inside of. If the boundaries of the target element exceed that of the fitWithin element, a sizeClass will be applied. Defaults to `elem.parentElement`.
- `sync` - boolean, other makeFit elements that we want to all change sizes at the same time. These would usually be siblings
- `alsoAddClassTo` element, other elements that applicable sizeClasses should be added to. Sometimes the class is more helpful on a shared parent, this allows you to do that

## data- attributes

Because this uses classes, which can be obfuscated via Webpack, the component also allows them to be passed in via data- attributes so that the script will know the Webpacked name.

- `data-makeFit-sizeClasses` - same as `sizeClasses` above
