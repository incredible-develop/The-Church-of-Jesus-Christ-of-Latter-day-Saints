import { storiesOf } from "@storybook/html";
import { text, select, number } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  layoutKnobs,
  backgroundKnobs,
  bgColor,
  selectCommon
} from "../../../.storybook/commonKnobs";

import audioPlayer from "./index";
import { setAudioPlayerProps, audioSrcs } from "./mocks";

const returnKnobs = () => {
  return {
    audio: {
      audioSrc: select(
        "Audio Source",
        audioSrcs,
        audioSrcs["Joy to the World"],
        "Component"
      )
    },
    trackName: text("Track Name", "Track Name", "Component"),
    artistName: text("Artist Name", "Artist Name", "Component"),
    fileName: text("File Name", "Joy to the World", "Component"),
    color: select("Color", ["Dark", "Light"], "Dark", "Component"),
    ariaLabels: {
      volume: text("Volume Label", "volume", "Component"),
      replayTen: text("Replay 10 Label", "replay ten seconds", "Component"),
      playPause: text("Play/Pause Label", "play/pause", "Component"),
      forwardTen: text("Forward 10 Label", "forward ten seconds", "Component"),
      download: text("Download Label", "download", "Component")
    },
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

const multiple = () => {
  const numberOfAudioPlayers = number(
    "Number of Audio Players",
    5,
    {
      range: true,
      min: 1,
      max: 20,
      step: 1
    },
    "Component"
  );
  const backgroundColor = selectCommon(bgColor);
  const color = select("Color", ["Dark", "Light"], "Dark", "Component");
  const audioPlayers = [];
  const makeAudioPlayers = (arrLength) => {
    const srcArr = Object.values(audioSrcs);
    for (let i = 0; i < arrLength; i++) {
      const props = setAudioPlayerProps(
        i,
        srcArr[i % srcArr.length],
        backgroundColor,
        color
      );
      audioPlayers.push(audioPlayer(props));
    }
  };
  makeAudioPlayers(numberOfAudioPlayers);
  return audioPlayers.join("");
};

storiesOf("Audio Player", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => audioPlayer(returnKnobs()))
  .add("Multiple", () => multiple());
