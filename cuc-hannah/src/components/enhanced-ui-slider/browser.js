import Flickity from "../flickity/flickity.pkgd.js";
import custEvent from "../custom-event/browser";
import { stepChangeAnalytics } from "../../utilities/analytics.js";
import {
  callbackWhenInView,
  initComponent,
  setTabIndex
} from "../../utilities/common";

const carouselSelector = '[data-type="enhanced-ui-slider-flickity"]';
const primContSelector = "[is-primary-content]";
const topArrowSelctors = {
  prev: '[aria-label="previous"]',
  next: '[aria-label="next"]'
};
const btmArrowSelctors = {
  prev: "[btm-nav-prev]",
  next: "[btm-nav-next]"
};
const btmArrowsTextSelector = "[btm-nav-label]";
const mediaPlayerSelector = '[data-type="media-player"]';
const mediaBlockSelector = '[data-type="media-block"]';
const limitWidthClass = "enhanced-ui-slider_limitWidth";
const shrinkMarginPrevious = "shrink-margin-previous";
const shrinkMarginNext = "shrink-margin-next";
const carouselTile = "flickity_carouselTile";
export default class EnhancedUISlider {
  constructor(element) {
    this.element = element;
    this.carouselElem = this.element.querySelector(carouselSelector);
    this.carouselTiles = this.carouselElem.querySelectorAll(`.${carouselTile}`);
    this.btmPrevArrow = this.element.querySelector(btmArrowSelctors.prev);
    this.btmNextArrow = this.element.querySelector(btmArrowSelctors.next);
    this.btmArrowsText = this.element.querySelector(btmArrowsTextSelector);
    this.previousIndex = 0;
    this.viewedSteps = [];
    this.extraData = JSON.parse(this.element.dataset.browser);

    this.flktyOptions = {
      pageDots: false,
      wrapAround: this.extraData.wrapAround,
      prevNextButtons: this.extraData.prevNextButtonsExist,
      adaptiveHeight: true,
      rightToLeft:
        document.querySelector("html").getAttribute("dir") === "rtl" || false
    };

    //removes animation of slide motion if preferences for reduced motion are set on operating system
    const media = matchMedia("(prefers-reduced-motion)");
    if (media.matches) {
      this.flktyOptions.selectedAttraction = 1;
      this.flktyOptions.friction = 1;
    }

    this.resetFlickity(); // creates this.flkty

    this.btmPrevArrow.addEventListener("click", () =>
      this.flkty.previous(this.flktyOptions.wrapAround)
    );
    this.btmNextArrow.addEventListener("click", () =>
      this.flkty.next(this.flktyOptions.wrapAround)
    );
    this.topPrevArrow = this.carouselElem.querySelector(topArrowSelctors.prev);
    this.topNextArrow = this.carouselElem.querySelector(topArrowSelctors.next);

    if (
      typeof ResizeObserver === "function" &&
      this.topPrevArrow &&
      this.topNextArrow
    ) {
      const ro = new ResizeObserver(() => this.positionTopArrows());
      ro.observe(this.element);
    } else if (this.topPrevArrow && this.topNextArrow) {
      // TODO: Remove once safari supports ResizeObserver
      window.addEventListener("resize", () => this.positionTopArrows());
      this.positionTopArrows();
    }
    element.updateFlkty = () => {
      // fire a bit later after CSS has had a chance to be parsed
      setTimeout(() => this.flkty.resize(), 100);
    };

    element.cssLoadedCallback = () => {
      element.updateFlkty();
      callbackWhenInView({
        elems: [this.element],
        callback: () => element.updateFlkty()
      });
    };

    if (element.hasAttribute("css-loaded")) {
      element.updateFlkty();
    }

    this.lastIndex = 0;
    this.addObservers(); // these should only be added once on the first render
    setTabIndex(this.carouselTiles, 0);
    // by default the fkty element isnt tabbable but we want it to be for accessibility
    setTabIndex([this.flkty.element], 0, "", true);
  }

  resetFlickity() {
    if (this.flkty) this.flkty.destroy();
    this.flkty = new Flickity(this.carouselElem, this.flktyOptions);
    this.previousIndex = this.flkty.selectedIndex;
    this.flktyCells = this.flkty.getCellElements();
    this.numberOfCells = this.flktyCells.length;
    // There's currently some bugs with Flickity with 3 cells and wrapAround being true
    // Submitted a bug to Flickity: https://github.com/metafizzy/flickity/issues/1086
    // Limiting the width to 1280px of the flickity wrapper is a bandaid fix for now
    if (this.numberOfCells <= 3 && this.flkty.options.wrapAround) {
      this.carouselElem.classList.add(limitWidthClass);
      this.flkty.resize();
    } else this.carouselElem.classList.remove(limitWidthClass);
    if (this.numberOfCells > 3) this.shrinkSecondMargin();

    if (this.numberOfCells) {
      this.btmPrevArrow.removeAttribute("hidden");
      this.btmNextArrow.removeAttribute("hidden");
    } else {
      this.btmPrevArrow.setAttribute("hidden", "");
      this.btmNextArrow.setAttribute("hidden", "");
    }

    this.flkty.on("select", () => {
      let currentIndex = this.flkty.selectedIndex;
      this.updateBottomNav();
      if (this.numberOfCells > 3) this.shrinkSecondMargin();
      this.checkViewportHeight();
      // timeout is important to make sure "pause-all-players" fires after user is done clicking, additionally prevents analytics from triggering on pageLoad
      setTimeout(() => {
        custEvent(window, "pause-all-players");

        // Analytics for changing slides
        if (
          this.previousIndex !== currentIndex &&
          !this.viewedSteps.includes(currentIndex)
        ) {
          this.sendAnalytics(currentIndex);
        }
      });
      setTabIndex([...this.carouselTiles], currentIndex);
    });

    this.updateBottomNav();
  }

  positionTopArrows() {
    const primaryContent =
      this.flkty.selectedElement.querySelector(primContSelector);
    const mediaBlock =
      this.flkty.selectedElement.querySelector(mediaBlockSelector);

    const topMargin = window
      .getComputedStyle(mediaBlock)
      .marginTop.replace("px", "");

    const halfHeight = primaryContent.clientHeight / 2;
    const distanceFromTop = parseInt(halfHeight) + parseInt(topMargin);

    [this.topPrevArrow, this.topNextArrow].forEach(
      (arrow) => (arrow.style.top = distanceFromTop + "px")
    );
  }

  updateBottomNav() {
    if (this.numberOfCells) {
      const index = this.flkty.selectedIndex;
      this.lastIndex = index;
      if (!this.flktyOptions.wrapAround) {
        if (index === 0) this.btmPrevArrow.disabled = true;
        else this.btmPrevArrow.disabled = false;
        if (index === this.numberOfCells - 1) this.btmNextArrow.disabled = true;
        else this.btmNextArrow.disabled = false;
      }
      // prettier-ignore
      this.btmArrowsText.innerHTML = `${index + 1} / ${this.numberOfCells}`;
    } else this.btmArrowsText.innerHTML = "";
  }

  get videoPlayingObserver() {
    return new MutationObserver((mutations) => {
      mutations?.array?.forEach(() => {
        this.checkViewportHeight();
      });
    });
  }

  get videoResizeObserver() {
    return new ResizeObserver(() => this.checkViewportHeight());
  }

  get hiddenObserver() {
    /*
      If the carousel cell is hidden, we move it outside of the carouselElem so it
      doesn't affect flickity. Otherwise, we put it back inside the carouselElem.
     */
    return new MutationObserver((mutations) => {
      for (let mutation of mutations) {
        const node = mutation.target;
        const isHidden = node.getAttribute("hidden") !== null;
        // move outside of carouselElem
        if (isHidden) this.element.appendChild(node);
        // move inside carouselElem
        else this.carouselElem.appendChild(node);
        this.resetFlickity();
      }
    });
  }

  addObservers() {
    const videoPlayingObserver = this.videoPlayingObserver;
    const videoResizeObserver = this.videoResizeObserver;
    const hiddenObserver = this.hiddenObserver;
    this.flktyCells.forEach((cell) => {
      const mediaPlayer = cell.querySelector(mediaPlayerSelector);
      if (mediaPlayer) {
        videoPlayingObserver.observe(mediaPlayer, {
          attributeFilter: ["playing"]
        });
        if (typeof ResizeObserver === "function") {
          videoResizeObserver.observe(mediaPlayer);
        } else {
          // TODO: Remove once safari supports ResizeObserver
          window.addEventListener("resize", () => this.checkViewportHeight());
        }
      }
      hiddenObserver.observe(cell, {
        attributeFilter: ["hidden"]
      });
    });
  }

  checkViewportHeight() {
    let cellHeight = this.flkty.selectedElement.offsetHeight;
    let viewport = this.flkty.viewport;

    if (cellHeight > viewport.offsetHeight) {
      viewport.style.height = `${cellHeight}px`;
    }
  }

  shrinkSecondMargin() {
    const numFromSelected = 2;
    if (this.previousSlide)
      this.previousSlide.removeAttribute(shrinkMarginPrevious);
    if (this.nextSlide) this.nextSlide.removeAttribute(shrinkMarginNext);
    const selectedIndex = this.flkty.selectedIndex;
    const len = this.numberOfCells;
    const prevIndex = (((selectedIndex - numFromSelected) % len) + len) % len;
    const nextIndex = (((selectedIndex + numFromSelected) % len) + len) % len;
    this.previousSlide = this.flktyCells[prevIndex];
    this.nextSlide = this.flktyCells[nextIndex];
    this.previousSlide.setAttribute(shrinkMarginPrevious, "");
    this.nextSlide.setAttribute(shrinkMarginNext, "");
  }

  sendAnalytics(currentIndex) {
    stepChangeAnalytics(
      this.element,
      this.flkty.selectedElement,
      currentIndex,
      this.numberOfCells,
      this.element.dataset.type
    );
    this.viewedSteps.push(currentIndex);
    this.previousIndex = currentIndex;
  }
}

export const setUpEnhancedSlider = (el) => {
  const slider = new EnhancedUISlider(el);
  el.addEventListener("keyup", () => {
    el.setAttribute("used-keyboard", "");
  });
  el.setAttribute("initialized", "");
  const callback = () => {
    slider.resetFlickity();
  };
  if (el.offsetParent === null) {
    //When the ui slider is initially hidden from the user (for example when it is within a modal), set up ui slider class when it is visible to the user
    callbackWhenInView({
      elems: [el],
      callback
    });
  } else callback();

  // When the slider is first viewed it will trigger analytics for viewing the first slide
  callbackWhenInView({
    elems: [el],
    callback: () => {
      slider.sendAnalytics(slider.flkty.selectedIndex);
    },
    rootMargin: "0px",
    threshold: "0.5"
  });
};

export const init = () => {
  initComponent(
    "enhanced-ui-slider",
    (element) => new setUpEnhancedSlider(element)
  );
};
init();
