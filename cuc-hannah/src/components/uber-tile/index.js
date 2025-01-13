import mainStyles from "./styles.css";
import criticalStyles from "./critical.css";
import invertColors from "../invert-text-color";
import typographyStyles from "../typography/critical.css";
import aspectRatioStyles from "../aspect-ratio/critical.css";
import { layoutOuter } from "../layout";
import button from "../button";
import { CSSClass as aspectClass } from "../aspect-ratio";
import videoComponent from "../video";
import background from "../background";
import actionWrapper from "../action-wrapper";
import socialIcons from "../social-block";
import zoomStyles from "../zoom/styles.css";
import bar from "../bar";
import { render } from "..";
import { layoutInner } from "components/layout";
import { renderChecker } from "../server.js";
import overlayClasses from "../overlay";
const styles = { ...mainStyles, ...criticalStyles };
let children = [];

export default (props) => {
  return renderChecker(component, props, "uber-tile");
};

export const component = (props) => {
  const {
    barColor = "",
    heading,
    isExtraBold,
    body,
    invertTextColor,
    headingStyleMobile,
    headingStyleDesktop,
    bodyStyleMobile,
    bodyStyleDesktop,
    verticalStyleMobile,
    verticalStyleDesktop,
    horizontalStyleMobile,
    horizontalStyleDesktop,
    textStyleMobile,
    textStyleDesktop,
    btn,
    aspectRatioMobile,
    aspectRatioDesktop,
    video,
    socialFollow
  } = props;
  let { link, remoteTriggerId } = props;
  if (btn.link && !link) {
    link = btn.link;
    delete btn.link;
  }

  remoteTriggerId =
    remoteTriggerId || video?.youTubeId || video?.brightcoveId || null;

  const bodyDataTags = createDataTags(
    "body",
    bodyStyleMobile,
    bodyStyleDesktop
  );
  const headingDataTags = createDataTags(
    "heading",
    headingStyleMobile,
    headingStyleDesktop
  );
  const verticalDataTags = createDataTags(
    "vertical",
    verticalStyleMobile,
    verticalStyleDesktop
  );
  const horizontalDataTags = createDataTags(
    "horizontal",
    horizontalStyleMobile,
    horizontalStyleDesktop
  );
  const textDataTags = createDataTags(
    "text",
    textStyleMobile,
    textStyleDesktop
  );

  const barTag = barColor
    ? `<div class="${styles.barWrapper}">${bar({ barColor })}</div>`
    : "";
  const bodyCopy = body
    ? `<div class="${styles.bodyCopy}" ${bodyDataTags}>${body}</div>`
    : "";
  const headLine = heading
    ? `<div bold-display-heading analytics-title class="${styles.heading}" ${headingDataTags}>${barTag}
                      ${heading}
                   </div>`
    : "";

  if (socialFollow) {
    socialFollow.isChild = true;
    // remove any align setting so it can follow what uber tile does for alignment
    socialFollow.actionBarSettings.align = "";
  }

  const isIconOnly = btn.variant === "icon-only";
  const hasBgImage =
    props.background?.bgImage?.renditions || props.background?.bgBrightcoveId;
  const { iconOnlyStyles, iconOnlyInvertColor } = createIconStyles(
    isIconOnly,
    hasBgImage,
    invertTextColor,
    btn
  );

  btn.fakeButton = true; // always use a fake button as the component will either be wrapped in A or BUTTON which is already actionable

  if (btn.variant === "text-link" && invertTextColor) {
    btn.colorVariant = "White";
  }

  const btnElem = createButtonElement(btn, isIconOnly, socialFollow);
  children = [headLine, bodyCopy, btnElem].join("");

  const gradientDataTags = createGradientTags(
    props,
    hasBgImage,
    verticalStyleMobile,
    verticalStyleDesktop
  );
  const gridDataTags = createGridTags(
    isExtraBold,
    headingStyleMobile,
    headingStyleDesktop
  );

  const baseTile = makeBaseTile({
    ...props,
    alignmentStyles: `${verticalDataTags} ${horizontalDataTags}`,
    textJustificationStyles: textDataTags,
    gradientStyles: gradientDataTags,
    children
  });

  const { wrapperOpen, wrapperClose } = actionWrapper({
    link: !socialFollow ? link : {},
    remoteTriggerId
  });

  const isClickable =
    wrapperClose === "a" || wrapperClose === "button" || video;
  // prettier-ignore
  return `
  <${wrapperOpen} data-type="uber-tile" class="${uberTileWrapperClasses(props, aspectRatioMobile, aspectRatioDesktop, isClickable)}" ${isClickable ? `extra-css="zoom"` : ""}>
  ${background(props)}
    <div class="${iconOnlyStyles} ${invertColors(invertTextColor)} ${iconOnlyInvertColor} ${styles.innerWrapper} ${isExtraBold ? styles.isExtraBold : ""}" ${gridDataTags}>
      ${baseTile}
    </div>
    ${video ? videoComponent({...video, remoteTriggerId, variant: "contain"}) : ""}
  </${wrapperClose}>`;
};

// This automatically creates data-tags used by the browser for mobile/desktop dynamic style adjustments
const createDataTags = (type, mobile, desktop) => {
  const mobileTag = `data-${type}-style-mobile="${createClass(mobile)}"`;
  const desktopTag = `data-${type}-style-desktop="${createClass(desktop)}"`;
  return `${mobileTag} ${desktopTag}`;
};

// Grabs the style, the gradient styles have multiple pre-rendered class names, which is accounted for with the ternary statement
const createClass = (dynamicClass) => {
  return dynamicClass?.split(" ")?.length > 1
    ? dynamicClass
    : { ...typographyStyles, ...styles }[dynamicClass];
};

// A function to create a "base tile"
const makeBaseTile = (tileContent) => {
  const {
    alignmentStyles = "", // horizontal and vertical alignment
    textJustificationStyles = "",
    gradientStyles = "",
    children = ""
  } = tileContent;
  const addPadding =
    !tileContent.layout.contentWidth && !tileContent.layout.paddingTop
      ? styles.addPadding
      : "";
  return `
<div ${alignmentStyles} class="${styles.container}" extra-css="overlay">
  <div  ${textJustificationStyles} ${gradientStyles} class="${
    styles.gradientWrapper
  } ${styles.grid} ${layoutInner(tileContent)} ${addPadding}">${render({
    componentData: children
  })}</div>
</div>`;
};

// Based on the heading style, return different grid gap classes
const gridStyleSelector = (style, isBold) => {
  return (!isBold && style === "h1") || style === "h1-Mckay" || style === "h2"
    ? "gridGapLarge"
    : "gridGapSmall";
};

// Creates data tags for the grid styles
const createGridTags = (isBold, mobile, desktop) => {
  return createDataTags(
    "grid",
    gridStyleSelector(mobile, isBold),
    gridStyleSelector(desktop, isBold)
  );
};

// Creates data tags for the gradient styles
const createGradientTags = (props, hasBgImage, mobile, desktop) => {
  const hasOverlay =
    props?.background?.overlay && props?.background?.overlay !== "false";
  if (hasOverlay && hasBgImage) {
    props.background.overlay = !children; // If there's no content, use the normal overlay, otherwise set it to false to allow the custom gradients to do their thing
    if (children) {
      const gradientStyleMobile = calculateGradient(mobile, props);
      const gradientStyleDesktop = calculateGradient(desktop, props);
      return createDataTags(
        "gradient",
        gradientStyleMobile,
        gradientStyleDesktop
      );
    }
  }
  return "";
};

// Returning the correct gradient style classes as a string based on vertical alignment
const calculateGradient = (style, props) => {
  const edgeGradient =
    (style === "top" || style === "bottom") &&
    `${styles.gradient} ${overlayClasses({
      position: style
    })}`;
  const middleGradient =
    style === "middle" &&
    `${styles.gradient} ${styles.centerOverlay} ${overlayClasses({
      position: "center",
      hideOverlayFor: props.background.hideOverlayFor
    })}`;
  return edgeGradient || middleGradient || "";
};

const createIconStyles = (isIconOnly, hasBgImage, invertTextColor, button) => {
  if (isIconOnly && hasBgImage) {
    button.invertIconColor = true;
    button.colorVariant = "blue";
  }
  return {
    iconOnlyStyles: isIconOnly && hasBgImage ? styles.iconOnlyStyles : "",
    iconOnlyInvertColor:
      isIconOnly && invertTextColor ? styles.invertTextColor : ""
  };
};

const createButtonElement = (btn, isIconOnly, socialFollow) => {
  const normalBtn = btn.label || isIconOnly ? button(btn) : "";
  return socialFollow ? socialIcons(socialFollow) : normalBtn;
};

const uberTileWrapperClasses = (
  props,
  aspectRatioMobile,
  aspectRatioDesktop,
  isClickable
) => {
  const mobileRatio = aspectClass(aspectRatioMobile);
  const desktopRatio = aspectRatioDesktop
    ? aspectClass(aspectRatioDesktop + "Desktop")
    : "";
  const mobileIsFlush =
    props.layout.contentWidthMobile === "flush" ? styles.mobileIsFlush : "";
  const desktopIsFlush =
    props.layout.contentWidthDesktop === "flush" ? styles.desktopIsFlush : "";

  return `${styles.uberTile} ${layoutOuter(props)} ${
    aspectRatioStyles.aspectRatio
  } ${mobileRatio} ${desktopRatio} ${mobileIsFlush} ${desktopIsFlush} ${
    isClickable ? zoomStyles.zoom : ""
  }`;
};
