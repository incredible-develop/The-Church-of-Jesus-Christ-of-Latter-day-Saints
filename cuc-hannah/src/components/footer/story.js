import { storiesOf } from "@storybook/html";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  pageRoot,
  layoutKnobs,
  backgroundKnobs
} from "../../../.storybook/commonKnobs";

import { dynamici18nSelector } from "../dynamic-i18n-selector/mocks";

import footer from "./index";

const returnKnobs = () => {
  return {
    type: "footer",
    copyright: "by Intellectual Reserve, Inc. All rights reserved.",
    components: {
      langSel: dynamici18nSelector,
      links1: [
        {
          type: "link-list",
          links: [
            {
              link: {
                URL: "/about-us"
              },
              text: "About Us"
            },
            {
              link: {
                URL: "/worship-with-us/nearby-churches"
              },
              text: "Find a Church"
            },
            {
              link: {
                URL: "/site-map"
              },
              text: "Site Map"
            }
          ],
          mobileSpacing: "no-spacing",
          desktopSpacing: "same-as-mobile"
        }
      ],
      links2: [
        {
          type: "link-list",
          links: [
            {
              link: {
                URL: "http://example.com"
              },
              text: "Other Link"
            },
            {
              link: {
                URL: ""
              },
              text: "{privacy-link}"
            },
            {
              link: {
                URL: ""
              },
              text: "{terms-link}"
            },
            {
              link: {
                URL: ""
              },
              text: "{feedback-link}"
            }
          ]
        }
      ]
    },
    socialLinks: [
      {
        platform: "facebook",
        socialURL: "//www.facebook.com/ComeUntoChrist"
      },
      {
        platform: "twitter",
        socialURL: "//www.twitter.com/ComeUntoChrist"
      },
      {
        platform: "youtube",
        socialURL: "//www.youtube.com/c/ComeUntoChrist"
      },
      {
        platform: "instagram",
        socialURL: "//www.instagram.com/ComeUntoChrist/"
      }
    ],
    churchLogoLink: "/",
    additionalComponents: [
      {
        type: "mo-simple-sign-up",
        tileTitle: "Inspire your inbox",
        layout: {
          spacingTop: "no-spacing",
          paddingTop: "unite-3-16px",
          paddingBottom: "same-as-top",
          backgroundWidth: "uncontrolled",
          backgroundWidthMobile: "uncontrolled",
          contentWidthDesktop: "normal"
        },
        background: {
          bgColor: "Yellow25",
          rays: "true"
        },
        label: "Inspire your inbox",
        invertColors: "true",
        fitContainer: "false",
        btn: {
          type: "mo-button",
          label: "Submit",
          variant: "primary-white-background",
          color: "interactive"
        },
        alignment: "left",
        close: {
          display: "false"
        },
        cookieName: "test",
        requestType: "email-request",
        listId: "106867",
        aspectRatio: "1x1",
        mobileSmall: "false",
        email: {
          key: "email-field",
          name: "email",
          label: "Email",
          emailVerify: {
            malformed: "Please enter a formatted address e.g. you@domain.com",
            invalidDomain: "Please enter a domain that can accept email",
            invalidAddress: "Please enter a valid email address",
            requiredMessage: "Please enter a value"
          }
        }
      }
    ],
    ...layoutKnobs(),
    ...backgroundKnobs(),
    ...pageRoot
  };
};

storiesOf("Footer", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => footer(returnKnobs()));
