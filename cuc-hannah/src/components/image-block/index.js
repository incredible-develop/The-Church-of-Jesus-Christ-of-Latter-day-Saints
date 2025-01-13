/*
image-block

    {
        type: 'image-block',
        imageURL: 'The URL of the image',
        linkURL: 'An optional link URL',
        referencedPage: {},
        caption: 'An optional caption'
    }

Creates an image using a given `imageURL` as the `src`.

If an optional `referencedPage` or `linkURL` property is present, the image will be wrapped in an anchor tag.

If an optional `caption` is present, it will be displayed.

Uses the media-block component.
*/
import styles from "./styles.css";
import aspectRatioStyles from "../aspect-ratio/critical.css";
import { CSSClass } from "../aspect-ratio";
import titanImage from "../titan-image";
import { layoutInner, layoutOuter } from "components/layout";
import background from "components/background";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "image-block");
};

export const component = (props) => {
  const {
    image,
    aspectRatio = "16x9",
    borderRadius = "0px",
    variant,
    minSize,
    maxSize,
    pageGlobals
  } = props;
  let { mobileAspectRatio = "" } = props;
  if (image) {
    image.minSize = minSize;
    image.maxSize = maxSize;
  } else {
    // no image, so no sense going on to display the image we don't have
    return "";
  }

  mobileAspectRatio =
    mobileAspectRatio === "" ? aspectRatio : mobileAspectRatio;

  // used to identify an element inside a container that is to avoid being hidden when the other elements are hidden
  const isPrimaryContent = "is-primary-content";
  // prettier-ignore
  return `
  <div data-type="image-block" ${isPrimaryContent} class="${layoutOuter(props)}" skip-analytics>
    ${background(props)}
    <div class="${layoutInner(props)}">
        <div class="${styles["borderRadius" + borderRadius]} ${styles.aspectRatio} ${aspectRatioStyles.aspectRatio} ${mobileAspectRatio !== "keeporiginal" ? `${CSSClass(mobileAspectRatio)}` : `${styles.mobileIgnoreAspect}`} ${aspectRatio !== "keeporiginal" ? `${CSSClass(aspectRatio + "Desktop")}` : `${styles.desktopIgnoreAspect}`} ${variant ? styles[variant] : ""}" data-type="aspect-ratio" skip-analytics>${titanImage({...image, pageGlobals})}</div>
    </div>
  </div>`;
};
