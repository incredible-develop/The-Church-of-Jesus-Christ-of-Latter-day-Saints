import styles from "./styles.css";
import icon from "../icon";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "rotating-arrow");
};

export const component = (props) => {
  const {
    label,
    alignment,
    iconType,
    notAButton = false,
    cssClasses = [],
    htmlAttrs = []
  } = props;

  const type = notAButton ? `div` : `button`;

  // prettier-ignore
  return `<${type} data-type="rotating-arrow" class="${styles[alignment]} ${styles.rotatingArrow} ${cssClasses.join(" ")}" ${htmlAttrs.join(" ")}>
             ${label ? label : ""}
            <span class="${styles.icon} ${iconType === "condensed" ? styles.condensed : ""}" aria-hidden="true">${icon({name: "chevron-down"})}</span>
          </${type}>`;
};
