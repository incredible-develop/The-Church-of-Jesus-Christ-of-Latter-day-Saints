export const setAudioPlayerProps = (i, audioSrc, bgColor, color) => ({
  audio: { audioSrc },
  trackName: `Track Number ${i + 1}`,
  artistName: `The Number ${i + 1} Artist`,
  fileName: `File Name ${i + 1}`,
  color,
  ariaLabels: {
    volume: "volume",
    replayTen: "replay ten seconds",
    playPause: "play/pause",
    forwardTen: "forward ten seconds",
    download: "download"
  },
  layout: {
    spacingTop: "relate-32px",
    paddingTop: "relate-32px",
    paddingBottom: "same-as-top",
    backgroundWidth: "normal",
    backgroundWidthMobile: "none",
    contentWidthMobile: "",
    contentWidthDesktop: "narrow"
  },
  background: {
    bgColor,
    bgImage: {},
    bgBrightcoveId: "",
    rays: false
  }
});

export const audioSrcs = {
  "Joy to the World":
    "https://media2.churchofjesuschrist.org/assets/music/hymns/2001-01-2010-joy-to-the-world-instrumental-192k-eng.mp3",
  Believe: "https://upload.wikimedia.org/wikipedia/en/e/e0/Believe_-_Cher.ogg",
  "Never Gonna Give You Up":
    "https://upload.wikimedia.org/wikipedia/en/d/d0/Rick_Astley_-_Never_Gonna_Give_You_Up.ogg",
  "Rains of Africa":
    "https://upload.wikimedia.org/wikipedia/en/e/ed/Africa_by_Toto.ogg"
};
