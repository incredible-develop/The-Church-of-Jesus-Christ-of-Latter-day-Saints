import styles from "./styles.css";
import { layoutInner, layoutOuter } from "components/layout";
import background from "../background";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "horizontal-rule");
};

export const component = (props) => {
  const { invertColor = false } = props;
  // prettier-ignore
  return `
  <div data-type="horizontal-rule" class="${layoutOuter(props)}">
    ${background(props)}
    <hr class="${styles.horizontalRule} ${invertColor ? styles.invertColor : "" } ${layoutInner(props)} "/>
  </div>`;
};
