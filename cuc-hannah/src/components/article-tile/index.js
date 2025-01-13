import { render } from "..";
import styles from "./styles.css";
import aspectRatioStyles from "../aspect-ratio/critical.css";
import typographyStyles from "../typography/critical.css";
import titanStyles from "../titan-image/styles.css";
import linkAttrs from "../link-attrs";
import zoomStyles from "../zoom/styles.css";
import progressCircle from "../progress-circle";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "article-tile");
};

const iconBadge = (icon = false) => {
  return icon && icon === "video"
    ? `<svg width="22px" height="18px" viewBox="0 0 22 18" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><title>icon: Video</title><defs></defs><g id="Article-1.1-Tablet-9&quot;-Landscape-Copy" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd" transform="translate(-23.000000, -1481.000000)"><g id="responsive-grid---mobile-copy-6" transform="translate(-1.000000, 1269.000000)"><g id="Video" transform="translate(4.000000, 195.160000)"><g transform="translate(15.500000, 15.363636)" id="Video-Copy-3"><g transform="translate(4.500000, 1.692592)"><g id="Video"><g id="video"><rect id="Rectangle-529" stroke="#FFFFFF" stroke-width="1.35" x="0.914130435" y="1.15326087" width="20.1717391" height="15.8673913" rx="0.9"></rect><path d="M9.25317681,12.2553266 C9.02904171,12.3937042 8.84782609,12.2839564 8.84782609,12.0119728 L8.84782609,6.1619402 C8.84782609,5.88995663 9.02904171,5.78020887 9.25317681,5.91858648 L14.0601595,8.8436028 C14.2842946,8.97720876 14.2842946,9.19670428 14.0601595,9.33031024 L9.25317681,12.2553266 Z" id="Type-something" fill="#FFFFFF"></path><rect id="Rectangle-530" fill="#FFFFFF" x="1.31521739" y="1.55434783" width="19.3695652" height="2.15217391"></rect><rect id="Rectangle-530" fill="#FFFFFF" x="1.31521739" y="14.4673913" width="19.3695652" height="2.15217391"></rect></g></g></g></g></g></g></g></svg>`
    : ``;
};

export const component = ({
  image,
  primaryMeta,
  secondaryMeta,
  link,
  icon,
  heading,
  content,
  variant = "default",
  download = "false",
  showProgress = false
}) => {
  if (image) image.maxSize = 400;

  // prettier-ignore
  const imageContainer = image
    ? `
    <div class="${styles.imageContainer} ${aspectRatioStyles.aspectRatio} ${aspectRatioStyles.is16x9}">
      <div class="${styles.image} ">
        ${render({componentData: image})}
        ${icon ? `<div class="${styles.iconArea}">${iconBadge(icon)}</div>` : ""}
        ${showProgress ? `<span class="${styles.progress}">${progressCircle({})}</span>` : ""}
      </div>
    </div>`
    : "";

  const hasText = heading || content || primaryMeta;

  // prettier-ignore
  return `
  <a data-type="article-tile" use-analytics class="${styles.articleTile} ${variant ? styles[variant] : ""} ${titanStyles.gradientOnHover} ${zoomStyles.zoom}" extra-css="zoom" ${linkAttrs(link)} ${download === "true" ? `download` : ""}>
      ${imageContainer}
      <div class="${styles.contentContainer}">
          ${hasText ? `<div class="${styles.contentWrapper} ${!secondaryMeta ? styles.noSecondary : ""}">` : ""}
            ${primaryMeta ? `<div class="${styles.primaryMeta} ${typographyStyles.h6}">${primaryMeta}</div>` : ""}
            ${heading ? `<p class="${styles.headline} ${typographyStyles.h4}">${heading}</p>` : ""}
            ${content ? `<div class="${styles.content}">${content}</div>` : ""}
          ${hasText ? `</div>` : ""}
          ${secondaryMeta ? `<div class="${styles.secondaryMeta}">${secondaryMeta}</div>` : ""}
      </div>
  </a>`;
};
