import { storiesOf } from "@storybook/html";
import { number, text, boolean, select } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  selectCommon,
  image,
  icon,
  bgColor,
  imageKnobs,
  layoutKnobs
} from "../../../.storybook/commonKnobs";

import thumbnailSlider from "./index";

const idName = () =>
  text("Gallery Id names (blank = numbers)", "", "Component");

const galleryItem = (index) => {
  return {
    image: image.array[index],
    caption: "Caption goes here if it's long",
    icon: Math.random() < 0.2 ? "video" : "",
    // + 1 + 1 is to compensate for custom gallery item (item 0) already inserted AND so it goes 1,2,3 (now it starts with item 1)
    galleryId: `${idName()}${index + 1 + 1}`,
    aspectRatio: "1x1",
    iconColor: selectCommon({ ...bgColor, groupId: "Component" }, "Icon Color")
  };
};

const makeGalleryItems = (itemCount) => {
  const galleryItems = [];
  for (let i = 0; i < itemCount; i++) galleryItems.push(galleryItem(i));
  return galleryItems;
};

const returnKnobs = () => {
  const numberOfItems = number(
    "Number of Items",
    15,
    {
      range: true,
      min: 1,
      max: 15,
      step: 1
    },
    "Component"
  );

  return {
    highlightColor: selectCommon(
      { ...bgColor, groupId: "Component" },
      "Highlight Color",
      "Yellow25"
    ),
    thumbnailBgColor: selectCommon(
      { ...bgColor, groupId: "Component" },
      "Thumbnail Background Color",
      ""
    ),
    thumbnailShape: select(
      "Thumbnail Shape",
      ["circle", "square"],
      "square",
      "Component"
    ),
    invertTextColor: boolean("Invert Colors", false, "Component"),
    outsetArrows: boolean("Outset Arrows", true, "Component"),
    isNumbered: boolean("Numbered thumbnails", false, "Component"),
    hideCaptions: boolean("Hide Captions", false, "Component"),
    selectFirstItem: boolean(
      "Pre-select first item by default",
      false,
      "Component"
    ),
    galleryItems: [
      {
        image: imageKnobs({
          imageProps: [
            { ...image, groupId: "Component" },
            "Image for Gallery Item 1",
            3
          ],
          altTextLabel: "Image Alt Text for Gallery Item 1",
          imgAlignmentLabel: "Image Alignment for Gallery Item 1"
        }),
        caption: text("Caption for Gallery Item 1", "Caption", "Component"),
        icon: selectCommon(
          { ...icon, groupId: "Component" },
          "Icon for Gallery Item 1"
        ),
        galleryId: text("Gallery Id for Gallery Item 1", "1", "Component"),
        aspectRatio: "1x1" // hard coded in index.js
      },
      ...makeGalleryItems(numberOfItems - 1)
    ],
    scrollLeft: "Scroll Left",
    scrollRight: "Scroll Right",
    ...layoutKnobs({ backgroundWidth: "normal" })
  };
};

storiesOf("Thumbnail Slider", module)
  .addDecorator(withReadme(readme))
  .add(
    "Default",
    () => `
    <style>
      #thumb-container {
        background: #fff;
        margin: auto;
      }
      @media (min-width: 600px) {
        #thumb-container {
          width: 80%;
        }
      }
    </style>
    <div style="background: #f5f5f5;">
    <button onclick="document.querySelector('[data-type]').addEventListener('gallery-item-select', e => {document.querySelector('#gallery-id').innerHTML = 'You have selected <code>galleryId: ' + e.detail.galleryId + '</code>'});">Listen for Gallery Id</button>
    <p id="gallery-id">Click the button to see the <code>galleryId</code> of any media item that is selected.</p>
    <hr>
    ${thumbnailSlider(returnKnobs())}
    </div>
    `
  );
