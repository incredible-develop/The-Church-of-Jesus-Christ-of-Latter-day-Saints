import DownloadButton from "../download-button/browser";
import { initComponent } from "../../utilities/common";

export default class ImageBlock {
  constructor(element) {
    this.element = element;
    const mediaBlock = element.closest('[data-type="media-block"]');
    this.downloadLinks =
      mediaBlock?.querySelectorAll('[data-type="download-button"]') || [];

    this.setupDownloadLinks();
  }

  setupDownloadLinks() {
    this.downloadLinks.forEach(
      (dl) =>
        new DownloadButton({
          element: dl,
          onClick: () => {
            this.downloadImg(dl);
          }
        })
    );
  }

  downloadImg(downloadLink) {
    //Check if the download button has a download link src specified already, if not, use src from actual image block
    //When using the src from the image block, we already sort the highest resolution image first

    const link = document.createElement("a");
    const source = this.element.querySelector("picture source");
    link.href =
      downloadLink?.dataset?.downloadSrc ||
      `${source?.srcset || source?.dataset?.srcset}?download=true`;
    link.download = "";
    link.target = "_blank"; // just in case the download attr does not work
    this.element.appendChild(link);

    link.click();
    link.remove();
  }
}

export const init = () => {
  initComponent("image-block", (element) => new ImageBlock(element));
};
init();
