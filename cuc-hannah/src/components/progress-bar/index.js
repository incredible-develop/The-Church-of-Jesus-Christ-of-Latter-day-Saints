import styles from "./styles.css";
import { layoutInner, layoutOuter } from "components/layout";
import colorStyles from "../color";
import background from "../background";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "progress-bar");
};

export const component = (props) => {
  const { stepCount, currentStep, theme, rounded = true } = props;

  return `
    <div data-type="progress-bar" class="${layoutOuter(props)}">
      ${background(props)}
      <div class="${layoutInner(props)} ${colorStyles["color" + theme]} ${
    styles.progressBar
  } ${rounded ? styles.rounded : ""}">
          <progress role="progressbar" aria-label="${currentStep}/${stepCount}" aria-valuenow="${currentStep}" aria-valuemin="0" aria-valuemax="${stepCount}" max="${stepCount}" value="${currentStep}"></progress>
      </div>
    </div>`;
};
