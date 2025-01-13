import styles from "./styles.css";
import icon from "../icon";
import invertTextStyles from "../invert-text-color";
import { layoutInner, layoutOuter } from "components/layout";
import background from "../background";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "likes");
};

export const component = (props) => {
  const {
    counterGroup = "",
    counterId = "",
    justification = "center",
    ariaLabel = "likes",
    countUpdatedString = "Likes updated",
    invertIconColor = false
  } = props;
  return `<div class= "${layoutOuter(props)}">
  ${background(props)}
            <div data-type="likes" aria-live="off" data-counter-group="${counterGroup}" data-counter-id="${counterId}" class=" ${
    styles.likes
  } ${layoutInner(props)} ${styles[justification]}">
              <button aria-label="${ariaLabel}" data-counter-updated-aria-label="${countUpdatedString}" data-type="toggle" data-toggled="off" class="${
    styles.countButton
  } ">
                <div class="${styles.beforeToggle}">${icon({
    name: "heart-std",
    invertIconColor
  })}</div>
                <div class="${styles.afterToggle} ${
    invertIconColor ? styles.colorWhite : ""
  }">${icon({
    name: "heart-filled",
    invertIconColor
  })}</div>
              </button>
              <div data-count class="${styles.count} ${invertTextStyles(
    invertIconColor
  )}"></div>
            </div>
          </div>`;
};
