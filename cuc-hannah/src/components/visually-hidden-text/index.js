import styles from "./critical.css";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "visually-hidden-text");
};

export const component = (props) => {
  const { text, additionalAttributes } = props;
  // prettier-ignore
  return `
  <span data-type="visually-hidden" class="${styles.hide}" ${additionalAttributes ? additionalAttributes : ""}>
    ${text}
  </span>`;
};
