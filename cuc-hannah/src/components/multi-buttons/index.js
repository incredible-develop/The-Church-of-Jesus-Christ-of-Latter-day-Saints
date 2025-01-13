import styles from "./styles.css";
import { layoutInner, layoutOuter } from "components/layout";
import background from "components/background";
import { renderChecker } from "../server.js";
import button from "../button";

export default (props) => renderChecker(component, props, "multi-buttons");

export const component = (props) => {
  const { buttons, wrapperJustification = "left" } = props;

  const buttonsArr = buttons
    .map((btn) => {
      return button({
        ...btn,
        btnJustification: "left", // send override down to all left, the container can change not the inner
        // this is to force the inner button wrapper to not be there for our flex to work.
        layout: { contentWidthDesktop: false }
      });
    })
    .join("");
  // prettier-ignore

  return `
  <div data-type="multi-buttons" class="${layoutOuter(props)}">
    ${background(props)}
    <div class="${layoutInner(props)} ${styles.multiButtons} ${styles[wrapperJustification]}" >
       ${buttonsArr}
    </div>
  </div>`;
};
