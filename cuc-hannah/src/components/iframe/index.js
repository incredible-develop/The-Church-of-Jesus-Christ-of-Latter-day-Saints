import { layoutInner, layoutOuter } from "components/layout";
import background from "components/background";
import styles from "./styles.css";
import { renderChecker } from "../server.js";

function instagramRender(permalink) {
  return `<div class="${styles.wrapper}"><blockquote class="instagram-media ${styles.instagramPost}" data-instgrm-captioned data-instgrm-permalink="${permalink.permalink}" data-instgrm-version="9"></blockquote> <script async defer src="//www.instagram.com/embed.js"></script></div>`;
}

export default (props) => {
  return renderChecker(component, props, "iframe");
};

export const component = (props) => {
  const {
    id,
    postsPerRow = "one",
    permalinks,
    src,
    title,
    height,
    allowFullScreen = "true"
  } = props;
  // prettier-ignore
  return `
  <div data-type="iframe" class="${layoutOuter(props)}">
    ${background(props)}
    <div class="${layoutInner(props)}">
      ${
  id
    ? `<script async src="https://cdn.hypemarks.com/pages/a5b5e5.js"></script><div class="tintup ${
      styles.tintup
    }" data-id="${id}" data-columns="" data-expand="true" data-infinitescroll="true" style="height: ${height +
              "px"};"></div>`
    : permalinks
      ? `<div class="${styles.container} ${
        styles[postsPerRow]
      }">${permalinks.map(instagramRender).join("")}</div>`
      : src
        ? `<iframe class="${styles.iframe}" src="${src}" title="${title ? title : ""}" height="${
          height ? height : ""
        }" ${
          allowFullScreen === "true" ? `allowFullScreen` : ""
        }></iframe>`
        : ""
}
    </div>
  </div>`;
};
