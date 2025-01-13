import typographyStyles from "../typography/critical.css";
import { layoutInner, layoutOuter } from "components/layout";
import background from "../background";
import colorStyles from "../color";
import mainStyles from "./styles.css";
import criticalStyles from "./critical.css";
import { renderChecker } from "../server.js";

const styles = { ...mainStyles, ...criticalStyles };

export default (props) => {
  return renderChecker(component, props, "heading");
};

export const component = (props, req = "") => {
  const {
    level = "h5",
    textColor,
    textJustification = "left",
    styleOnly = false
  } = props;
  let { text = "" } = props;
  text = text.replace("{page-uri}", req.path);
  const levelMatch = level ? level.match(/h[1-6]/) : "";
  const tag = levelMatch && !styleOnly ? levelMatch[0] : "div";
  return text
    ? `<div data-type="heading" class="${styles.heading} ${layoutOuter(props)}">
    ${background(props)}
    <div class="${layoutInner(props)}">
    			<${tag} class="${typographyStyles[level]} ${styles[textJustification]} ${
        textColor ? colorStyles[`color${textColor}`] : ""
      }" analytics-title>${text}</${tag}>
      </div>
    </div>`
    : ``;
};
