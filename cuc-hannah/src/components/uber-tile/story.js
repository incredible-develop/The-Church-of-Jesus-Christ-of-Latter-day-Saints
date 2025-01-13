import { storiesOf } from "@storybook/html";
import { text, boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  layoutKnobs,
  backgroundKnobs,
  btnVariant,
  selectCommon,
  bgColor,
  icon,
  aspectRatio,
  verticalAlign,
  horizontalAlign,
  textJustification,
  headingLevel,
  bodyFontSize,
  videoKnobs,
  remoteTriggerId,
  layoutLines,
  link
} from "../../../.storybook/commonKnobs";
import { remoteComponentSubscribe } from "../remote-trigger/browser";

import uberTile from "./index";

const socialFollowProps = {
  actionBarContent: {
    facebook: { display: true, link: "www.facebook.com/comeuntochrist" },
    instagram: { display: true, link: "www.instagram.com/comeuntochrist" },
    twitter: { display: true, link: "www.twitter.com/comeuntochrist" },
    youtube: { display: true, link: "www.youtube.com/comeuntochrist" },
    email: { display: false }
  },
  actionBarSettings: {
    largeSocialIcons: true,
    invertSocialIcons: true,
    iconBackgroundColor: "LTWRed"
  }
};

const returnKnobs = () => {
  let videoOn = boolean("Add Video", false, "Component");
  let useSocialFollow = boolean(
    "Replace button with Social Follow component",
    false,
    "Component"
  );
  return {
    aspectRatioMobile: selectCommon({
      ...aspectRatio,
      label: "Aspect Ratio Mobile"
    }),
    aspectRatioDesktop: selectCommon({
      ...aspectRatio,
      options: ["", ...aspectRatio.options],
      initialVal: "",
      label: "Aspect Ratio Desktop"
    }),
    verticalStyleMobile: selectCommon(
      verticalAlign,
      "Vertical Alignment Mobile",
      "top"
    ),
    horizontalStyleMobile: selectCommon(
      horizontalAlign,
      "Horizontal Alignment Mobile",
      "left"
    ),
    verticalStyleDesktop: selectCommon(
      verticalAlign,
      "Vertical Alignment Desktop",
      "top"
    ),
    horizontalStyleDesktop: selectCommon(
      horizontalAlign,
      "Horizontal Alignment Desktop",
      "left"
    ),
    textStyleDesktop: selectCommon(
      textJustification,
      "Text Justification Desktop",
      "left"
    ),
    textStyleMobile: selectCommon(
      textJustification,
      "Text Justification Mobile",
      "left"
    ),
    invertTextColor: boolean("Invert Text Color", false, "Component"),
    barColor: selectCommon(bgColor, "Bar Color", "Yellow25"),
    heading: text(
      "Heading",
      "Heading that is really long and wraps so we can more easily see the width of the component",
      "Component"
    ),
    headingStyleMobile: selectCommon(
      headingLevel,
      "Heading Style Mobile",
      "h3"
    ),
    headingStyleDesktop: selectCommon(headingLevel, "Heading Style Desktop"),
    isExtraBold: boolean("Is Heading Extra Bold?", false, "Component"),
    body: text(
      "Body",
      "This is the Body: Add background image/video for gradient",
      "Component"
    ),
    ...bodyFontSize({
      key: "bodyStyleMobile",
      label: "Body Style Mobile",
      initialVal: "legal"
    }),
    ...bodyFontSize({ key: "bodyStyleDesktop", label: "Body Style Desktop" }),
    btn: {
      variant: selectCommon({ ...btnVariant, groupId: "Component" }),
      colorVariant: selectCommon(bgColor, "Button Color", "Component"),
      label: text("Button Label", "Play", "Component"),
      icon: selectCommon({ ...icon, groupId: "Component" }, "Button Icon")
    },
    socialFollow: useSocialFollow ? socialFollowProps : "",
    ...(videoOn
      ? {
          video: videoKnobs()
        }
      : { ...link() }),
    ...remoteTriggerId({ groupId: "Component" }),
    mockWrapped: boolean(
      "Act as if inside an additional layout wrapper",
      false,
      "Component"
    ),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Uber Tile", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => {
    const results = returnKnobs();
    remoteComponentSubscribe(results.remoteTriggerId, () => {
      alert(`Remote component triggered: ${results.remoteTriggerId}`);
    });
    return `
    <div class="${results.mockWrapped ? "layout_inner" : ""}">
    ${uberTile(results)}
    </div>
    ${layoutLines(results)}
    `;
  });
