import renderIcon from "../icon/browser";
import {
  callbackWhenInView,
  initComponent,
  sendMediaAnalytics
} from "../../utilities/common";
import { events } from "../media-player/lds-media-player/events";
import dispatchCustomEvent from "../custom-event/browser";

export default class AudioPlayer {
  constructor(element) {
    this.element = element;

    this.bufferedEl = element.querySelector("[buffered]");
    this.currentTimeEl = element.querySelector("[current-time]");

    this.rangeTag = element.querySelector("input[type=range]");
    this.audioTag = element.querySelector("audio");
    this.audioTag.name = element.querySelector("[track-name]")?.innerText;

    this.currentTimeDisplay = element.querySelector("[current-time-display]");
    this.durationDisplay = element.querySelector("[duration-display]");

    this.setupListeners(element);

    // allows us to select the html element and element.pause()
    element.pause = () => this.pause();
    this.state = "paused";

    new renderIcon(element.querySelector('[data-icon-name="pause"]'));
  }

  set state(status) {
    if (status === "playing") {
      this.element.setAttribute("playing", "");
      this.audioTag.play();
      AudioPlayer.pauseAllOtherAudios(this.element);
      dispatchCustomEvent(window, "pause-all-players"); // media players
      this.updateBuffer();
    } else {
      this.element.removeAttribute("playing");
      this.audioTag.pause();
    }
  }

  get state() {
    if (this.element.hasAttribute("playing")) return "playing";
    else return "paused";
  }

  pause() {
    this.state = "paused";
  }

  static pauseAllOtherAudios(element) {
    document.querySelectorAll('[data-type="audio-player"]').forEach((audio) => {
      if (element !== audio && audio.pause) audio.pause();
    });
  }

  updatePlayPos() {
    const { duration } = this.audioTag;
    // this.audioTag.pause(); // need some way to mute this for google chrome
    const currentTime = parseFloat(this.rangeTag.value) * 0.01 * duration;
    this.audioTag.currentTime = currentTime;
    this.updateCurrentTime();
  }

  keepPlayState() {
    if (this.state === "paused") this.audioTag.pause();
    else this.audioTag.play();
  }

  changePlayState() {
    this.state = this.state === "paused" ? "playing" : "paused";
  }

  updateDuration() {
    this.durationDisplay.innerHTML = AudioPlayer.toTimeStr(
      this.audioTag.duration
    );
  }

  updateCurrentTime() {
    const { duration, currentTime } = this.audioTag;
    const currTimePer = ((currentTime / duration) * 100).toFixed(2);
    this.currentTimeEl.style.width = currTimePer + "%";
    this.rangeTag.value = currTimePer;
    this.currentTimeDisplay.innerHTML = AudioPlayer.toTimeStr(currentTime);
    if (duration === currentTime) this.state = "paused";
  }

  updateBuffer() {
    const { duration, buffered, currentTime } = this.audioTag;
    if (duration > 0) {
      for (let i = 0; i < buffered.length; i++) {
        if (buffered.start(i) <= currentTime) {
          this.bufferedEl.style.width =
            (buffered.end(i) / duration) * 100 + "%";
        }
      }
    }
  }

  static toTimeStr(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds - minutes * 60);
    if (minutes >= 0 && remainingSeconds >= 0) {
      // returns time string like 01:21
      return [minutes, remainingSeconds]
        .map((v) => (v < 10 ? "0" + v : v))
        .join(":");
    } else return "";
  }

  replayTen() {
    this.audioTag.currentTime -= 10;
  }

  forwardTen() {
    this.audioTag.currentTime += 10;
  }

  setupListeners(element) {
    this.rangeTag.addEventListener("input", () => this.updatePlayPos());
    this.rangeTag.addEventListener("change", () => this.keepPlayState());

    this.audioTag.addEventListener(events.TIMEUPDATE, () => {
      this.updateCurrentTime();
      this.sendAnalytics("unitytimeupdate");
    });
    this.audioTag.addEventListener(events.PLAY, () => {
      this.state = "playing";
      this.sendAnalytics("unityplay");
    });
    this.audioTag.addEventListener(events.PAUSE, () => {
      this.state = "paused";
      this.sendAnalytics("unitypause");
    });
    this.audioTag.addEventListener("durationchange", () =>
      this.updateDuration()
    );
    this.audioTag.addEventListener(events.PROGRESS, () => {
      if (this.audioTag.currentTime > 0) this.updateBuffer();
    });

    // Analytics events
    this.audioTag.addEventListener(events.LOADEDMETADATA, () =>
      this.sendAnalytics("unityloadedmetadata")
    );
    this.audioTag.addEventListener(events.ERROR, () =>
      this.sendAnalytics("unityerror")
    );
    this.audioTag.addEventListener(events.ENDED, () =>
      this.sendAnalytics("unityended")
    );
    this.audioTag.addEventListener(events.PLAYING, () =>
      this.sendAnalytics("unityplaying")
    );

    element
      .querySelector("[play-btn]")
      ?.addEventListener?.("click", () => this.changePlayState());

    element
      ?.querySelector("[replay-ten]")
      ?.addEventListener?.("click", () => this.replayTen());

    element
      .querySelector("[forward-ten]")
      ?.addEventListener?.("click", () => this.forwardTen());
  }

  sendAnalytics(event) {
    /** From the details section of this page: https://eden.churchofjesuschrist.org/?path=/docs/media-players-eden-audio-player--demo
     * platform:	String of “Audio” representing that it is using the web audio player.
     * mediaId:	String representing the platform's id for the media. Because the Audio component uses the HTML <audio> element, this value will be the <audio> element's currentSrc property.
     * currentTime:	Current playback time in seconds.
     * duration:	Total duration of the media in seconds.
     * name:	String representing the name or title. (Comes from the name prop which would default to a wrapping <AudioRecording>'s name prop if present.)
     */
    const { currentSrc: mediaId, name, currentTime, duration } = this.audioTag;
    sendMediaAnalytics({
      playerElement: this.audioTag,
      event,
      detail: {
        platform: "Audio",
        mediaId,
        name,
        currentTime,
        duration
      }
    });
  }
}

export const init = () => {
  const audioPlayers = [];
  initComponent("audio-player", (element) => {
    audioPlayers.push(element);
    callbackWhenInView({
      elems: [element],
      callback: () => new AudioPlayer(element)
    });
  });

  window.addEventListener("pause-all-audios", () => {
    audioPlayers.forEach((ap) => {
      if (ap.pause) ap.pause();
    });
  });
};
init();
