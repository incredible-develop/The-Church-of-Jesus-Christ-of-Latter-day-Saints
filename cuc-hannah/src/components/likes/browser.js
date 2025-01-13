import SimpleCounter from "../simple-counter/browser.js";
import hashFnv32a from "../hashfnv32a/browser.js";
import CounterGroup from "../counter-group/browser.js";
import { recordInteraction } from "../../utilities/analytics.js";
import { initComponent } from "../../utilities/common";

export default class Likes {
  constructor(element) {
    this.element = element;
    this.id = this.element.dataset.counterId;
    this.group = this.element.dataset.counterGroup;
    this.count = this.element.querySelector("[data-count]");
    this.hiddenCount = this.element.querySelector("[hidden-count-label]");
    this.toggle = this.element.querySelector('[data-type="toggle"]');

    this.simpleCounter = new SimpleCounter({
      group: this.group,
      id: this.id,
      onDataIsSet: () => {
        this.disableButton();
      },
      updateSocialCounter: (count) => {
        this.updateSocialCounter(count);
      },
      counter: element
    });

    this.enableButton();
    this.simpleCounter.checkForData();
  }

  updateSocialCounter(count) {
    this.count.innerHTML = count;
    if (this.element.getAttribute("aria-live") === "assertive") {
      this.toggle.setAttribute(
        "aria-label",
        this.toggle.dataset.counterUpdatedAriaLabel
      );
      setTimeout(() => {
        this.element.setAttribute("aria-live", "off");
      }, 1000);
    }
  }

  disableButton() {
    if (this.toggle) {
      this.toggle.style.pointerEvents = "none";
      this.toggle.dataset.toggled = "on";
    }
  }

  enableButton() {
    if (this.toggle && this.group && this.id) {
      this.toggle.addEventListener("click", () => {
        this.element.setAttribute("aria-live", "assertive");
        this.disableButton();
        const currentTime = Math.round(new Date().getTime()) + "";
        const hashed = hashFnv32a(currentTime, true, "WuN9P62Arf2E"); //random seed here
        this.simpleCounter
          .incrementSocialCounter(currentTime, hashed)
          .catch(() => {
            this.toggle.style.pointerEvents = "";
            this.toggle.dataset.toggled = "";
            this.simpleCounter.checkForData();
          });
        recordInteraction(this.element, "Content Like", "contentLike");
      });
    } else {
      this.toggle.dataset.toggled = "on";
    }
  }
}

export const init = () => {
  const likes = [];
  initComponent("likes", (element) => {
    likes.push(new Likes(element));
  });
  new CounterGroup(likes, 60000).watch();
};
init();
