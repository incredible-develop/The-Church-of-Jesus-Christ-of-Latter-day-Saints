import styles from "./styles.css";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "max-lines");
};

export const component = (props) => {
  const { content, maxLines, maxLinesDesktop = maxLines } = props;

  // prettier-ignore
  return `
  <div data-type="max-lines" max-lines-wrapper ${maxLines && ` style="--maxLinesMobile:${maxLines}; --maxLinesDesktop:${maxLinesDesktop};"`}>
    <div class="${styles.fader}">
      ${content}
    </div>
  </div>`;
};
