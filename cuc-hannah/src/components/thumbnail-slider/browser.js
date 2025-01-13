import {
  callbackWhenInView,
  initComponent,
  setTabIndex
} from "../../utilities/common";
import { recordInteraction } from "../../utilities/analytics";

export default class thumbnailSlider {
  constructor(element) {
    this.element = element;
    this.scrollable = element.querySelector(
      `[data-type="thumbnail-slider-scrollable"]`
    );
    this.arrows = element.querySelectorAll(
      `[data-type="thumbnail-slider-arrow-container"]`
    );
    this.galleryItems = element.querySelectorAll(`[data-type="gallery-item"]`);

    [...this.galleryItems].forEach((galleryItem) => {
      galleryItem.addEventListener("focus", () =>
        galleryItem.setAttribute("focus-visible", "")
      );
      galleryItem.addEventListener("blur", () =>
        galleryItem.removeAttribute("focus-visible")
      );
      galleryItem.addEventListener("keypress", (keyboardEvent) => {
        if (keyboardEvent.key === "Enter" || keyboardEvent.key === " ") {
          this.selectGalleryItem({ galleryItem, entryKey: keyboardEvent.key });
        }
      });
    });

    const selectFirstItem =
      this.element.dataset.selectFirstItem === "true" ? true : false;
    if (selectFirstItem)
      this.selectGalleryItem({
        galleryItem: this.galleryItems[0],
        entryKey: undefined,
        shouldScroll: false,
        shouldFocus: false
      });

    this.arrows[0].addEventListener("click", () => this.scroll(-1)); // scroll backwards
    this.arrows[1].addEventListener("click", () => this.scroll(1)); // scroll forwards
    this.scrollable.addEventListener("scroll", () => this.toggleArrows());
    this.scrollable.addEventListener("keydown", (event) => {
      //If a user uses the keyboard to navigate through the thumbnails, prevent scrolling so that a user can select each thumbnail at a time
      const currentIndex = [...this.galleryItems].indexOf(
        this.selectedGalleryItem
      );
      if (
        (event.code === "ArrowLeft" && currentIndex !== 0) ||
        (event.code === "ArrowRight" &&
          currentIndex !== this.galleryItems.length - 1)
      ) {
        event.preventDefault();
        const newIndex =
          event.code === "ArrowLeft" ? currentIndex - 1 : currentIndex + 1;
        this.selectGalleryItem({ galleryItem: this.galleryItems[newIndex] });
      }
    });
    this.checkLangDir();

    this.mouseDown = false;
    this.didDrag = false;
    this.smallDrag = false;
    this.cancelSelection = false;
    this.scrollable.addEventListener("mousedown", (e) =>
      this.handleMouseDown(e)
    );
    this.element.addEventListener("mousemove", (e) => this.handleMouseMove(e));
    this.boundMouseUp = this.handleMouseUp.bind(this); // enables removing of window event listener

    // When the slider is first viewed it will trigger analytics for viewing the first thumbnail
    callbackWhenInView({
      elems: [this.element],
      callback: () => {
        recordInteraction(
          this.element.querySelector("[use-analytics"),
          "",
          "click"
        );
      },
      rootMargin: "0px",
      threshold: "0.5"
    });
  }

  toggleArrows() {
    const needsArrows =
      this.scrollable.scrollWidth > this.scrollable.clientWidth;
    if (needsArrows) {
      /* Display at least one arrow when there is an overflow */
      if (this.currPos <= 0) {
        /* When position is 0 */
        this.backArrow.style.visibility = "hidden";
        this.forArrow.style.visibility = "visible";
      } else if (
        this.currPos + this.scrollable.clientWidth >=
        this.scrollable.scrollWidth
      ) {
        /* When at the max position */
        this.backArrow.style.visibility = "visible";
        this.forArrow.style.visibility = "hidden";
      } else {
        /* Anywhere inbetween */
        this.backArrow.style.visibility = "visible";
        this.forArrow.style.visibility = "visible";
      }
    } else {
      /* Do not display arrows when there is no overflow */
      this.backArrow.style.visibility = "hidden";
      this.forArrow.style.visibility = "hidden";
    }
  }

  checkLangDir() {
    /* For RTL languages in firefox and safari */
    /* This won't change the event listeners, but it will only change arrow visibility */
    this.dir = this.element.closest("[dir]")
      ? this.element.closest("[dir]").getAttribute("dir")
      : "ltr";
    if (this.dir === "rtl" && this.currPos <= 0) {
      this.backArrow = this.arrows[1];
      this.forArrow = this.arrows[0];
    } else {
      this.backArrow = this.arrows[0];
      this.forArrow = this.arrows[1];
    }
    this.toggleArrows();
  }

  get currPos() {
    return this.dir === "rtl"
      ? Math.abs(this.scrollable.scrollLeft)
      : this.scrollable.scrollLeft;
  }

  scroll(dir) {
    const scrl = (this.scrollable.clientWidth / 2) * dir;
    if ("scrollBehavior" in document.documentElement.style)
      // chrome and firefox
      this.scrollable.scrollBy({
        left: scrl,
        top: 0,
        behavior: "smooth"
      });
    else {
      try {
        // safari
        this.scrollable.scrollBy(scrl, 0);
      } catch (error) {
        // edge
        this.scrollable.scrollLeft = this.currPos + scrl;
      }
    }
  }

  handleMouseDown(e) {
    e.preventDefault();
    this.mouseDown = true;
    window.addEventListener("mouseup", this.boundMouseUp);
  }

  handleMouseMove(e) {
    /* If the user is holding down the mouse and dragging the cursor, scroll inside of this.scrollable */
    if (this.mouseDown && e.movementX) {
      const movement = e.movementX * -1;
      if (Math.abs(e.movementX) < 3) {
        this.smallDrag = true;
      } else {
        this.smallDrag = false;
        this.cancelSelection = true;
      }
      this.didDrag = true;
      try {
        this.scrollable.scrollBy(movement, 0);
      } catch (error) {
        // edge
        this.scrollable.scrollLeft = this.currPos + movement;
      }
    }
  }

  handleMouseUp(e) {
    /* If the user clicked a gallery item, but is not currently dragging, focus on it */
    const galleryItem = e.target.closest(`[data-type="gallery-item"]`);
    if (
      (this.smallDrag || !this.didDrag) &&
      galleryItem &&
      !this.cancelSelection
    ) {
      galleryItem.focus();
      this.selectGalleryItem({ galleryItem });
    }
    this.mouseDown = false;
    this.didDrag = false;
    this.smallDrag = false;
    this.cancelSelection = false;
    window.removeEventListener("mouseup", this.boundMouseUp);
  }

  selectGalleryItem({
    galleryItem,
    entryKey = "Click",
    shouldScroll = true,
    shouldFocus = true
  }) {
    if (entryKey === " " || entryKey === "Enter") {
      galleryItem.setAttribute("focus-visible", "");
    } else {
      galleryItem.removeAttribute("focus-visible");
    }
    const event = new CustomEvent("gallery-item-select", {
      detail: {
        galleryId: galleryItem.getAttribute("data-gallery-id"),
        shouldScroll
      }
    });
    this.element.dispatchEvent(event);
    /* Mainly for styling */
    this.scrollable.setAttribute("data-child-selected", "");
    if (this.selectedGalleryItem) {
      this.selectedGalleryItem.removeAttribute("data-gallery-item-selected");
      galleryItem.removeAttribute("aria-selected");
    }
    this.selectedGalleryItem = galleryItem;
    galleryItem.setAttribute("data-gallery-item-selected", "");
    galleryItem.setAttribute("aria-selected", "true");
    setTabIndex(
      [...this.galleryItems],
      [...this.galleryItems].indexOf(galleryItem),
      shouldFocus,
      shouldFocus
    );
  }

  scrollIfNeeded(target) {
    const min = this.currPos;
    const max = min + this.scrollable.clientWidth;
    const tarMin = target.offsetLeft;
    const tarMax = target.offsetLeft + target.clientWidth;
    const ltMin = tarMin < min;
    const gtMax = tarMax > max;
    /* if one of the edges is not visible, scroll so it is visible */
    if (ltMin || gtMax)
      try {
        this.scrollable.scrollTo({
          behavior: "smooth",
          left: ltMin ? tarMin : min + (tarMax - max)
        });
      } catch (err) {
        this.scrollable.scrollLeft = ltMin ? tarMin : min + (tarMax - max);
      }
  }
}

export const init = () => {
  initComponent("thumbnail-slider", (element) => new thumbnailSlider(element));
};
init();
