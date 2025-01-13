/*
caption-block

    {
        caption: 'The image or video description',
        citation: 'The source or other legal info of the image or video.'
    }

Creates a caption-block with optional citation.
*/
import styles from "./styles.css";
import typographyStyles from "../typography/critical.css";
import button from "../button";
import { layoutInner, layoutOuter } from "components/layout";
import invertColors from "../invert-text-color";
import downloadButton from "../download-button";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "caption-block");
};

export const component = (props) => {
  const {
    heading,
    caption,
    citation,
    btn,
    invertTextColor = false,
    downloadLabel,
    limitTextWidth,
    textAlign = "Left",
    limitMobileWidth
  } = props;

  const invert = invertColors(invertTextColor);

  const propsClone = Object.assign({}, props);
  propsClone.layout.spacingTop = props.layout.spacingTop || "unite-2-8px";

  const downloadBtn = downloadLabel
    ? downloadButton({
        cssClasses: [styles.download, invert],
        children: (defaultChildren) => [downloadLabel, ...defaultChildren],
        invertIconColor: invertTextColor
      })
    : "";

  // prettier-ignore
  return caption || heading || citation || downloadBtn || btn?.label
    ? `
    <div data-type="caption-block" use-analytics ${limitMobileWidth ? "limitMobileWidth" : ""} class="${styles.captionBlock} ${styles['align' + textAlign]} ${layoutOuter(propsClone)} ${invert}">
      <div class="${layoutInner(props)}">
        <div class="${styles.container}">
        <div class="${styles.wrapper} ${limitTextWidth ? styles.limitWidth : ""}">
          ${heading ? `<div class="${styles.heading} ${typographyStyles.h4}" analytics-title>${heading}</div>` : ""}
          ${caption ? `<div class="${styles.caption}">${caption}</div>` : ""}
          ${citation ? `<div class="${styles.citation}">${citation}</div>` : ""}
          ${btn?.label ? `<div class="${styles.button}">${button(btn)}</div>` : ""}
        </div>
        ${downloadBtn}
        </div>
      </div>
    </div>`
    : "";
};
