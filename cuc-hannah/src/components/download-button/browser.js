export default class DownloadButton {
  constructor(props) {
    const {
      element /* required */,
      onClick /* required */,
      showProgress = (DL) => {
        DL.downloadIcon?.setAttribute("hidden", "");
        DL.loadingIcon?.removeAttribute("hidden");
      },
      onLoad = () => {},
      showComplete = (DL) => {
        DL.downloadIcon?.removeAttribute("hidden");
        DL.loadingIcon?.setAttribute("hidden", "");
      },
      onError = () => {}
    } = props;

    this.element = element;
    this.showProgress = () => showProgress(this);
    this.onClick = () => onClick(this);
    this.onLoad = () => onLoad(this);
    this.showComplete = () => showComplete(this);
    this.onError = (err) => onError(err, this);

    this.downloadIcon = this.element.querySelector(
      '[data-icon-name="download"]'
    );
    this.loadingIcon = this.element.querySelector(
      '[data-icon-name="loading-spinner"]'
    );

    this.element.addEventListener("click", () => this._onClick());
  }

  async _onClick() {
    try {
      this.showProgress();
      await this.onClick();
      await this.onLoad();
      this.showComplete();
    } catch (err) {
      this.showComplete();
      this.onError(err);
    }
  }
}
