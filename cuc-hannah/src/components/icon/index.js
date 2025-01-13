import styles from "./critical.css";
import colorStyles from "../color";
import invertTextColor from "../invert-text-color";
const fs = require("fs");
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(componentRenderChecker, props, "icon");
};

export const componentRenderChecker = (props) => {
  const {
    name = "",
    title,
    iconColor = "Grey60",
    invertIconColor = false,
    hidden = false,
    extraAttr = ""
  } = props;
  let inline = "";
  // check for fs.readFileSync because storybook has issues with it being in deeper components
  if (props.inline && fs?.readFileSync) {
    inline = fs.readFileSync(
      `${__dirname}/../browser/svgs/${name}.svg`,
      "utf8"
    );
  }
  return `<span class="${styles.icon} ${
    invertTextColor(invertIconColor) || colorStyles["color" + iconColor] || ""
  }" data-icon-name="${name}" ${title ? `data-svg-title="${title}"` : ""} ${
    hidden ? "hidden" : ""
  } ${extraAttr}>${inline}</span>`;
};
