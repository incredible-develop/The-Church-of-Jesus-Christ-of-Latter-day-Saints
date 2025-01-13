import { callbackWhenInView, initComponent } from "../../utilities/common";
var settings = {
  th: 200,
  animated: true,
  ani: "data-src-animated",
  ret: "data-src-retina",
  src: "data-src",
  srcset: "data-srcset"
};

var retina = window.devicePixelRatio > 1,
  attrib = retina ? settings.ret : settings.src;

export const unveil = function (image) {
  var node = image.tagName,
    source = image.getAttribute(attrib),
    srcset = image.getAttribute(settings.srcset),
    // TODO: source is defined two lines up, need to review which one is used and remove the other. Didn't want to be invasive when doing a storybook update though
    source = // eslint-disable-line
      source ||
      image.getAttribute(settings.src) ||
      image.getAttribute(settings.ret);
  if (settings.animated === true) {
    source = image.getAttribute(settings.ani) || source;
  }
  if (source || node === "PICTURE") {
    var parent = image.parentElement,
      parentWidth = parent.offsetWidth,
      parentHeight = parent.offsetHeight,
      upscale = Math.max(
        parentWidth > 100 ? 1.25 : 1.75,
        window.devicePixelRatio * 0.75 // if on a retina device, use their pixel ratio, but doesn't need to be full size so reduce it a little since we will also go one size larger below
      );

    if (node === "IMG") {
      image.setAttribute("src", source);
      if (srcset) {
        image.setAttribute("srcset", srcset);
      }
    } else if (node === "PICTURE") {
      var img = image.querySelector("img");
      var imgSrc =
        img.getAttribute(attrib) ||
        img.getAttribute(settings.src) ||
        img.getAttribute(settings.ret);
      img.dataset.srcset && img.setAttribute("srcset", img.dataset.srcset);
      img.setAttribute("src", imgSrc);
      var sources = image.querySelectorAll("source");
      let doOneMore = false;
      // we need to reverse the order of the sources since they come into the DOM from largest to smallest but we need to show one larger than the smallest one that meets the mediaWidth and so need to know which was the last smaller one that fit to go one more
      [].slice
        .call(sources, 0)
        .reverse()
        .forEach(function (e) {
          const media = e.getAttribute("media").split(", "),
            mediaWidth = media[0].slice(12, -3),
            mediaHeight = media[1].slice(13, -3);
          const bigEnough =
            parentWidth * upscale >= mediaWidth ||
            parentHeight * upscale >= mediaHeight;
          if (bigEnough || doOneMore) {
            // allow the source if it is bigEnough or if it is one larger that the last one that fit. If the target size was 500 but the image sizes were 480 and 640, then 480 would be included and 600 wouldn't be, then the 480 would get stretched. Allowing one larger than the target Size covers that situation
            e.setAttribute("srcset", e.getAttribute(settings.srcset));
            doOneMore = bigEnough;
          }
        });
    } else {
      image.style.backgroundImage = "url(" + source + ")";
    }
    // TODO: evaluate removing the below, callback is never defined anywhere so I can't see how it would be missed
    if (typeof callback === "function") callback.call(this); // eslint-disable-line
  }
  image.setAttribute("data-unveil", false);
  if ("objectFit" in document.documentElement.style === false) {
    Array.prototype.forEach.call(
      document.querySelectorAll("img[data-object-fit]"),
      function (image) {
        (image.runtimeStyle || image.style).background =
          'url("' +
          image.getAttribute("data-src") +
          '") no-repeat 50%/' +
          (image.currentStyle
            ? image.currentStyle["object-fit"]
            : image.getAttribute("data-object-fit"));

        image.src =
          "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='" +
          image.width +
          "' height='" +
          image.height +
          "'%3E%3C/svg%3E";
      }
    );
  }
};

export const init = () => {
  let images = [];
  initComponent(
    "unveil",
    (image) => {
      images.push(image);
    },
    '[data-unveil="true"]'
  );
  callbackWhenInView({ elems: images, callback: unveil });
};
init();
