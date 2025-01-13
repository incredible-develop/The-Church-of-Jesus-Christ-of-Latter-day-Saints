import styles from "./styles.css";
import typographyStyles from "../typography/critical.css";
import { layoutInner, layoutOuter } from "components/layout";
import background from "components/background";
import icon from "../icon";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "audio-player");
};

export const component = (props) => {
  const {
    audio: { audioSrc = "" },
    trackName = "",
    artistName = "",
    fileName = "",
    color = "Light",
    ariaLabels: {
      volume = "volume",
      replayTen = "replay ten seconds",
      playPause = "play/pause",
      forwardTen = "forward ten seconds",
      download = "download"
    }
  } = props;
  const trackNameTag = trackName
    ? `<div track-name class="${styles.trackName} ${typographyStyles.h5}">${trackName}</div>`
    : "";
  const artistNameTag = artistName
    ? `<div class="${styles.artistName} ${typographyStyles.h5}">${artistName}</div>`
    : "";
  // TODO: volume controls are not supported yet, but could be added in the future if it becomes important
  const volumeBtn = volume
    ? `<button class="${styles.ctrlBtn}" aria-label="${volume}">${icon({
        name: "volume"
      })}</button>`
    : "";
  const replayTenBtn = replayTen
    ? `<button class="${
        styles.ctrlBtn
      }" replay-ten aria-label="${replayTen}">${icon({
        name: "replay-ten"
      })}</button>`
    : "";
  const playPauseBtn = playPause
    ? `<button class="${
        styles.ctrlBtn
      }" play-btn aria-label="${playPause}">${icon({
        name: "play"
      })}${icon({ name: "pause" })}</button>`
    : "";
  const forwardTenBtn = forwardTen
    ? `<button class="${
        styles.ctrlBtn
      }" forward-ten aria-label="${forwardTen}">${icon({
        name: "forward-ten"
      })}</button>`
    : "";
  const downloadBtn = download
    ? `<a class="${
        styles.ctrlBtn
      }" download-btn aria-label="${download}" href="${audioSrc}" target="_blank" download="${fileName}">${icon(
        {
          name: "download"
        }
      )}</a>`
    : "";
  // prettier-ignore
  return `
  <div data-type="audio-player" class="${styles.audioPlayer} ${styles["fore" + color]} ${layoutOuter(props)}">
    ${background(props)}
    <div class="${layoutInner(props)}">
      ${trackNameTag}
      ${artistNameTag}
      <audio controls src="${audioSrc}" preload="none"></audio>
      <div class="${styles.timeDisplay}">
        <span current-time-display class="${styles.time}">00:00</span>
        <div class="${styles.slideContainer}">
          <div class="${styles.emptyTrack}"></div>
          <div buffered class="${styles.buffered}"></div>
          <div current-time class="${styles.currentTime}"></div>
          <input class="${styles.rangeInput}" min="0" max="100" step="0.01" value="0" type="range">
        </div>
        <span duration-display class="${styles.time}"></span>
      </div>
      <div class="${styles.buttons}">
        <div class="${styles.btnGroup} ${styles.startBtns}">
          <!--${volumeBtn}-->
        </div>
        <div class="${styles.btnGroup} ${styles.centerBtns}">
          ${replayTenBtn}
          ${playPauseBtn}
          ${forwardTenBtn}
        </div>
        <div class="${styles.btnGroup} ${styles.endBtns}">
          ${downloadBtn}
        </div>
      </div>
    </div>
  </div>`;
};
