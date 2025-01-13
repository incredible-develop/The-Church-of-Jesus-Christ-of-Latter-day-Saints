import mainStyles from "./styles.css";
import criticalStyles from "./critical.css";
import typographyStyles from "../typography/critical.css";
import imageBlock from "../image-block";
import { layoutInner, layoutOuter } from "components/layout";
import linkAttrs from "../link-attrs";
import background from "../background";
import invertColors from "../invert-text-color";
import zoomStyles from "../zoom/styles.css";
import { renderChecker } from "../server.js";

const styles = { ...mainStyles, ...criticalStyles };

export default (props) => {
  return renderChecker(component, props, "horizontal-tile");
};

export const component = (props) => {
  const { tiles, pageGlobals, invertTextColor = false } = props;

  function makeTile(tileProps) {
    const {
      portraitCardLink,
      heading = "",
      primaryMeta = "",
      secondaryMeta = "",
      content = "",
      image,
      pageGlobals
    } = tileProps;
    const link =
      portraitCardLink && portraitCardLink.URL ? portraitCardLink : "";
    const imageContainer = image
      ? imageBlock({
          image,
          pageGlobals,
          maxSize: 128,
          aspectRatio: "1x1",
          borderRadius: "8px",
          layout: {
            backgroundWidth: "uncontrolled"
          }
        })
      : "";
    const primMeta =
      primaryMeta &&
      `<span class="${styles.primaryMeta}">${primaryMeta}</span>`;
    const secMeta =
      secondaryMeta &&
      `<span class="${styles.secondaryMeta}">${secondaryMeta}</span>`;
    const metas = [primMeta, secMeta]
      .filter(Boolean)
      .join(`<span class="${styles.pipe}">|</span>`);
    const metaText = metas && `<p class="${styles.meta}">${metas}</p>`;
    // prettier-ignore
    return `
    ${link ? `<a use-analytics class="${styles.tile} ${zoomStyles.zoom}" extra-css="zoom" ${linkAttrs(link)}>` : `<div class="${styles.tile}">`}
    ${imageContainer}
    <div class="${styles.contentContainer}">
      <div class="${styles.verticalAlignSelf}">
        ${metaText}
        ${heading && `<p class="${styles.headline} ${typographyStyles.h4}">${heading}</p>`}
        ${content && `<p class="${styles.content}">${content}</p>`}
      </div>
    </div>
     ${link ? `</a>` : "</div>"}`
  }

  // prettier-ignore
  return `
  <div data-type="horizontal-tile" class=" ${layoutOuter(props)} ${styles.horizontalTile}">
  ${background(props)}
      <div class=" ${layoutInner(props)} ${styles.container} ${invertColors(invertTextColor)} ${invertTextColor ? styles.invertTextColor: ""}">
        ${tiles.map(tile => makeTile({...tile, pageGlobals})).join(" ")}
    </div>
  </div>`;
};
