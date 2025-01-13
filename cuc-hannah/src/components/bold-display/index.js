import styles from "./styles.css";
import { layoutInner, layoutOuter } from "components/layout";
import background from "components/background";
import textLinkStyles from "../text-link/styles.css";
import typographyStyles from "../typography/critical.css";
import renderButton from "../button";
import renderIcon from "../icon";
import overlayClasses from "../overlay";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "bold-display");
};

export const component = (props) => {
  const {
    heading,
    miniText,
    fontFamily,
    contentAlign,
    color,
    includeBtn,
    btnLabel,
    btnIcon,
    miniTextIcon = "",
    playIconAriaLabel = "play",
    overlay,
    maxLines = 2,
    maxLinesDesktop = maxLines,
    // right now fitContainer should always be true unless this will be needed as a block-level component
    fitContainer = true
  } = props;

  // prettier-ignore
  const headingTag = heading ? `
  <div bold-display-heading style="--maxLinesMobile:${maxLines}; --maxLinesDesktop:${maxLinesDesktop};" class="${styles.boldHeading} ${typographyStyles.h1} ${styles[fontFamily] || ""}" max-lines-wrapper>
    <div max-lines-fader>${heading}</div>
  </div>` : ""

  // prettier-ignore
  const playIcon = `
  <button class="${styles.playIconBtn}" aria-label="${playIconAriaLabel}">
    ${renderIcon({ type: "icon", name: "play", invertIconColor: true })}
  </button>
  <span class="${styles.lineUnderIcon}"></span>
  `;

  const primaryBtn = renderButton({
    type: "button",
    size: "small",
    variant: "primary-color-background",
    label: btnLabel,
    icon: btnIcon
  });

  const button =
    includeBtn && btnLabel ? primaryBtn : includeBtn ? playIcon : "";

  const miniVidIcon = renderIcon({
    type: "icon",
    name: "play",
    iconColor: "Link"
  });

  const miniIconClass = !miniTextIcon
    ? ""
    : miniTextIcon === "chevron-right"
    ? textLinkStyles.link
    : styles.videoLink;

  // prettier-ignore
  const miniTextTag = miniText ?
    `<span class="${styles.miniText} ${miniIconClass}">
    ${miniText}${miniTextIcon === "play" ? miniVidIcon: ""}
  </span>` :
    "";

  let gradientOverlay = "";
  if (
    overlay &&
    (contentAlign === "BottomCenter" || contentAlign === "BottomLeft")
  ) {
    gradientOverlay = overlayClasses({ position: "bottom" });
  } else if (overlay) props.background.overlay = true;

  // prettier-ignore
  const contents = `
  ${background(props)}
  <div bold-display-contents class="${styles.boldContents} ${fitContainer ? styles.fitContainer : layoutInner(props)} ${styles["align" + contentAlign]} ${color ? styles["color" + color] : ""}">
      <div bold-display-text-wrapper class="${styles.textWrapper} ${gradientOverlay}">
      ${button}
      ${headingTag}
      ${miniTextTag}
    </div>
  </div>
  `;

  return `<div data-type="bold-display" extra-css="overlay${
    !fitContainer
      ? ` max-lines" class="${styles.boldDisplay} ${layoutOuter(props)}"`
      : ""
  }">${contents}</div>`;
};
