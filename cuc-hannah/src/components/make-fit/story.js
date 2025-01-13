import { storiesOf } from "@storybook/html";
import { text } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";

import MakeFit from "./browser";

const returnKnobs = () => {
  setTimeout(() => {
    /* make calls for demos */

    // use fitWithin
    new MakeFit(document.querySelectorAll(".makeFit2"), {
      fitWithin: document.querySelector(".fitWithin2"),
      sizeClasses: "small smaller smallest"
    });

    // use fitWithin
    new MakeFit(document.querySelectorAll(".makeFit3"), {
      alsoAddClassTo: document.querySelector(".addToMe"),
      sizeClasses: "small smaller smallest"
    });

    // use sync
    new MakeFit(document.querySelectorAll(".sync"), {
      sync: true,
      sizeClasses: "small smaller smallest"
    });
    document.querySelector(".imgWrapper").addEventListener("click", () => {
      document
        .querySelector(".imgWrapper img")
        .setAttribute(
          "src",
          document.querySelector(".imgWrapper img").dataset.src
        );
    });
  });
  const fillerText = text("Filler Text", "", "Component");
  return `
	<p>Boxes with different sizes but same text to see how the styles apply differently</p>
<div class="wrapper">
	<div class="demo1 makeFit replaceText updateOnChange" data-type="make-fit" data-makeFit-sizeClasses="small smaller smallest">${
    fillerText ||
    "This is the text that needs to fit inside of the wrapping element"
  }</div>
</div>

<div class="wrapper bigger">
	<div class="demo2 makeFit replaceText updateOnChange" data-type="make-fit" data-makeFit-sizeClasses="small smaller smallest">${
    fillerText ||
    "This is the text that needs to fit inside of the wrapping element"
  }</div>
</div>
<div class="wrapper biggest">
	<div class="demo3 makeFit replaceText updateOnChange" data-type="make-fit" data-makeFit-sizeClasses="small smaller smallest">${
    fillerText ||
    "This is the text that needs to fit inside of the wrapping element"
  }</div>
</div>

<p><code>fitWithin</code> is defined as being a sibling, not the parent.</p>
<div class="positionWrapper">
	<div class="wrapper fitWithin2 bigger"></div>
	<div class="demo4 makeFit2 replaceText updateOnChange">${
    fillerText ||
    "This is the text that needs to fit inside of the wrapping element"
  }</div>
</div>

<p><code>alsoAddClassTo</code> is provided as a parent wrapper.</p>
<p>Parent wrapper will have red border normally, orange for small, yellow for smaller and green for smallest. The makeFit element has a black border.</p>
<div class="addToMe">
	<div class="wrapper">
		<div class="demo5 replaceText updateOnChange makeFit3" data-makeFit-sizeClasses="small smaller smallest">${
      fillerText ||
      "This is the text that needs to fit inside of the wrapping element"
    }</div>
	</div>
</div>

<p>This tests the sync option, if one of the following is long they should all shrink. Also demonstrates flexible size container</p>
<div class="syncWrapper">
	<div>
		<div class="sync updateOnChange"><span class="replaceText">${fillerText}</span> text</div>
	</div>
	<div>
		<div class="sync replaceText updateOnChange">This has text that wraps</div>
	</div>
	<div>
		<div class="sync updateOnChange"><span class="replaceText">${fillerText}</span> some more text</div>
	</div>
</div>

<p>Test image loading and resizing the parent. Click box to load image</p>
<div class="wrapper imgWrapper">
	<div class="demoImg makeFit replaceText updateOnChange" data-type="make-fit" data-makeFit-sizeClasses="small smaller smallest">${
    fillerText ||
    "This is the text that needs to fit inside of the wrapping element"
  }</div>
		<img data-src="http://place-puppy.com/public-images/index-page/image4/410x280-lg.jpg" />
</div>
  

<style>
.wrapper {
	outline: 1px solid red;
	height: 150px;
	width: 150px;
	font-size: 48px;
	display: inline-block;
	vertical-align: text-top;
}

.demo4 {
	font-size: 48px;
	position: absolute;
	top: 0;
	left: 0;
	width: 100%;
}

.demo2 {
	// font-size: 48px;
}
.replaceText {
	padding: 10px;
}

.small {
	font-size: 32px;
}
.smaller {
	font-size: 24px;
}
.smallest {
	font-size: 16px;
}

.bigger {
	width: 200px;
	height: 200px;
}
.biggest {
	width: 250px;
	height: 250px;
}

.positionWrapper {
	position: relative;
	display: inline-block;
}

.syncWrapper {
	display: flex;
	height: 200px;
}
.syncWrapper > div {
		background: #f1f1f1;
		padding: 10px;
		margin-inline-end: 10px;
		font-size: 48px;
		width: 30%;
}

.imgWrapper {
	position: relative;
	height: auto;
	width: auto;
	min-height: 100px;
	min-width: 100px;
}
.imgWrapper div {
	position: absolute;
	top: 0;
	left: 0;
}
body {
	padding: 30px;
}

.addToMe {
	border: 1px solid red;
}
.addToMe.small {
	border-color: orange;
}
.addToMe.smaller {
	border-color: yellow;
}
.addToMe.smallest {
	border-color: green;
}
.addToMe .wrapper {
	outline-color: black;
}
`;
};

storiesOf("Utilities/Make Fit", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => returnKnobs());
