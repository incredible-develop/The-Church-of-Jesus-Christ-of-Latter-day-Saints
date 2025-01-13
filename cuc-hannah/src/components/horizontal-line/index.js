import styles from "./styles.css";
import spacingStyles from "../spacing/critical.css";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "horizontal-line");
};

export const component = ({ mobileSpacing, desktopSpacing }) => {
  return `<hr data-type="horizontal-line" class="${styles.horizontalLine} ${
    spacingStyles[mobileSpacing]
  } ${spacingStyles["desktop-" + desktopSpacing]}">`;
};
