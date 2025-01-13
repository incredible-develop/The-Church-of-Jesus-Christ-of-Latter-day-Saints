import titanImage from "../titan-image";
import { escape } from "../../utilities/common";
import styles from "./styles.css";
import { layoutInner, layoutOuter } from "components/layout";
import background from "../background";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "block-quote");
};

export const component = (props) => {
  const { image, text, pageGlobals, citation } = props;
  if (image) image.maxSize = 128;
  // prettier-ignore
  return `
    <aside data-type="block-quote" class=" ${layoutOuter(props)} ${styles.blockQuote}">
  ${background(props)}
      <div class=" ${layoutInner(props)}">
        <div class=" ${styles.container}">
          ${image ? `<div class="${styles.image}">${titanImage({...image, pageGlobals})}</div>`: ""}
          <div class="${styles.content}">
            <div class="${styles.text}">${text ? escape(text) : ""}</div>
            <div class="${styles.citation}">${citation ? citation : ""}</div>
        </div>
      </div>
  </aside>`;
};
