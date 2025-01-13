import styles from "./styles.css";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "anchor");
};

export const component = ({ id }) => {
  return `<div id="${id}" data-type="anchor" class="${styles.anchor}"></div>`;
};
