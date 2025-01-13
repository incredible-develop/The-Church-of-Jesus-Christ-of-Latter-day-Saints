import { image, randomWords } from "../../../.storybook/commonKnobs";
import { mockMediaBlock as simpleMediaBlock } from "../media-block/mocks";

export const renderMediaBlock = (number) => ({
  type: "media-block",
  variant: "bottom",
  image: image.array[number],
  poster: image.array[number],
  youTubeId: "zkC8kZb1RdQ",
  brightcoveId: "ref:5A788F7FAB26DADBE468CED4E2B9202BC72F0ED7",
  // youTubePlaylistId: "PLdDQasmKFH_iFZ0PeD_EFxIeUxRs_GWsf", we want brightcove to default so commenting this out, if you need to test it you can put this back in
  mobileAspectRatio: "will be overridden",
  aspectRatio: "will be overridden",
  borderRadius: "will be overridden",
  videoTitle: "Video Title",
  timestamp: "1:23",
  btn: {
    variant: "primary-color-background",
    colorVariant: "",
    label: "Play",
    icon: "play"
  },
  heading: "",
  body: "",
  looping: false,
  captionWidth: "uncontrolled",
  actionBar: [
    {
      twitter: {
        text: "No matter who we are, or what our story is, we are all invited to #ComeUntoChrist and be perfected in him."
      },
      email: {
        subject: "Come Unto Christ",
        body: "<p>No matter who we are, or what our story is, we are all invited to #ComeUntoChrist and be perfected in him.</p>",
        urlPlacement: "append"
      },
      likes: { counterGroup: "alpha", counterId: "test5" },
      includeShareButton: true,
      download: true,
      shareUrl: { URL: "http://www.comuntochrist.org" },
      popoverHeading: "Share With Your Friends"
    }
  ],
  caption: {
    type: "caption-block",
    heading: randomWords({ minWords: 3, maxWords: 7, capitalCase: true }),
    caption: randomWords({ minWords: 5, maxWords: 40 }),
    citation: "I am the citation",
    btn: {
      link: { URL: "https://comeuntochrist.org" },
      variant: "secondary-color-text",
      colorVariant: "",
      label: "Label",
      icon: ""
    }
  },
  limitCaptionTextWidth: true,
  downloadLabel: "",
  defaultPoster: false,
  invertTextColor: false,
  background: {
    bgColor: "",
    bgImage: {},
    bgBrightcoveId: "",
    rays: false
  },
  layout: {
    spacingTop: "",
    paddingTop: "",
    paddingBottom: "same-as-top",
    backgroundWidth: "uncontrolled",
    backgroundWidthMobile: "normal",
    contentWidthMobile: "",
    contentWidthDesktop: "uncontrolled"
  }
});

export const mockEUI = {
  type: "enhanced-ui-slider",
  components: [simpleMediaBlock, simpleMediaBlock, simpleMediaBlock],
  background: {
    bgColor: "",
    bgImage: {},
    bgBrightcoveId: "",
    rays: false
  },
  layout: {
    spacingTop: "relate-32px",
    spacingTopDesktop: "",
    paddingTop: "relate-32px",
    paddingTopDesktop: "",
    paddingBottom: "same-as-top",
    paddingBottomDesktop: "",
    backgroundWidth: "uncontrolled",
    backgroundWidthMobile: "none",
    contentWidthMobile: "",
    contentWidthDesktop: "uncontrolled"
  },
  size: "small",
  wrapAround: false,
  ratio: "16x9",
  borderRadius: "0px",
  ariaPrevious: "previous",
  ariaNext: "next",
  captionAlignment: "Left",
  invertTextColor: false
};
