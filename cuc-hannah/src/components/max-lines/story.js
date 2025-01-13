import { storiesOf } from "@storybook/html";
import { text, number } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";

import maxLines from "./index";

const returnKnobs = () => {
  const content = text(
    "Content",
    "A more lengthy set of content so that there is a chance that the lines could wrap so that the dynamic fade can be shown in all of its magnificent glory",
    "Component"
  );

  const maxLinesInlineMobile = number("Max Lines Mobile", 3, {}, "Component");

  const maxLinesInlineDesktop = number("Max Lines Desktop", 4, {}, "Component");

  const examples = [
    {
      fontSize: "16px",
      lineHeight: "1.0",
      maxLinesMobile: maxLinesInlineMobile,
      maxLinesDesktop: maxLinesInlineDesktop
    },
    {
      fontSize: "16px",
      lineHeight: "1.2",
      maxLinesMobile: maxLinesInlineMobile,
      maxLinesDesktop: maxLinesInlineDesktop
    },
    {
      fontSize: "22px",
      lineHeight: "1.2",
      maxLinesMobile: maxLinesInlineMobile,
      maxLinesDesktop: maxLinesInlineDesktop
    },
    {
      fontSize: "30px",
      lineHeight: "1.2",
      maxLinesMobile: maxLinesInlineMobile,
      maxLinesDesktop: maxLinesInlineDesktop
    }
  ];
  let exampleCode = "";
  examples.forEach((example) => {
    exampleCode += `
    <div class="example" style="--fontSize: ${example.fontSize};
	--lineHeight: ${example.lineHeight};
  --maxLinesMobile: ${example.maxLinesMobile}; --maxLinesDesktop: ${
      example.maxLinesDesktop
    };">
  <p class="details">--fontSize: ${example.fontSize};<br />
	--lineHeight: ${example.lineHeight};<br />
  --maxLinesMobile: ${example.maxLinesMobile};<br />
  --maxLinesDesktop: ${example.maxLinesDesktop};
  </p>
  
   ${maxLines({
     content,
     maxLines: example.maxLinesMobile,
     maxLinesDesktop: example.maxLinesDesktop
   })}</div>
    `;
  });

  return `
  <style>
  :root {
    --fontSize: 10px;
    --lineHeight: .8;
    --maxLines: ${maxLinesInlineMobile};
  }

.example {
  width: 200px;
  border: 1px solid red;
  float: left;
  font-size: var(--fontSize);
  line-height: var(--line-height);
  margin-inline-end: 5px;
}
.details {
  font-size: 12px !important;
  line-height: 1.2 !important;
  font-weight: 400;
  padding: 3px;
  border-bottom: 1px solid red;
  margin-bottom: 0;
}
h3 {
  clear:both;
}
.existingStructure:after {
  clear:both;
  display:table;
  content:"";
}
  </style>
  ${exampleCode}
  <div class="existingStructure">
  <h3>Example of existing structure using Max Lines attributes to style</h3>
  <p>For if you don't want to add extra wrappers when you already have some you could use. Just add <code>max-lines-wrapper</code> and <code>max-lines-fader</code> attributes (not classes due to postcss name changing) as appropriate.</p>
  <div class="example" style="--fontSize: 22px;
	--lineHeight: 1.4;
  --maxLinesMobile: ${maxLinesInlineMobile};
  --maxLinesDesktop: ${maxLinesInlineDesktop};">
  <p class="details">--fontSize: 22px;<br />
	--lineHeight: 1.4;<br />
  --maxLinesMobile: ${maxLinesInlineMobile};<br />
  --maxLinesDesktop: ${maxLinesInlineDesktop};
  </p>
  <div max-lines-wrapper>
    <div max-lines-fader>
   ${content}</div>
   </div>
   </div>
  `;
};

storiesOf("Utilities/Max Lines", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => returnKnobs());
