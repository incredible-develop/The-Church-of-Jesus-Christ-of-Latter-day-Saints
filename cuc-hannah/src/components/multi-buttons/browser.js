import { initComponent } from "../../utilities/common";

export default class MultiButtons {
  constructor(element) {
    this.element = element;
    this.buttons = this.element.querySelectorAll("a");
    this.maxBtnWidth = 0;
    this.setContainerWidth();
  }

  getMaxBtnWidth = () => {
    for (const element of this.buttons) {
      let currentWidth = element.clientWidth;

      if (this.maxBtnWidth < currentWidth) {
        this.maxBtnWidth = currentWidth;
      }
    }
    return this.maxBtnWidth;
  };
  setContainerWidth = () => {
    const w = this.getMaxBtnWidth();
    for (const element of this.buttons) {
      element.setAttribute("style", `width: ${w}px`);
    }
  };
}

export const init = () => {
  initComponent("multi-buttons", (element) => new MultiButtons(element));
};
init();
