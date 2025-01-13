import { escape } from "../../utilities/common";
import styles from "./styles.css";
import iconComponent from "../icon";
import iconStyles from "../icon/critical.css";
import { layoutInner, layoutOuter } from "components/layout";
import background from "../background";
import remoteTrigger from "components/remote-trigger";
import bgColor from "../background/styles.css";
import color from "../color";
import linkAttrs from "../link-attrs";
import { renderChecker } from "../server.js";

function capitalize(string) {
  return string?.charAt(0)?.toUpperCase() + string?.slice(1);
}

export default (props) => {
  return renderChecker(component, props, "button");
};

// If a link is given with a URL, it assumes the "button" is an <a> instead of a <button>
export const component = (props) => {
  const {
    link: { URL } = {},
    layout: { contentWidthDesktop } = {},
    fakeButton
  } = props;
  let { downloadRef = "" } = props;

  // TODO: the accessibility of the buttons will be fixed in CUC-7721 https://jira.churchofjesuschrist.org/browse/CUC-7721
  downloadRef = createDownloadRef(downloadRef);
  const wrapper = downloadRef || contentWidthDesktop;
  const href = URL || downloadRef;

  const buttonElement = createButtonElement({ ...props, href, wrapper });

  if (wrapper) {
    return `
		<div data-type="button" class="${layoutOuter(props)}" extra-css="background">
      ${background(props)}
      <div class="${layoutInner(props)}">
        <div class="${
          downloadRef || URL || fakeButton ? styles.flexContainer : ""
        }">
          ${buttonElement}
        </div>
      </div>
		</div>
		`;
  } else {
    return buttonElement;
  }
};

const createDownloadRef = (ref) => {
  const editedRef = ref?.includes("?") ? ref : `${ref}?download=true`;
  return ref ? editedRef : "";
};

const sortElement = (logic, array, element) => {
  return logic ? array.unshift(element) : array.push(element);
};

const generateColorStyles = (variant, colorVariant) => {
  const isPrimary = variant === "primary-color-background";
  const primaryColor = bgColor[colorVariant] || bgColor.Theme;
  const otherColor = color["color" + colorVariant] || "";
  const otherVariant =
    variant === "ghost-color-text" ||
    variant === "secondary-color-text" ||
    variant === "text-link" ||
    variant === "icon-only"
      ? otherColor
      : "";

  return isPrimary ? primaryColor : otherVariant;
};

const createButtonElement = (props) => {
  const { wrapper, href, fakeButton, link } = props;
  let { btnType, title } = props;

  const defaultAttrs = generateDefaultAttributes({ ...props, wrapper });
  const btnContent = createButtonContent(props);
  const titleAttr = title ? `title="${escape(title)}" ` : "";
  const ariaLabel = title ? `aria-label="${escape(title)}" ` : "";
  btnType = btnType ? `type="${btnType}"` : "";

  if (href && !fakeButton) {
    // prettier-ignore
    return `<a ${defaultAttrs} ${titleAttr}${linkAttrs(link)}>${btnContent}</a>`;
  } else {
    const elType = fakeButton ? "span" : "button";
    // prettier-ignore
    return `<${elType} ${defaultAttrs} ${ariaLabel}${btnType}>${btnContent}</${elType}>`;
  }
};

const generateDefaultAttributes = (props) => {
  const {
    variant = "primary-color-background",
    icon = "",
    size = "big",
    btnJustification = "center",
    colorVariant,
    iconPosition = "before",
    click = "",
    remoteTriggerId,
    isFullWidth,
    extraAttrs = "",
    wrapper
  } = props;

  const colorStyles = generateColorStyles(variant, colorVariant);
  const btnSize = size === "small" ? `${styles.small}` : `${styles.big}`;
  const onClick = click ? `onClick="${click}" ` : "";
  const remoteTriggerAttribute = remoteTrigger({ remoteTriggerId });
  const justificationClass = wrapper ? styles[btnJustification] : "";
  const fullWidth = isFullWidth ? styles.fullWidthButton : "";
  const iconClass =
    icon || variant === "icon-only"
      ? `${styles.icon} ${styles[iconPosition]} ${iconStyles[iconPosition]} ${iconStyles.button}`
      : "";

  return `data-type="button" use-analytics class="${styles.button} ${styles[variant]} ${colorVariant} ${colorStyles} ${bgColor.btn} ${iconClass} ${btnSize} ${justificationClass} ${fullWidth}" ${onClick}${remoteTriggerAttribute} ${extraAttrs} extra-css="background"`;
};

// This organizes the icons, label, and textLinkArrow according to iconPosition and invertTextLink
const createButtonContent = (props) => {
  const {
    iconPosition = "before",
    invertArrowDirection = false,
    icon = "",
    iconColor, // TODO: methinks we should start using this instead of invertIconColor since invertIconColor only makes it white..
    invertIconColor = false,
    variant = "primary-color-background"
  } = props;
  let { colorVariant = "", title = "", label = "" } = props;

  if (variant === "icon-only") {
    title = label;
    label = "";
  }
  colorVariant = styles[capitalize(colorVariant)] || "";
  const iconEl =
    (icon &&
      iconComponent({
        name: icon,
        title,
        iconColor: iconColor || colorVariant,
        invertIconColor
      })) ||
    (variant === "icon-only" &&
      iconComponent({ name: "play", invertIconColor })) ||
    "";
  const textLinkArrow =
    (variant === "text-link" &&
      `<span class="${styles.textLinkArrow} ${
        invertArrowDirection ? styles.invertArrowDirection : ""
      }">${iconComponent({
        name: invertArrowDirection ? "chevron-left" : "chevron-right",
        iconColor: `${colorVariant}`
      })}</span>`) ||
    "";
  label = escape(label);

  let buttonContent = [label];
  sortElement(iconPosition === "before", buttonContent, iconEl);
  sortElement(invertArrowDirection, buttonContent, textLinkArrow);
  return buttonContent.join("");
};
