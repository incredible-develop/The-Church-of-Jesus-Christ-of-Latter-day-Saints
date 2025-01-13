import mainStyles from "./styles.css";
import criticalStyles from "./critical.css";

import flktyStyles from "../flickity/styles.css";
import { render } from "..";
import { layoutInner, layoutOuter } from "components/layout";
import layoutStyles from "components/layout/critical.css";
import icon from "../icon";
import background from "components/background";
import invertColors from "../invert-text-color";
import displayDependency from "../form-components/display-dependency";
import { renderChecker } from "../server.js";

const styles = { ...mainStyles, ...criticalStyles };

export default (props) => {
  return renderChecker(component, props, "enhanced-ui-slider");
};

export const component = (props) => {
  const {
    components = [],
    size = "small",
    wrapAround = false,
    borderRadius,
    desktopAspectRatio,
    moblieAspectRatio,
    ariaPrevious = "previous",
    ariaNext = "next",
    captionAlignment,
    invertTextColor = false,
    layout: { contentWidthDesktop, backgroundWidth },
    uniqueKey,
    pageGlobals
  } = props;

  const backArrow = icon({
    name: "arrow-back",
    invertIconColor: invertTextColor
  });

  const cellSize =
    size === "small"
      ? `${layoutStyles["outer"]} ${layoutStyles["narrow"]}`
      : `${layoutStyles["outer"]} ${layoutStyles["normal"]}`;

  const carouselCell = (componentProps, index) => {
    const isMediaPlayerOrBlock = [
      "mo-media-block",
      "media-block",
      "mo-media-player",
      "media-player"
    ].includes(componentProps.type);

    // If the component is a media block or media player - do some specific things
    if (isMediaPlayerOrBlock) {
      componentProps.layout.backgroundWidthMobile = "uncontrolled";
      // the slider will always have the contents off the edge, so force the actionBar to NOT be indented
      componentProps.indentActionBarDesktop = false;
      componentProps.indentActionBarMobile = false;

      // If the captionAlignment value is set, set the textAlignment to that value
      if (captionAlignment) {
        componentProps.textAlignment = captionAlignment;
      }

      // If captionAlignment is being used and the caption exists, set the value
      if (captionAlignment && componentProps.caption) {
        componentProps.caption.textAlign = captionAlignment;
      }
    }

    // We want display dependencies getting applied to the wrapper, not the inner component
    const displayDependencies = displayDependency({
      ...componentProps,
      uniqueKey
    });

    // prettier-ignore
    return `
    <div class="${flktyStyles.carouselTile} ${index === 0 && flktyStyles.isSelected} ${cellSize}" ${displayDependencies}>
      ${render({
    componentData: {
      ...componentProps,
      aspectRatio: desktopAspectRatio,
      displayDependencies: null, // don't apply display dependencies twice
      mobileAspectRatio: moblieAspectRatio,
      borderRadius,
      invertTextColor,
      videoTitleIsH4: size === "large",
      addGrippy: isMediaPlayerOrBlock,
      limitMobileWidth: isMediaPlayerOrBlock,
      pageGlobals
    }})}
    </div>`;
  };

  const frames = components
    .map((item, index) => carouselCell(item, index))
    .join("");

  // these are the buttons inside the carousel, known as topArrows
  const widthsWithArrows = ["normal", "narrow"];
  const prevNextButtonsExist =
    widthsWithArrows.includes(contentWidthDesktop) ||
    widthsWithArrows.includes(backgroundWidth);

  const dataForBrowser = {
    prevNextButtonsExist,
    wrapAround
  };

  const btmNav = `
  <div btm-nav class="${styles.btmNav} ${invertColors(invertTextColor)}">
    <button btm-nav-prev aria-label="${ariaPrevious}">${backArrow}</button>
    <span aria-live="polite" class="${
      styles.navLabel
    }" btm-nav-label>words and things</span>
    <button btm-nav-next aria-label="${ariaNext}">${backArrow}</button>
  </div>`;

  // prettier-ignore
  return `
<div data-type="enhanced-ui-slider" extra-css="flickity" analytics-title="${components?.[0]?.caption?.heading}" data-browser='${JSON.stringify(dataForBrowser)}' class="${styles.enhancedUiSlider} ${layoutOuter(props)}">
  ${background(props)}
  <div class="${layoutInner(props)}">
		<div aria-live="polite" data-type="enhanced-ui-slider-flickity" skip-analytics class="${prevNextButtonsExist ? `${cellSize} ${flktyStyles.showArrows}` : ""} ${styles.flktyWrapper}" data-swipe-wrapper>
			${frames}
		</div>
		${btmNav}
	</div>
</div>`;
};
