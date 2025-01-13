import styles from "../flickity/styles.css";
import articleStyles from "../article-tile/styles.css";
import Flickity from "../flickity/flickity.pkgd.js";
import { callbackWhenInView, initComponent } from "../../utilities/common";

export default class TileSwipe {
  constructor(swipe) {
    const elem = swipe.querySelector("[data-swipe-wrapper]");

    const rightToLeft = document.dir === "rtl" || false;
    const cellAlign = rightToLeft ? "right" : "left";

    // TODO: This also runs in the resizer function, so it could probably be eliminated
    let flkty = new Flickity(elem, {
      // options
      wrapAround: false,
      adaptiveHeight: false,
      cellAlign,
      pageDots: false,
      contain: true,
      //prevNextButtons: false,
      dragThreshold: 10,
      rightToLeft,
      arrowShape:
        "M7.77719121,11.4622538 C7.4742696,11.7567609 7.4742696,12.2432391 7.77719121,12.5377462 L13.1771912,17.7877462 C13.4741802,18.0764855 13.9490069,18.0697978 14.2377462,17.7728088 C14.5264855,17.4758198 14.5197978,17.0009931 14.2228088,16.7122538 L9.36515845,12.0104618 L14.2228088,7.28774618 C14.5197978,6.99900686 14.5264855,6.52418022 14.2377462,6.2271912 C13.9490069,5.93020218 13.4741802,5.92351448 13.1771912,6.21225381 L7.77719121,11.4622538 L7.77719121,11.4622538 Z"
    });

    flkty.on("change", (index) => {
      padIndex(flkty.slides[index].target);
    });

    const arrows = elem.querySelectorAll("svg");
    arrows.forEach((arrow) => {
      arrow.setAttribute("viewBox", "0 0 24 24");
    });

    let prevent = function (el) {
      el.preventDefault();
    };

    const padIndex = (xValue) => {
      // Check if the difference between the current X position and the position it should be at is significantly different
      // Prevents the flkty index from progressing past a point where the slider isn't actually moving anymore
      if (Math.abs(flkty.cells[flkty.selectedIndex].x - xValue) > 10) {
        const cells = flkty.cells.map((cell) => cell.x);
        const correctX = cells.reduce(function (prev, curr) {
          return Math.abs(curr - xValue) < Math.abs(prev - xValue)
            ? curr
            : prev;
        });
        flkty.selectedIndex = cells.indexOf(correctX);
        flkty.nextButton.element.style.opacity = 0;
      } else {
        flkty.nextButton.element.style.opacity = 1;
      }
    };

    let reInit = function () {
      flkty.on("scroll", function () {
        const anchors = elem.querySelectorAll("a");
        Array.prototype.forEach.call(anchors, function (el) {
          el.addEventListener("click", prevent);
        });
      });

      flkty.on("settle", function () {
        const anchors = elem.querySelectorAll("a");
        Array.prototype.forEach.call(anchors, function (el) {
          el.removeEventListener("click", prevent);
        });
      });

      flkty.on("change", (index) => {
        padIndex(flkty.slides[index].target);
      });
    };

    let resizer = function () {
      let layout = elem.getAttribute("data-layout");
      if (layout === "emphasized") {
        elem.style.visibility = "hidden";
        let width = window.innerWidth;
        let slider = elem.querySelector(
          `.${styles.flickitySlider.split(" ")[0]}`
        );
        if (width < 480) {
          const groups = elem.querySelectorAll(`.${styles.rowGroup}`);
          groups.forEach((group) => {
            const html = group.innerHTML;
            slider.insertAdjacentHTML("beforeend", html);
            group.remove();
          });
          elem.classList.remove(`${styles.emphasized}`);
          elem.classList.remove(`${articleStyles.emphasized}`);
        } else {
          let tilegroup = elem.querySelectorAll(`.${styles.rowGroup}`);
          let html = "";
          if (!(tilegroup.length > 0)) {
            let tiles = elem.querySelectorAll(
              `.${styles.rowTile.split(" ")[0]}`
            );
            let tileArr = Array.prototype.slice.call(tiles);
            let remaining = tileArr.splice(1);
            remaining.forEach((item, index) => {
              item.removeAttribute("style");
              if (index % 2 === 0) {
                html += `
                  <div class="${styles.rowGroup}">
                    ${item.outerHTML}`;

                if (index === tiles.length - 1) {
                  html += `</div>`;
                }
              } else {
                html += `${item.outerHTML}</div>`;
              }
              item.remove();
            });
            slider.insertAdjacentHTML("beforeend", html);
            elem.classList.add(`${styles.emphasized}`);
            elem.classList.add(`${articleStyles.emphasized}`);
          }
        }

        flkty.destroy();
        flkty = new Flickity(elem, {
          // options
          wrapAround: false,
          adaptiveHeight: false,
          cellAlign,
          pageDots: false,
          contain: true,
          //prevNextButtons: false,
          dragThreshold: 10,
          rightToLeft,
          arrowShape:
            "M7.77719121,11.4622538 C7.4742696,11.7567609 7.4742696,12.2432391 7.77719121,12.5377462 L13.1771912,17.7877462 C13.4741802,18.0764855 13.9490069,18.0697978 14.2377462,17.7728088 C14.5264855,17.4758198 14.5197978,17.0009931 14.2228088,16.7122538 L9.36515845,12.0104618 L14.2228088,7.28774618 C14.5197978,6.99900686 14.5264855,6.52418022 14.2377462,6.2271912 C13.9490069,5.93020218 13.4741802,5.92351448 13.1771912,6.21225381 L7.77719121,11.4622538 L7.77719121,11.4622538 Z"
        });
        const arrows = elem.querySelectorAll("svg");
        arrows.forEach((arrow) => {
          arrow.setAttribute("viewBox", "0 0 24 24");
        });
        elem.style.visibility = "visible";
        reInit();
      }
    };

    const wrapper = elem.querySelector(`.${styles.flickitySlider}`);
    resizer(wrapper);

    // TODO There is an issue inside the flickity scroll event listener. The scroll event listener is re-added every time reinit() runs on line 133.
    // A better solution is probably refactoring this component to act more like a JS Class.
    swipe.resize = () => {
      resizer(wrapper);
    };

    if (typeof ResizeObserver === "function") {
      const ro = new ResizeObserver(swipe.resize);
      ro.observe(elem);
    } else {
      window.addEventListener("resize", swipe.resize);
    }
    swipe.updateFlkty = () => {
      // fire a bit later after CSS has had a chance to be parsed
      setTimeout(() => flkty.resize(), 100);
    };

    swipe.cssLoadedCallback = () => {
      swipe.updateFlkty();
      callbackWhenInView({
        elems: [swipe],
        callback: () => swipe.updateFlkty()
      });
    };
    elem.addEventListener("keyup", () => {
      elem.setAttribute("used-keyboard", "");
    });
  }
}

export const init = () => {
  initComponent("tile-swipe", (element) => new TileSwipe(element));
};
init();
