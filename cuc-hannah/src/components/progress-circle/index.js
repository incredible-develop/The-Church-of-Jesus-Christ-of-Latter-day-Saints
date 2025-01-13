import { bgcolorToCssVar } from "../color/util";
import icon from "../icon";
import styles from "./styles.css";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "progress-circle");
};

export const component = (props) => {
  const { percent = "0", color = "Confirmation40" } = props;
  // prettier-ignore
  return `
  <div data-type="progress-circle" class="${styles.progressCircle}" style="--progress-percentage:${percent}%;${color ? ` --progress-color:var(${bgcolorToCssVar(color)})` : ""}"${percent === 100 ? " complete":""} title="${percent}%">
  ${icon({name:"check"})}
  </div>`;
};
