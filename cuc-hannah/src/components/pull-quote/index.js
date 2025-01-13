import { escape } from "../../utilities/common";
import styles from "./styles.css";
import { layoutInner, layoutOuter } from "components/layout";
import background from "../background";
import invertColors from "../invert-text-color";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "pull-quote");
};

export const component = (props) => {
  const {
    text,
    citation,
    textJustification = "center",
    invertTextColor = "false"
  } = props;

  if (!props.background) props.background = {};

  props.background.overlay = true;

  return `
${
  text || citation
    ? `<aside class="${styles.pullQuote} ${layoutOuter(
        props
      )}" data-type="pull-quote">
      ${background(props)}
      <div class="${layoutInner(props)}">
	    <div class="${styles.content} ${styles[textJustification]} ${
        styles[textJustification]
      } ${invertColors(invertTextColor)}">
	        ${text ? `<div class="${styles.text}">${escape(text)}</div>` : ""}
	        ${citation ? `<div class="${styles.citation}">${citation}</div>` : ""}
      </div>
    </div>
</aside>`
    : ""
}`;
};
