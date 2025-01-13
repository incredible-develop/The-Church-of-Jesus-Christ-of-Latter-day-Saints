import { initComponent } from "../../utilities/common";
export default class ProgressCircle {
  constructor(element) {
    this.element = element;
    // check to see if the circle is in an anchor
    const aWrapper = element.closest("a");
    if (aWrapper) {
      // if so, look at where it is pointing to get the path to look up in localStorage for progress on that remote page
      const href = aWrapper.getAttribute("href");

      // look in localStorage for the progress on that page
      const remoteProgress = localStorage.getItem(`track-${href}`);

      // make sure it has the right format
      if (remoteProgress && remoteProgress.indexOf("/") !== -1) {
        const [remoteProgressComplete, remoteProgressTotal] =
          remoteProgress.split("/");
        // if it does, set the progress circle to that value
        const percent = (remoteProgressComplete / remoteProgressTotal) * 100;
        element.style.setProperty("--progress-percentage", `${percent}%`);
        if (percent === 100) {
          element.setAttribute("complete", "");
        }
        element.setAttribute(
          "title",
          `${remoteProgressComplete}/${remoteProgressTotal}`
        );
      }
    }
  }
}
export const init = () => {
  initComponent("progress-circle", (element) => new ProgressCircle(element));
};
init();
