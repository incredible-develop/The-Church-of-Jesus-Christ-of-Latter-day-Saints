import {
  initComponent,
  toggleTrueFalseAttribute
} from "../../utilities/common.js";

export default class RotatingArrow {
  constructor(element) {
    const button = element.closest("button") || element;

    button
      ? button.addEventListener("click", () => {
          element.toggleAttribute("clicked");

          //Only set aria-expanded if the element is a button, if it isn't a button, the aria-expanded attribute should be getting set on the parent button element
          if (element.nodeName === "BUTTON") {
            toggleTrueFalseAttribute(element, "aria-expanded");
          }
        })
      : "";
  }
}
export const init = () => {
  initComponent("rotating-arrow", (element) => new RotatingArrow(element));
};
init();
