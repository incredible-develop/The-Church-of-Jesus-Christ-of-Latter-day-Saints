import styles from "./styles.css";
import typographyStyles from "../typography/critical.css";
import icon from "../icon";
import imageBlock from "../image-block";
import color from "../color";
import { layoutInner, layoutOuter } from "components/layout";
import backgroundColor from "../background/styles.css";
import invertColors from "../invert-text-color";
import overlayClasses from "../overlay";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "thumbnail-slider");
};

export const component = (props) => {
  const {
    outsetArrows = true,
    invertTextColor,
    highlightColor = "Yellow25",
    thumbnailBgColor = "",
    aspectRatio = "1x1",
    thumbnailShape,
    isNumbered,
    hideCaptions,
    selectFirstItem = false,
    galleryItems,
    scrollLeft,
    scrollRight
  } = props;
  const arrow = (direction) =>
    `<button data-type="thumbnail-slider-arrow-container" class="${
      styles.arrow
    }" ${direction ? `aria-label="${direction}"` : ""}>${icon({
      name: "chevron-left"
    })}</button>`;
  // prettier-ignore
  return `
  <div data-type="thumbnail-slider" extra-css="overlay" class="${invertColors(invertTextColor)} ${invertTextColor ? styles.invertTextColor : ""}
   ${layoutOuter(props)}" data-select-first-item="${selectFirstItem}">
  <div class="${styles.thumbnailSlider} ${
  outsetArrows ? styles.outsetArrows : ""
} ${layoutInner(props)}">
    ${arrow(scrollLeft)}
    ${arrow(scrollRight)}
    <div role="tablist" data-type="thumbnail-slider-scrollable" skip-analytics class="${styles.scrollable} ${
  isNumbered ? styles.numbered : ""
}">
      ${galleryItems
    .map(
      (galleryItem, index) => `
      <button role="tab" id="tab-${galleryItem.galleryId}" aria-controls="${galleryItem.galleryId}" aria-selected="false" aria-label="${galleryItem.image.altText}" data-type="gallery-item" use-analytics data-gallery-id="${
  galleryItem.galleryId
}" class="${styles.galleryItem}" ${
  hideCaptions ? `aria-label="${galleryItem.caption}"` : ""
}>
        <div data-thumbnail class="${color.borders} ${
  thumbnailBgColor ? backgroundColor[thumbnailBgColor] : ""
} ${color["border" + highlightColor]} ${styles.thumbnail} ${
  styles[thumbnailShape]
} ${isNumbered ? typographyStyles.h1 : ""}">
        ${
  !isNumbered
    ? imageBlock({
      image: galleryItem.image,
      aspectRatio,
      maxSize: 250
    })
    : index + 1
}
<div class="${galleryItem.icon && !isNumbered ? `${styles.overlay} ${overlayClasses({position: "bottom"})}`:""}"></div>
        ${
  galleryItem.icon && !isNumbered
    ? `<span class="${styles.icon}">${icon({
      name: galleryItem.icon,
      iconColor: galleryItem.iconColor ? galleryItem.iconColor : "White"
    })}</span>`
    : ""
}
        </div>
        ${
  galleryItem.caption && !hideCaptions
    ? `<div class="${styles.caption}" analytics-title>${galleryItem.caption}</div>`
    : ""
}
        </button>`
    )
    .join("")}
    </div>
    </div>
  </div>`;
};
