import { initComponent } from "../../utilities/common";

// TODO: remove debugs which are hidden behind a prop. With how tricky this is I can see the debugging being useful as we refine this, so want to leave them. But being hidden behind the prop at least doesn't normally output to the user
export default class MakeFit {
  constructor(elems, props = {}) {
    this.props = props;
    this.elems = elems;
    if (!elems.length) return;
    this.debounce = "";
    const { debug } = props;

    // loop through the elems and set some stuff up one time
    elems.forEach((elem) => {
      let alsoAddClassTo = this.props.alsoAddClassTo || "";
      let elemsToAddTo = [elem];
      elem.sizeClasses =
        props.sizeClasses || elem.dataset.makefitSizeclasses || "small";
      elem.fitWithin = props.fitWithin || elem.parentElement;
      elem.fitWithin.caller = elem;
      const images = elem.fitWithin.querySelectorAll("img");
      images.forEach((img) => {
        // update when any img inside the fitWithin loads
        img.addEventListener("load", () => this.update(elem));
      });

      // allow external scripts to run the makeFit update if needed
      elem.makeFit = (allowSync) => this.update(elem, allowSync);

      // if there are other elements to add/remove a class to/from, figure that out once
      if (alsoAddClassTo) {
        if (typeof alsoAddClassTo === "function") {
          // this allows for it to be a function to be relative to the current element
          alsoAddClassTo = alsoAddClassTo(elem);
        }
        // if it was a single element passed in via the prop, or somethign returned in the above function, turn it into an array
        elemsToAddTo = elemsToAddTo.concat(alsoAddClassTo);
      }

      elem.addClass = (theClass) => {
        if (typeof theClass !== "object") theClass = [theClass];
        elemsToAddTo.forEach((applyTo) => {
          debug && console.log(`adding ${theClass} to`, applyTo);
          applyTo.classList.add(...theClass);
        });
      };

      elem.removeClass = (theClass) => {
        elemsToAddTo.forEach((applyTo) => {
          debug && console.log(`removing ${theClass} from`, applyTo);
          applyTo.classList.remove(...theClass);
        });
      };
    });

    // fluid elements can resize based on reize or device rotation, re-evaluate after each
    if (typeof ResizeObserver === "function") {
      // ResizeObserver only fires when an element changes size, not when the window changes size which may not change the child elements https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver
      const resizeObserver = new ResizeObserver((entries) => {
        for (let entry of entries) {
          this.update(entry.target.caller);
        }
      });
      elems.forEach((elem) => {
        // track what the elem is supposed to fit within, not the elem itself
        resizeObserver.observe(elem.fitWithin);
      });
    } else {
      // TODO: remove window resize once Safari supports ResizeObserver https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver
      window.addEventListener("resize", () => {
        clearTimeout(this.debounce);
        this.debounce = setTimeout(() => {
          this.update();
        }, 100);
      });
      window.addEventListener("orientationchange", () => this.update());
      this.update();
    }
  }
  update = () => {
    let classesUsed = [];

    // loop through elements tracking the classes each one needs
    this.elems.forEach((elem) => {
      const returnedClasses = this.checkIndividualElement(elem);
      classesUsed = classesUsed.concat(returnedClasses);
    });

    // once through them all go back and apply the ones that were needed by any element to all other elements if we are syncing them
    if (this.props.sync) {
      this.elems.forEach((elem) => {
        elem.addClass(classesUsed);
      });
    }
  };

  checkIndividualElement = (elem) => {
    let sizeClasses = (
      elem.dataset.makefitSizeclasses ||
      this.props.sizeClasses ||
      "small"
    ).split(" ");
    let classesUsed = []; // track what classes are used from list

    // first remove any current classes so we start full size
    elem.removeClass(sizeClasses);

    // loop through each class
    sizeClasses.forEach((sizeClass) => {
      // only apply it if the element doesn't currently fit
      if (this.elemTooBig(elem)) {
        elem.addClass(sizeClass);
        classesUsed.indexOf(sizeClass) === -1 && classesUsed.push(sizeClass);
      }
    });
    return classesUsed; // return the classes that were used
  };

  elemTooBig = (elem) => {
    const {
      fitWithin = elem.parentElement, // default to parent unless passed in
      cushion = 0, // sometimes you need to allow for an extra few pixels
      debug
    } = this.props;

    const fitWithinH = fitWithin.clientHeight + cushion;
    const fitWithinW = fitWithin.clientWidth + cushion;
    const elemH = elem.scrollHeight; // use scrollHeight to also check dimensions of children which may be breaking out of a parent but the parent is restricting height
    const elemW = elem.scrollWidth; // same for width
    debug &&
      console.log({ fitWithinH }, { fitWithinW }, { elemH }, { elemW }, 4);
    // if the elem doesn't fit within the bounds of the fitWithin element, then apply the current class
    return elemH > fitWithinH || elemW > fitWithinW;
  };
}

export const init = () => {
  const elements = [];
  initComponent("make-fit", (element) => elements.push(element));

  new MakeFit(elements, {
    // debug: true
    // sizeClasses: "fred george wilma"
  });
};
init();
