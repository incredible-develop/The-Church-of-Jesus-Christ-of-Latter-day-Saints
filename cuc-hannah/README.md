# Hannah

Welcome to the README for the Hannah repository. Hannah handles building and serving pages for the comeuntochrist.org website. The rest of this document contains how to get set up to start working on Hannah and it's companion repository CMS.

# Table of Contents

- [Introduction](#Introduction)
- [Overview](#Overview)
- [Getting Set Up](#Getting-Set-Up)
  - [Prerequisites](#Prerequisites)
  - [Node.js](#Node.js)
  - [Git](#Git)
  - [Pull Repositories](#Pull-Repositories)
  - [Hosts file](#Hosts-File)
  - [Security Certificate](#Security-Certificate)
- [Development Basics](#Development-Basics)
  - [Storybook](#Storybook)
  - [DevOps](#DevOps)
  - [Components](#Components)
  - [Structure](#Structure)
  - [Pull Request Process](#Pull-Request-Process)
- [Architecture](#Architecture)
  - [Putting it all Together](#Putting-it-all-Together)
  - [How it all works](#How-It-All-Works)
- [Additional Development Tips](#Additional-Development-Tips)
  - [Cloud Foundry CLI](#Cloud-Foundry-CLI)
  - [Adapters](#Adapters)
  - [Managing Analytics](#managing-analytics)
  - [Running a local version of ComeUntoChrist](#Running-a-local-version-of-ComeUntoChrist)
    - [Configuration Files](#Configuration-Files)
    - [Connecting Hannah to a CMS](#Connecting-Hannah-to-a-CMS)
    - [Development Server](#Development-Server)
    - [Production](#Production)
  - [Running a local version of CMS](#Running-a-local-version-of-CMS)
    - [Configuring vcap file](#configuring-vcap-file)
    - [Additional Local/Publishing Tips](#Additional-Local/Publishing-Tips)
- [Additional Details](#Additional-Details)
  - [Accessing SonarQube Scan Reports](#SonarScan)
  - [Titan](#titan)
  - [Adding a Theme](#adding-a-theme)
  - [Updating Versions of Dependencies](#updating-versions-of-dependencies)
  - [Change Log](#name-change)

# Introduction

Welcome to the ComeUntoChrist.org team! This documentation is designed to get you started and able to contribute to the work in as little time as possible. You should be able to follow this setup in the order it is written, but it may take more than a day to finish everything. You can use this process as an opportunity to improve your troubleshooting skills. If you are stuck for an extended amount of time on the same problem, you should reach out to a team member.

We encourage you to take note of issues with this documentation, so you can make improvements in the future.

# Overview

ComeUntoChrist.org uses two main repositories. `Hannah` and `CMS`.

`Hannah` is the name for our in-house JavaScript framework used specifically on ComeUntoChrist (CUC). It is essentially VanillaJS built into components and bundled up using Webpack. We use PostCSS to process some SASS-esque CSS formatting.

`CMS` is an in-house Content Management System (CMS) called LDS Publisher (LDSP), typically known as cms. Common words thrown around for this are CMS, Publisher, or occasionally musketeer.

Our data store is a system called [MarkLogic](https://en.wikipedia.org/wiki/MarkLogic) (xml based storage) and is managed with a language called [XQuery](https://en.wikipedia.org/wiki/XQuery). `CMS` and the data store are set up in the cms repo but are noted here for contextual reference only.

We use [storybook](https://storybook.js.org/) for quick building and testing of our components.

Before a feature is merged into our public `release` branch (for Hannah and/or cms) it must be tested. To do this, each feature/change branch gets built and tested at it's own custom URL (See [DevOps](#DevOps)). A Pull request is made to request that the branch is merged into `release`, once the code has been reviewed and approved by at least two other developers, the change must be tested at the custom URL and approved by QA and User Acceptance Testing (UAT). Once tested and approved, the change gets merged into `release`, built to our `stage` environment, and tested one last time before it is released to production.

# Getting Set Up

## Prerequisites

Before beginning, please ensure you have the following:

- [ ] An IDE / code editor of choice (Install the Prettier extension to ensure consistent code formatting)
- [ ] Access to ComeUntoChrist.org CMS repository on GitHub (Ask Dev Lead for access)
- [ ] Access to ComeUntoChrist.org Hannah repository on GitHub (Ask Dev Lead for access)

During the process, this documentation will walk you through setting up these items:

- [ ] Node Version Manager (NVM)
- [ ] Git
- [ ] Hosts file

## Node.js

ComeUntoChrist is a Node.js application, so we will walk you through installing the version of Node we use via Node Version Manager(NVM). To see what version the team is currently using, you can check the JSON property `engines.node` in the [`./package.json`](./package.json) in `Hannah`. It is possible that newer versions of Node will not build correctly.

1. Download the Node Version Manager (NVM).
   - _Bash (MacOS, GNU/Linux)_  
     Use  
     `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash`  
     or  
     `wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash`
     - You will need to manually install Xcode before running the install script, or the command above will fail. You can install these manually from the [App Store]('https://apps.apple.com/us/app/xcode/id497799835?mt=12').
   - _Windows_  
     Download the nvm-setup.zip from https://github.com/coreybutler/nvm-windows/releases.  
     Unzip the file then go to nvm-setup/nvm-setup.exe and install the program. You will be able to call nvm from the command line.
   - See more details [here]('https://github.com/nvm-sh/nvm') on how to install NVM.
2. **For MacOS users:**
   Navigate to your `Users` folder and open your default user (e.g. `Users/newUser`). In this directory create a new file called `.zshrc`. Copy, paste and save the following code in the `.zshrc` file

```
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

3. In a new terminal type `nvm install`. The node version will be determined by the [`.nvmrc`](./.nvmrc), which should match the engines.node in the [`package.json`](./package.json). NOTE: If the install command does not work for you see the nvm documentation (help)[https://github.com/nvm-sh/nvm#troubleshooting-on-macos].
4. In your terminal type `nvm use`. All `node` commands will run the version specified in the [`.nvmrc`](./.nvmrc).
5. In your terminal type `node -v` to check that your system is using the version defined in the [`.nvmrc`](./.nvmrc) file.

## Git

We have all of our code on GitHub and you will need to use git to pull and push the code. If you do not have git installed already please install it.

- Mac: It's built-in to MacOS but you can ensure this by simply trying to run git from the Terminal for the very first time.
  Run the following command on Terminal and if you don’t have it installed already, it will prompt you to install it.

```bash
git --version
```

- Windows: https://git-scm.com/download/win

To make sure you have access to Github, follow steps 1-4 in the [Getting Started With Github](https://confluence.churchofjesuschrist.org/display/ALM/Getting+Started+with+Github) documentation. These steps cover the following:

- [Setting up an Account](https://confluence.churchofjesuschrist.org/display/ALM/Github+Account+Requirements)
- [Setting up Two Factor Authentication](https://docs.github.com/en/github/authenticating-to-github/configuring-two-factor-authentication)
- [Creating a Personal Access Token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token), don't forget to copy down your token for a later step
- [Request Access to ICSEng](https://confluence.churchofjesuschrist.org/display/ALM/Github+Request+Access+to+ICSEng). Once you receive an invitation to join ICSEng, you must click the button in the email invitation to join. You won't appear as a member of the organization until you do so.
- [Authorize Personal Access with SAML](https://docs.github.com/en/github/authenticating-to-github/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on)

## Pull Repositories

### Pull Hannah repository

Navigate to the location where you want to install the `Hannah` files. There are two ways to clone a repo from Github: HTTPS and SSH.

#### HTTPS (fastest way)

Once you are to the above location, run the following command in the terminal.

```bash
git clone https://github.com/ICSEng/cuc-hannah.git
```

If that worked you can skip the steps for SSH.

#### SSH - Generate an SSH Key Pair (more secure way)

1. Open a new Terminal window. If you already have a key setup on your machine you can skip to step 5.
2. Genrate a key set.

- [Mac OS] In the terminal run `ssh-keygen -b 4096 -t rsa`. Got to step 3 for directions on what to do immedialtey after this command is run.
- [Windows OS] users see this (post)[https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/create-with-putty/] for the flow. Then after using putty to generate the key copy it to your clipboard and go to step 6.

3. You will be prompted to enter a filename. By default, your keys will be saved as id_rsa and id_rsa.pub. Simply press Enter to confirm the default - there is no need to change this unless you have multiple keys! Also, your pass phrase you must remember since there is no way to recover.
4. This will created a hidden directory called .ssh that contains both your public (id_rsa.pub) and private (id_rsa.) key files.
5. [Mac OS] Copy the pubilc key `pbcopy < ~/.ssh/id_rsa.pub` to the clipboard.
6. In Github, once logged in, you can click on the top right Profile ICON for your profile. Go to Settings > SSH and GPG Keys tab.
7. Click New SSH Key, name the key what you want, leave type as default, then paste the key that was copied before into the Key box and hit the Add SSH Key button to save.
8. IMPORTANT: Click Configure SSO to Authorize the ICSEng Organization (you must have the Church repo access at this point) to use this key.
9. At this point you can now clone the repo to you local machine using `git clone git@github.com:ICSEng/cuc-hannah.git`

Once done you should have a copy of the latest `hannah` code in a folder called hannah. Install all the Node dependencies by typing:

```bash
cd hannah
npm install
```

### Pull CMS repository

Navigate to the location where you want to install the `CMS` files.

Once you are there, run the following command in the terminal. Once you've done that you should have a copy of the latest `cms` code in a folder called cms.

```bash
git clone https://github.com/ICSEng/cuc-cms.git
```

If you followed the SSH steps above you can instead use this command.

```bash
git clone git@github.com:ICSEng/cuc-cms.git
```

## Hosts file

Open your hosts file at (navigate either in the finder or via the terminal)

MacOS: `/private/etc/hosts` ex: in terminal run `sudo nano /etc/hosts` (it should ask for your mac password)

Windows: `C:\Windows\System32\Drivers\etc\hosts`

Add the following to allow you to use some domains for your local machine.

```
127.0.0.1 local.comeuntochrist.org
127.0.0.1 local.churchofjesuschrist.org
127.0.0.1 preview-local.churchofjesuschrist.org
127.0.0.1 comeuntochrist-preview-local.churchofjesuschrist.org
127.0.0.1 mwpublisher-preview-local.churchofjesuschrist.org
127.0.0.1 cuc-local-hannah.pvu.cf.churchofjesuschrist.org
127.0.0.1 cuc-local-hannah-preview.pvu.cf.churchofjesuschrist.org
```

MacOS users: see more (here)[https://setapp.com/how-to/edit-mac-hosts-file] if you have any issues.

This will allow you to go to [local.churchofjesuschrist.org]('https://local.churchofjesuschrist.org') (or any of the others listed above) to see your local version running. This will allow you to easily change from seeing a page in production such as https://www.churchofjesuschrist.org/comeuntochrist/article/temples and by only changing the `www` to `local` you can se the same page on your local machine to debug an issue.

The server uses a self signed certificate, so the first time you view the https://local.churchofjesuschrist.org domain on a browser/device you will need to go past the security warning that it is an un-safe site and allow it to load.

There are many instances of `localhost` in this readme. They all can load from `localhost` or `local.churchofjesuschrist.org` with their respective ports. Be careful of `http` vs `https` as you use them. `https` is used for loading the dev server to match up with the protocol used in other lanes. `https` will not be used for any that are using a different port, but the domains in the host file can still be used if desired.

## Security Certificate

To not have to regularly click past browser warnings of invalid certificates, do the following:

1. Install the mkcert tool. (See [installation instructions](https://github.com/FiloSottile/mkcert/blob/master/README.md#installation)). If you decide to use homebrew to install mkcert on MacOS, when installing homebrew you may get an error saying you need the xCode Command Line Tools installed. Download the Command Line Tools for the version of xCode you have install on your machine from the [Apple Development Downloads page]('https://developer.apple.com/download/more/').
2. Run the following, which may ask you for your `sudo` password, which is the password you use to get on your machine (likely your Church Account Password)

```bash
mkcert -install
```

3. Run the mkcert tool to create the certificate and private key in your hannah directory:

   ```bash
   mkcert -key-file localhost.key -cert-file localhost.crt local.churchofjesuschrist.org local.comeuntochrist.org localhost preview-local.churchofjesuschrist.org comeuntochrist-preview-local.churchofjesuschrist.org mwpublisher-preview-local.churchofjesuschrist.org cuc-local-hannah.pvu.cf.churchofjesuschrist.org cuc-local-hannah-preview.pvu.cf.churchofjesuschrist.org 127.0.0.1 ::1
   ```

4. Your OS needs to allow for trusting the new SSL in the browser. [MacOS] make sure to follow this (stackoverflow)[https://superuser.com/questions/1359755/trust-self-signed-cert-in-chrome-macos-10-13] to allow your SSL to be trusted by Chrome.
   For [WindowsOS] you will be able to search for that topic and follow steps to "Trust SSL in Chrome on Windows."

# Development Basics

## Storybook

Much of our component development happens within Storybook. Storybook acts as a "fake backend" for testing and developing. Because we build in a component based architecture, we primarily look at the component on its own within Storybook, allowing it to be composed into a page via the CMS. You will need to run storybook in your terminal for it to work in the web browser. Once it is running, changes you make within a component will typically show in storybook without having to refresh it. This is a good way to test your changes before running it in a dev environment.

Get storybook running in the `Hannah` repository

```bash
npm run storybook
```

**_If you are out of the office, make sure VPN is working or storybook will not work. You will also need to make sure you have the correct version of node installed._**
You can now view our components locally in Storybook at http://localhost:9999 or http://local.churchofjesuschrist.org:9999
Storybook can be accessed in any lane except for production by appending "/storybook" at the end of the URL. For example, https://cuc-1234-hannah.pvu.cf.churchofjesuschrist.org/comeuntochrist/storybook

Review the components to be familiar with what we have. On the right side of the screen are "Knobs" which:

1. Show you the options available for a component, with their possible values
1. Allow you to use easily change options to see what a component can do

Also be aware of the "Readme" tab on the right for details about what each Knob is for.

Storybook will reload the main frame after any change to the Knobs, and hot-reload any changes you save in your editor as well. This allows for quick verification of changes.

### Story.js files in Hannah

- `story.js` files in each component include a function called `returnKnobs`, which returns an object.
- Each property of the `returnKnobs` object corresponds to a property that is normally passed into `index.js` with data from Publisher. Instead of using data from Publisher, Storybook will use the data inside the `returnKnobs` object.
- By adding a Storybook function (`text()`, `select()`, `number()` or `boolean()`) as a value to a property, you create a "knob" that will be visible and editable to a user viewing Storybook from a web browser.
- You can use common knobs from `hannah/.storybook/commonKnobs.js` to create knobs that are the same site-wide, like `icon`, `image`, `backgroundKnobs` etc.

For more specifics about storybook, you can visit https://storybook.js.org/.

## DevOps

DevOps is the process we follow in order to test individual changes on an isolated branch that will yield realistic results, and you can change the Hannah and CMS of your custom DevOps lane.

To start, create a new branch branched off of `release` or `mormonorg-release` (for Hannah or CMS respectively). The new branch must have `CUC-[four numbers]-[some name]` in the branch name with the `####` matching the jira you are working on. The name has to have the dashes and shouldn't contain any other special characters like ", \_, ', etc.". When changes are pushed to the remote branch, it will automatically run the DevOps process. It will create a custom URL for your particular branch. For example, if you were working on task CUC-1234 and you push it to GitHub, it will create a link like this URL that can you can use: [https://cuc-1234-hannah.pvu.cf.churchofjesuschrist.org/comeuntochrist]. Optionally, If you have a bugfix ticket from jira, you could create it in the bugfix folder instead of creating your branch at the root, then the path to your branch would be `bugfix/CUC-[some numbers]-[some name]`.

### Working with Devops

There are two sites that allow you to see all the DevOps processes that have built or are being built. Sometimes, these processes will fail and you'll need to re-build them or you can build them at any time by pressing "Run Pipeline" and selecting the branch you'd like to build.

[Hannah DevOps](https://dev.azure.com/churchofjesuschrist/Nurture/_build?definitionId=5345)

[CMS DevOps](https://dev.azure.com/churchofjesuschrist/Nurture/_build?definitionId=5511)

### CMS specific

If you are running a CMS DevOps branch you will need content to fill your custom CMS. In order to do this you will need to do a _Content Pump_. The instructions to do this are located in the [CMS README](https://github.com/ICSEng/cuc-cms#content-pump)

### Content location

While working on the Hannah DevOps side the CMS/content will come from `dev` by default and this will be indicated in the top left corner of the web page. You can adjust where you get your content by using the `?CMS_LANE=` query and using the values `dev`, `test`, `stage`, at the end of your URL or if there is a CMS devops lane you'd like to use for the content you can use it's respective `cuc #` (i.e. `?CMS_LANE=1234`).

The default `CMS_LANE` for a DevOps instance can be changed to not require the query override. You must login to cf in terminal first, then run:

```
cf target -o "Missionary Work" -s "comeuntochrist-non-prod"
cf set-env CUC-1234-hannah CMS_LANE 1234
cf restage CUC-1234-hannah
```

This will update the `CUC-1234` DevOps instance to now default the `CMS_LANE` to `1234`. The restage will take a few mins to complete.

### Storybook

It's also important to note that you can also access storybook on your lane by going to the URL with `/storybook` at the end of it (e.g. https://cuc-1234-hannah.pvu.cf.churchofjesuschrist.org/comeuntochrist/storybook)

## Components

A component is something which knows how to ["Do One Thing and Do It Well."](https://en.wikipedia.org/wiki/Unix_philosophy#Do_One_Thing_and_Do_It_Well) It should be limited in scope. Some components will be used to render HTML while others may only add CSS and/or JavaScript to the application. Many are located in `/src/components` but others may be installed as NPM modules.

### Making a new component

To create a new component run the following and follow the prompts.

```bash
npm run component
```

This will output a new folder with a structure as defined below for your component.

### File Structure

Components for Hannah use a standard structure:

```
+-- component-name [Lowercase and hyphenated.]
    |-- browser.js [JavaScript which needs to end up in the browser.]
    |-- index.js [The main entry point which exports a "render" function.]
    |-- mocks.js [Exports mock data objects which can be used for testing, etc.]
    |-- styles.css [Styling for the component.]
    +-- critical.css [Important styling for the component that will be loaded immediately upon page load, instead of waiting to load when the component comes into view]
```

#### **browser.js**

Some components use client-side JavaScript. For example, a form may need to submit data via AJAX, or a menu may need to toggle the display of its menu items. Any JavaScript needed in the browser should be included here, and any JavaScript not needed in the browser should not be included here. Be careful what this file `import`s.

#### **index.js**

The main entry point of a component. It's default export should be function which returns an HTML string from a given component data object. Most "render" functions will use a template literal.

#### **mocks.js**

When testing, it is useful to have mock data. This file will export various data objects needed to test various scenarios which the component may encounter.

#### **styles.css**

Contains styling for the component. Hannah uses https://github.com/css-modules/css-modules which helps modularize CSS and allows components to import and use styles in JavaScript. Styles for components are loaded on to the page as the components are scrolled into view.

#### **critical.css**

Occasionally a component has some styling that needs to be used immediately when the page begins to load. Those styles are placed here in the critical.css file.

### Data Object Structure

The "render" functions within Hannah accept a data object and return an HTML string. The default export of `/src/components/index.js` is a generic `render` function which can be used to render a component or array of components dynamically. In order to do so, it expects a `type` property in each component data object.

For example, the data object for an `image-block` component would look something like the following

```json
{
  "type": "image-block",
  "URL": "http://example.com/some-image.png"
}
```

### Component Regions

Some components contain children "component regions." For example, the main `page` component renders the standard markup for an HTML document. Inside `<body>` it contains one component region where it dynamically renders an array of other components.

Whenever a component contains a region for other child components, the data object should include these under a `components` property. For example, a `page` component would expect a data object like the following:

```json
{
    "type": "page",
    "title": "The Title of the Page",
    "components": [
        {
            "type": "image-block",
            "URL": "http://example.com/some-image.png"
        },
        ...
    ]
}
```

## Cloud Foundry

To monitor servers and see real time logs for ComeUntoChrist, we use Cloud Foundry.

1. You will need to get permission to access Cloud Foundry from the team's ASE (application support engineer). The team's ASE is currently Dave Totten.
1. Navigate to the website: https://ui.cf.churchofjesuschrist.org/home
1. Typically speaking, you'll need to reconnect the endpoint to access everything. Navigate to the `Endpoints` section on the left side of the page. Click the three dots by the PVU endpoint and click disconnect. Then go to the same menu and click reconnect.
1. You're now ready to go! Here are two of the main features we use:
   - `Applications` section where you can access the various lanes we have running (`dev`, `test`, `CUC-1234`, etc.) and you access the logs, restart them, stop them, etc.
   - `Services` section which is where we can store variables across the different lanes such as private usernames, passwords, API keys, etc. (Detail on local access to this in [Local Services](#Local-Services))

## Structure

The following is a high-level description of the application's folder/file structure.

```
hannah
    |-- cf-configs [CloudFoundry services configuration files]
    |-- dist [The built applications ultimately run from here.]
    |   |-- browser [These files become publicly available under the `/static` URI in the client.]
    |   +-- server [The server-side express app.]
    |-- docs [Any additional documentation.]
    |-- manifests [Manifest files for CloudFoundry deployments.]
    |-- node_modules [Created when running `npm i` and is where all NPM packages are installed.]
    |-- src [The application's main source files. All development is done here.]
    |   |-- adapters [Modules for interfacing with external sources (e.g., CMS).]
    |   |-- apps [Entry points for the various applications]
    |   |   |-- components [The components applications]
    |   |   |   |-- browser.js [The entry point for the components browser JS application.]
    |   |   |   +-- server.js [The entry point for the components server-side express application.]
    |   |   |-- browser.js [The entry point for the browser (client) JS application.]
    |   |   +-- server.js [The entry point for the server-side express application.]
    |   |-- locales [Contains a map of all the application's supported locales.]
    |   |-- middleware [Custom express middleware.]
    |   |-- styles [Application-specific CSS styling.]
    |   +-- utilities [Custom utility modules.]
    |-- test [Test files. (Component unit tests should exist within the components' directories.)]
    |-- webpack [Various configurations for webpack.]
    |-- .babelrc [Configuration for Babel which handles transpiling ES6+ to ES5]
    |-- .cfignore [Things which Cloud Foundry should ignore.]
    |-- .env [Additional ENV variables which are added via the `dotenv` package.]
    |-- .eslint [Configuration for ESLint which helps us keep the code nice.]
    |-- .gitignore [Things which git should ignore.]
    |-- .nmprc [Configuration for NPM.]
    |-- .nvmrc [Configuration for NVM.]
    |-- package-lock.json [NPM's manifest for locked package versions. This is _NOT_ git-ignored.]
    |-- package.json [NPM information for the application.]
    |-- README.md [Where this documentation comes from.]
    +-- TODO.md [A list of things that need to happen.]
```

## Pull Request Process

Pull Requests (PRs) are an opportunity for learning. When your code is reviewed, you may receive feedback of better ways to do things, particularly for interns. Hopefully you also take time to review why you as the writer of the code received the feedback you did. Did you miss a requirement, incorrectly interpret a requirement, accidentally left something there, didn't know the better way, etc.

As a reviewer, when you see others give feedback you can learn from them as well. If they came after you, why did they catch what you missed? How can you do better as a reviewer going forward?

### Creating a Pull Request

When you create a pull request, you should do a quick review of all the code that shows as changed. While you are likely sick of looking at the same code over and over, make sure that the changes you see are the changes you made. If you are seeing additional changes you are not expecting, you should understand why they are there.

The PR is your code, you should be able to explain why everything is there. While there are always exceptions, it should be rare to say "I don't know why that is changed".

Look at your PR with the eye of the reviewer and the things they will be looking at or comparing to. Have you done your due diligence to account for the list below as much as possible? The reason we have PRs is to catch small things that have been missed or to learn of new ways to do things. If many things are found and obvious requirements were missed, you need to evaluate your own processes so that things are not missed in the future.

#### Naming the PR

Typically you will not have to adjust the name of your PR as it will just grab the name of the branch which is perfect. Although if you are creating a PR that only has **one** commit when you create it - it will use that individual commit as the PR name so you'll need to adjust the name to be branch's name. This is mostly important so we can quickly differentiate the PRs by their CUC numbers.

#### Description

To make it easier on all those reviewing please provide a clear description of the bug, what your code fixes, and an easily accessible location to test said changes. Specifically, if applicable, including a devops link or links with an example of changes makes it easiest.

**Example description**

```
Explanation of what broke, quick explanation of the fix. (if fixing multiple components, a bulleted list of which ones were affected would be perfect)

Explanation of how to test it and applicable links.

Broken: https://churchofjesuschrist.org/comeuntochrist
Fixed: https://cuc-1234-hannah.pvu.cf.churchofjesuschrist.org/comeuntochrist
```

### Reviewing a pull request

#### **Review the code**

A non-exhaustive list of things to look for:

- Does it use best practices to the best of your knowledge?
- Using established CSS Vars where available
- Are debugging helps removed? (`console.log`, etc)
- Are commented code blocks removed, unless there is a comment explaining why they should be kept?
- Is there inline documentation for potentially confusing things? Will we understand things in 6 months when we need to look at this again?
- Does the documentation (readme) make sense

#### **Test Code**

Navigate to the devops lane/URL (if applicable) in your browser to visually inspect. Run the component in storybook. There will be times where a PR is for a simple spelling correction or removing an extra `;` or something. Use your best judgment as to when a browser review is needed. Some things you may need to build out on a normal page, if it's a CMS PR you can create it on it's respective Devops CMS URL (i.e. https://cuc-1234-cms.pvu.cf.churchofjesuschrist.org/cms/content-admin/default.xqy?lang=eng&site=churchofjesuschrist) otherwise if there is no custom CMS devops lane you can create a page in another existing CMS lane (i.e. `CUC-1234`, `test`, `dev`, etc.) and then navigate to their Devops Hannah lane pointing it to the lane that has that page you created. For example, if your changes were in `CUC-1234` and it was only a Hannah PR but you needed a custom page to test, you could create a page on the [dev CMS](https://mwpublisher-preview-dev.churchofjesuschrist.org/cms/content-admin?lang=eng&site=churchofjesuschrist) content and navigate to https://cuc-1234-hannah.pvu.cf.churchofjesuschrist.org/comeuntochrist?CMS_LANE=dev.

- If there are design documents (attachments, links to documents that you have access to, etc) compare to the documents and make sure things are visually correct. Look at spacing, color, font sizes, font weight, positioning, image/icon size, etc
- Check RTL - Do things "reverse" the way you would expect. Look particularly for horizontal spacing to flip and spacing from edges and other objects to be maintained
- Accessibility (a11y) - Keyboard access, can you tab through things and select actionable items with a press of the space bar. If you are familiar enough with a screen reader like Voice Over on the mac, try using it to interact with the component
- Can you modify everything you would expect to be able to modify? (text, colors, etc)
- Run through all knobs to make sure they work as expected

#### **Leaving feedback**

- Review code within GitHub and give comments on the related line.
- Make a comment with the details of the feedback and screenshots if needed.
- Ensure that when feedback is fixed or otherwise resolved to `resolve the conversation` so that it doesn't distract from further changes requested. (this is the responsibility of either the reviewer or the author of the code)

# Architecture

## Putting it all Together

```
      1.                      2.                         3.

+----+     +------------------+       +------------------+       +------------------+
|    +---> +                  +-----> | * This is not    +-----> |                  |
|    |     |                  |       |   used anymore*  |       |                  |
|    |     |    HANNAH        |       |    CMS-API       |       |   LDS-Publisher  |
| F5 |     |                  |       |                  |       |                  |
|    |     |   (mormonorg)    |       |   (decorator)    |       |   (repository)   |
|    |     |                  |       |                  |       |                  |
|    + <---+                  | <-----+                  | <-----+                  |
+----+     +------------------+       +------------------+       +------------------+

      6.                      5.                         4.

```

1. All requests to Hannah are routed from the F5 to CloudFoundry. The F5 is configured to add a header of the
   referring host so Hannah can detect a request for published content or unpublished content, i.e., `www.comeuntochrist.org` vs.
   `comeuntochrist-preview.churchofjesuschrist.org`. This is the `x-forwarded-host` header.

2. Hannah detects that header and constructs a request in the form of
   `https://<cms-api host>>?uri=((Host from x-forwarded-header))/((page requested))`. Hannah sends this
   request to the LDS-Publisher.

3. LDS Publisher receives this request and simply looks up the page (a MarkLogic document) by the URI value. If there is
   match it returns the document in JSON format.

4. Hannah converts this document into an HTML document and response to the request from the F5.

## How it all Works

Content creators will create "Pages" within a "Site" within LDS Publisher. Pages are simple MarkLogic documents that have
been composed using LDS Publisher forms. The Site name matches the Host value from step 1 & 2 above. The ComeUntoChrist.org team
has created custom forms that allow users (publishers) to create pages within a site by adding hannah components, i.e.,
headers, images, content blocks, etc. When each page is created it is assigned a URI by the publisher. This URI is the path
users will enter into the browser (after the host value) to view the page. Hannah will request that page from cms-api, and cms-api from
LDS publisher, as seen above in steps 2 & 3. Hannah will read each component on the page and render that component as
HTML to be display in the browser.

# PAUSE

**Didn't think we'd have you read this WHOLE readme at once did you? Anyways, for now we just want you to focus on understanding the things you've already learned. You can come back and learn more next week if you want, but most of this is optional development tips from here on out anyways. (3 Nephi 17:3)**

---

# Additional Development Tips

These aren't pertinent to the basics of developing on the ComeUntoChrist application but can be helpful if any of these topics pertain to the work you're doing.

## Cloud Foundry CLI

To monitor servers and see real time logs for ComeUntoChrist, use the Cloud Foundry CLI.

1. You will need to get permission to access Cloud Foundry from the team's ASE (application support engineer). The team's ASE is currently Dave Totten.
1. Install the CLI [here](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html).
1. Once the CLI is installed, to use the CLI you must be either in the office or connected to the VPN. You can connect to the VPN by using either Global Protect or Cisco Any Connect. If you decide to use Cisco Any Connect, just be sure that you are connected to either "External Two-Step Admin Access" or the "Internal Two-Step Admin Access". "LDS Remote Access" will not work.
1. If you are in the office or once connected to the VPN, open a new terminal and type
   ```bash
   cf login --sso
   ```
1. You will be prompted to go to a specific URL to retrieve a "Temporary Authentication Code". Go to the URL, copy the access code, and paste it into the terminal.
1. The first time you log in, you will be prompted to enter an API Endpoint: https://api.pvu.cf.churchofjesuschrist.org
1. Enter your Church email and password
1. Type `2` to select "2. Missionary Work" as your "org"
1. Type `1` to see logs for stage or production (comeuntochrist-prod) or type `2` to see logs from any of the other lanes (comeuntochrist-non-prod)

You can also do these same steps all at once by entering the following command (If you want to enter the production space just replace "comeuntochrist-non-prod" with "comeuntochrist-prod"):

```bash
cf login --sso -o "Missionary Work" -s comeuntochrist-non-prod
```

To see the available apps, or rather lanes, that are being run in a specific space, use the following command:

```bash
cf apps
```

To begin viewing the logs for a lane, use the command `cf logs` with the name of the lane. For example:

```bash
cf logs comeuntochrist-dev
```

Use the `--recent` flag to see recent logs that have already happened

To see the VCAP_Serivces and environment variables for a specific lane, use the command `cf env` with the name of the lane. For example:

```bash
cf env comeuntochrist-dev
```

## Adapters

This application interacts with external data sources. An "adapter" is module which fetches data from the external data source and transforms data from the external source into structures which the application expects.

For example, say we have a `widget` component in our application which expects a data object with the following shape:

```json
{
  "title": "Some title",
  "id": "The ID",
  "description": "Some description",
  "created": "YYYY-MM-DD"
}
```

Now say the data for a widget from an external "Killer CMS" source looks like the following:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<widget id="123" createdAt="2017-01-01T09:00:00Z">
  <title>The Best Widget</title>
  <about>Why it's the best...</about>
</widget>
```

The "Killer CMS" adapter must export a function which knows how to get the widget data from "Killer CMS," transform it, and return a Promise. Something like the following:

```js
import getWidget from "../adapters/killer-cms";

const id = 123;

getWidget(id).then(console.log);

// {
//     "title": "The Best Widget",
//     "id": "123",
//     "description": "Why it's the best...",
//     "created": "2017-01-01"
// }
```

## Webpack debugging

To track down what file is causing what other files to be included in a bundle do the following.

- Add `--json > stats.json"` to the end of the webpack build you want to debug. So `"build:browser": "webpack --config ./webpack/browser.babel.js",` becomes `"build:browser": "webpack --config ./webpack/browser.babel.js --json > stats.json",`
- This will output a stats.json file to your project root.
- Load that file into https://webpack.github.io/analyse/
- That site will tell you what loads what (parent and child) to hopefully help you find your problem.

## Adding a non-publisher driven path

To add a path that isn't driven by publisher (an API endpoint, etc) you must edit the following

- `src/apps/server.js` - add the path that you want to use and either define the logic inline or reference the external location

### Adding to the API path

Most non-publisher paths are located within the `api` path. To add to this path, do the following

- Update `src/apps/server.js` as defined above. you can copy existing lines and just update the `API.*` reference
- Update `src/middleware/api/index.js`. Add to the `import` list in the top portion and the `export` in the bottom.
- Add a relevantly named file to the `src/middleware/api/` folder with the desired logic.

## Analytics

### What is analytics

We use analytics to track how users are using our website in ways such as:

- What are they clicking?
- How long are they watching videos?
- Which videos do they watch?
- What components are they clicking on most?

In order to do this, we have an object stored on the `window` called `digitalData` (sometimes called the `data layer`, in fact most of the logic for this is currently in the [analytics.js](/src/utilities/analytics.js) file). So when a user interacts with something on our website we will push the analytics data into the `digitalData` object in varying specific formats (depending on the type of interaction).

We use `Adobe Launch` technology for our analytics tracking and work with a team who manages that technology (the Hoodoo team) and they have a format for most interactions. [Here is a page containing documentation](https://confluence.churchofjesuschrist.org/display/ContMed/Data+Layer+-+Master) of how they're expecting most interactions to look like, although we have some some custom interactions for ComeUntoChrist specifically that are not documented there. You might have to get permission to view that document, in which case you can reach out to one of the Hoodoo employees we work with via email or Microsoft Teams. Jared Linares (jared@hoodoo.digital) or Scott Cannon (scott.c@hoodoo.digital) or whoever the current Hoodoo/analytics contact is.

For reference most objects will look something along the lines of this:

```
window.digitalData.push({
    event, // "Component Click", "Download", etc.
    component: {
      info: {
        contentTitle, // "Beliefs" (title on page)
        interactionText, // "Click Here!" (text on actual element clicked)
        link // "/beliefs/book-of-mormon" If there is a link associated with the clicked element
      },
      category: {
        primary: componentBreadcrumb // "Inline-component-gallery > media-block > caption-block > button" a breadcrumb trail from the top-most component
      }
    }
  });
```

This is what our generic "component interaction" object looks like with comments explaining what the values will look like.

### Adding to analytics

Currently, there are specific analytics set up for some interactions such as sharing, downloading, and all form-related interactions. But the rest of the components will just be watched with a generic "Component Click" eventListener. We don't want _every single_ component to have analytics tracking so we simply add a `use-analytics` attribute to the components we want to track. The code for this is located in the [page/browser.js](/src/components/page/browser.js).
Additionally, for the generic "Component Click" event there is a function that creates a breadcrumb trail of all the components from the parent to the clicked element; (i.e. `emphasized media tiles > emphasized media tile > button`) this is the `getComponentTrail` function. If you have any components that you do _not_ want in this breadcrumb (i.e. background, titan-image, etc.) just add `skip-analytics` to the element (that has the `data-type` on it) that you want to exclude from the breadcrumb.

### Generic Analytics

To add generic analytics to a component, simply add the attribute `use-analytics` on the component/div that you would like to be tracked. Example:

```
<div data-type="cool-button" use-analytics>${cool button stuff}</button>
```

Again, the logic for the eventListener for this attribute is in the [page/browser.js](/src/components/page/browser.js) if you ever need to tweak anything.

### Custom Analytics

Typically the process of adding new analytics will look like this:

1. Hoodoo reaches out because they need more data or (more likely) we reach out because _we_ want to grab more analytics for something.
2. Communicate with them the data we need tracked and they will communicate how that should be formatted.
3. Add the code to the appropriate components so that the data is sent to the `digitalData` object at the right time (described below).
4. Check with Hoodoo/BonCom to make sure that the data is being tracked properly in their databases.

You'll need to add logic so that when the user _interacts_ with the specified component/element it will submit the data that Hoodoo is expecting. It's important to emphasize that you can't just put any object in, you must work with Hoodoo to create the new event/interaction as they're expecting it in the `digitalData` object. The object will most likely be formatted similar to the one mentioned previously (in `What is Analytics`), altered to have the new data needed. The logic to push this to the `digitalData` object will usually look like a simple `element.addEventListener("click", function)` unless the "interaction" is more complex than a "click" (current examples include: `form submission`, `download`, etc.). This will probably just be done in the `browser.js` file of whatever component you're working with to get custom data from.

If you need to add a new **event** to the `window.digitalDataEventsCUC` object, this is found in the [page/index.js](/src/components/page/index.js). Hoodoo will determine what the event should be named and if it's component specific it will most likely be nested within the `component` object within the `window.digitalDataEventsCUC` object.

**General Tip for Testing** When testing analytics click events, it's useful to use Command (or Control on Windows) Click on links so that they open the link in a new tab but will leave you on the same page and will still trigger the analytics event so you can examine them.

## Running a local version of ComeUntoChrist

### Configuration Files

We deploy `Hannah` through Cloud Foundry. In order to see changes that we make during development we need to run things locally; we need to include a "development" version of the Cloud Foundry configuration:

1. Navigate to your `Hannah` repository
2. Create a new file `dev-vcap_services.json` at the root level of the repository, then copy and paste the content from `/cf-configs/vcap_services.json.sample` into your new file.
3. Please note that this json file has comments at the top of the file that need to be removed for it to work properly.
4. If you're on Windows, you need to go into the webpack folder and go into the browser.babel.js file. At the very bottom in the proxy object inside the devServer object you'll see http://0.0.0.0:${PORT} you need to change it to http://127.0.0.1:${PORT}

_Note: We are using ICS's private NPM registry as noted in `/.npmrc`._

### Connecting Hannah to a CMS

Out of the box, the dev-vcap_services.json points to the test instance of our CMS. This allows you to run the hannah code locally without needing a local copy of the CMS running. We will eventually get you to having a local copy, but it is a much more complicated process and we want to get you up and running something ASAP. The first object within the `Http` array in your `dev-vcap_services.json` file should look like the following:

```json
{
  "credentials": {
        "url": "https://mwpublisher-preview-test.churchofjesuschrist.org/cms/api/v1/page",
        "predefinedQuestionsUrl": "http://mwpublisher-preview-test.churchofjesuschrist.org/cms/api/v1/getpredefinedquestions",
        "publisher": "comeuntochrist-preview-test.churchofjesuschrist.org",
        "productConfirmationUrl": "https://mwpublisher-preview-test.churchofjesuschrist.org/cms/api/v1/productconfirmation"
			},
    "name": "comeuntochrist-lds-publisher"
},
```

### Local Services

You'll additionally find in the `dev-vcap_services.json` file a variety of services and APIs (if not all of them) that we use on the frontend. You'll find that the usernames, passwords, API keys, and any other secure information have been filtered with some value similar to "ReferToCloudFoundry". This is because we don't want to store secure IDs and values locally or on GitHub so we store them securely in CloudFoundry exclusively. See [Cloud Foundry](#Cloud-Foundry) for details on how to get access.

Once you have copied over your local vcap file (created the `dev-vcap_services.json` as mentioned in the [instructions above](#Configuration-Files)) you are welcome to copy any of those values that you need for testing purposes into your local file because it doesn't get pushed to GitHub and will stay on your machine. Simply ensure you aren't copying them into the `.sample` file and pushing that up in any of your PRs.

### Development Server

Hannah contains a development server which can be started with the following:

```bash
npm run dev
```

#### If you run into errors:

- Try deleting `node_modules`, clearing cache, and reinstalling node. In a fresh terminal run `nvm use` to make sure the correct version of node is being used.
- Ensure You are using the correct version of Node.js by running `node -v`, if your node version does not match the version specified in the [`.nvmrc`](./.nvmrc) file you may run into errors. `nvm install [version]` then `nvm use [node version]` will likely be what you need to run in your command prompt.
- If you receive this error `Error: error:0909006C:PEM routines:get_name:no start line` make sure that you properly installed the security certificate and ran the mkcert command in your hannah directory. If ran in the wrong directory you may encounter this error as you will not have the `localhost.crt` and `localhost.key` files in your root directory.
- If your error looks similar to this `Error: listen EACCES: permission denied 0.0.0.0:80` try running `net stop http` as admisitrator in the command prompt. It may be that the port that you are trying to use for the local instance is being used by another device or service which is usually the case for windows machines. If this solves your problem you may need to run this each time or identify what else is using that port.

This automatically runs a build using `NODE_ENV` set to `development` and then starts two servers:

1. The development server with [webpack's HMR](https://webpack.js.org/concepts/hot-module-replacement/) runs at https://localhost or https://cuc-local-hannah.pvu.cf.churchofjesuschrist.org/comeuntochrist. This can be used during active development. The Come Unto Christ application can be seen locally with https://local.churchofjesuschrist.org/comeuntochrist.
2. The application's express server runs at http://localhost:2021. This version of the site more closely mimics the production site but will not pickup code changes during development. That is, the `dev` script will need to be re-run after making any development changes.

There's a value `http.credentials.publisher` inside your `dev-vcap_services.json` file, this dictates which environment/lane the application pulls content and components from (by default this points to the `test` lane). You can change this value to determine which lane you're pulling content and components from. For example, you can see what your code would look like in the `release` lane versus the `development` lane or the `test` lane.

If you want to test a component that doesn't yet exist in any of the lanes, you'll need to create it in a local cms server hosted via `localhost`.

### **Production**

Running a production version of Hannah requires two steps:

#### **Build**

Hannah is written in ES6+ and uses [Babel](https://babeljs.io/) to convert everything down to ES5.

The build compiles the `/src` directory to the `/dist` directory. You should not modify any files in `/dist` since it will be recreated during each build. (It's also git-ignored.)

```bash
npm run build
```

_Note: The `build` script automatically runs with `NODE_ENV` set to `production`. If needed, `npm run dev:build` will build using the development environment._

#### **Server**

Once a build has been run, the production server can be started with the following:

```bash
npm start
```

Currently the production server is set to run on http://localhost:2021.

## Running a local version of CMS

The majority/rest of this section will be located in the CMS README, but here are the parts that you'll need to setup on the `hannah` side of things.

If you want to test a component that doesn't yet exist in any of the lanes, you can pull data from your local `cms` repository, which you can host via localhost. This will require updating your `dev-vcap_services.json` file and using browser plug-ins to adjust the headers to reroute the online data to use your local cms data instead.

### Configuring vcap file

To setup hannah to talk to the local version of the CMS you will need to edit the `dev-vcap_services.json` file by replacing the first object within the `Http` array with the following:

```json
{
  "credentials": {
    "url": "http://localhost:10090/cms/api/v1/page",
    "predefinedQuestionsUrl": "http://mwpublisher-preview-local.churchofjesuschrist.org/cms/api/v1/getpredefinedquestions",
    "publisher": "comeuntochrist-preview-local.churchofjesuschrist.org",
    "productConfirmationUrl": "https://mwpublisher-preview-local.churchofjesuschrist.org/cms/api/v1/productconfirmation"
  },
  "name": "comeuntochrist-lds-publisher"
}
```

The `publisher` value in the `credentials` needs to match whatever `local` URL you are hitting (i.e. `local.comeuntochrist.org`) not including the `https://`. After that you need get your `local CMS` running and go to `localhost:10090` > `Content Admin` > `Sites` (located in the left sidebar) > `mormonorg-global` and then edit the `Preview Host` value to be the same as this `publisher` value we changed earlier.

## Additional Local/Publishing Tips

- Hannah's connection to CMS-API is set in the `dev-vcap_properties.json` file while running locally. The `url` property is used.
- CMS-API is a Java application that can be run locally. The connection to LDS Publisher is set in the `resources/application-local.yml`.
- LDS Publisher will require the following configuration items to find the pages created within Publisher

  - Site
    - "Preview Host" must be set to the host entered in the browser for unpublished content. i.e.,
      `comeuntochrist-preview.churchofjesuschrist.org => https://comeuntochrist-preview.churchofjesuschrist.org/path/to/page`.
    - "Published Host" must be set to the host entered in the browser for published content. i.e.,
      `www.comeuntochrist.org => https://www.comeuntochrist.org/path/to/page`.
    - "Site Context" must be set to "/"
    - "Templates" must contain at least one template and it must be the "comeuntochrist.Org Universal Template"
  - Page

    - A page must contain at least one component.
    - All Components must be set to "published" (for published content), otherwise the page will generate a 500 - Internal Server Error at the
      CMS-API level.

# Additional Details

## Accessing SonarQube Scan Reports

SonarQube is a Code Quality Assurance tool that collects and analyzes source code, and provides reports for the code quality of your project.

### To Request Access

- Try to sign in to see if you already have access [here](https://sonarqube.churchofjesuschrist.org/projects)
- If you cannot sign in or see no projects follow the instructions [in this guide](https://confluence.churchofjesuschrist.org/display/CUC/How+to+Access+SonarQube+Dashboard)

## Other SonarQube Links

- [SonarQube documentation](https://confluence.churchofjesuschrist.org/display/ALM/Getting+Started+With+SonarQube+Enterprise)
- [SonarQube Teams Channel](https://teams.microsoft.com/l/channel/19%3aeb428ddabd914c6299c3ef61a0f035fd%40thread.skype/SonarQube?groupId=6178ec7f-1d72-461a-9b4d-ff8f53ca1f8f&tenantId=61e6eeb3-5fd7-4aaa-ae3c-61e8deb09b79)
- [Slider deck for the Sonar training](https://office365lds.sharepoint.com/:p:/r/sites/AWS/Shared%20Documents/General/Trainings/2023-11-16%20-%20Sonar%20Qube%20and%20Renovate%20Up%20to%20date%20and%20secure%20-%20Cloud%20User%20Group.pptx?d=wb9756202fdfc4dc1b34e155461ab73fe&csf=1&web=1&e=AUWbnj)

#### Point of Contact: Evan Porter, Gavid Todd

## Titan

The host for all images used on the site is [Titan](https://titan.churchofjesuschrist.org/). The site takes an uploaded max-resolution image and automatically makes "renditions" at various sizes using compression algorithms to optimize for size. Boncom uploads to titan (or sends to titan people to add) and then can reference the images by titanID from within LDSP.

In the scripts/titan-parsing.js file you will find some helpful scripts that can be run relative to titan.

### Recreate Titan Renditions

There is a `Recreate Titan Renditions` link on any individual Titan image page a user can click to re-render images. When they initially setup the system their performance optimization was poor and images were way larger than needed. That was fixed, but it is resource prohibitive to run the update on 10s of thousands of images, when the extra size only matters for web use.

Within the titan-parsing.js is a way to quickly run the process on a list of IDs. The need to run this should diminish over time as more and more of the images we use are updated.

### View Titan filesizes

As of this writing you can't see the size of the renditions on the Titan website. Another snippet in the titan-parsing.js file will inject filesizes on an individual image page. The script will need to be re-run each time you change to a different image. Details in the js file.

### Large File Logging

In the local and dev lanes the server will log out any large images it finds. This is based on data we have about the images from titan. For a while boncom used a lot of PNG files which should have been JPGs (photos, textured illustrations, etc). Again, these should hopefully diminish over time, but the logic in titan-image/index.js will log out anything that is over 400kb.

<a name="adding-a-theme"></a>

## Adding a Theme

At times there will be a request to add a new theme, or a new set of colors based on a holiday or special event, to the CUC website.

Currently we support the following themes:

- <span style="background-color:#ea7225;color:#FFF;">&nbsp;"default"&nbsp;</span> - This is the normal site with a primary color of orange.
- <span style="background-color:#d50032;color:#FFF;">&nbsp;"christmas"&nbsp;</span> - Also known as "Light the World". This has a primary color of red.
- <span style="background-color:#592569;color:#FFF;">&nbsp;"easter"&nbsp;</span> - This has a primary color of purple.

If you want to add a new theme then you will need to make changes to the following files:

- This file `hannah/README.md`:

  - Modify this section, **Adding a Theme**, to include the new theme and its primary color.

- The file `hannah/src/styles/colors.css`:
  - At the bottom of the file add a new section like this:
    - `[set-theme="easter"] {}` but change from `easter` to the new theme name.
    - Copy all of the entries from the easter block and paste them into your new block.
    - Change all of the color variables to match the new theme. If there are new colors that do not have a variable already defined.
      - For example the color `#ea7225` already has a variable named `--yellow-25` and you should use the variable name `--yellow-25` instead of the color value `#ea7225`. If there is no variable name already defined for your color then check with the team lead about how to name new colors.
- The file `hannah/src/components/page/index.js`:

  - There is a constant value called `FAVICON_COLOR_OPTIONS` defined towards the top of the file. This is an array of valid theme names. Add your new theme name, all lower case, to this list.

- The file `hannah/src/components/background/styles.css`:

  - If you had to create a new name for any of your colors then you need to add the appropriate section for background colors similar to this:

  ```css
  &.bgcolorLTWRed {
    background-color: var(--ltw--red);
  }
  ```

  - Make sure to change the selectors to match your theme name. Use **IntraCaps** on the name and not **snake-case**.
  - Also change the name for the CSS variable to match your correct color.

- The file `hannah/.storybook/commonKnobs.js`:

  - Add your new name into the list `bgColor.options`

- The file `cms/src/main/xquery/_configuration/ALL/mormonorg-settings.xml`

  - Add your new named colors into the followng sections: `<background-color>` and `<foreground-colors>`

> You may want to check all of the other CSS files in `hannah/src/components` to see if you need to add your color in any of these files too. We are trying to remove the need for colors in other CSS files, but, until we have finished that work, you may still need to do it.

## Updating Versions of Dependencies

### Updating Node/NPM

You need to update the node version in 3 places

- package.json `engines.node`
- .nvmrc file
- pipelines/azure-pipelines-\*.yml where it lists `NodeVersion`

### Updating Packages

For any major version updates, make sure to review changelogs for updates we may need to make to our code.

Make sure to update by running `npm i PACKAGE_NAME` so that `package-lock.json` is updated as well. You can specify a version number to update to if you want to by doing `npm i PACKAGE_NAME@VERSION`.

Running `npm outdated` will show you which packages are out of date.

## Install Java

AdoptOpenJDK binaries and scripts are open source licensed and available for free. The Workforce App Store has a binary install available for you and this is the easy way to set up and install Java. You will see in the CMS readme.md file that versions are important, so make sure you read it carefully before you decide which version to download.

## Change Log

### Name Change

A reivew to update references to moml or MOML acronyms was performed on Aug 17, 2023. In response to the site name change from mormon.org to comeuntochrist.org. Hence, if you see references to MOML instead of CUC anywhere in JIRA work items or code, then you know why. For ex: `src/middleware/page-manager.js` this file has an old reference to MOML-7244 (a jira work item). In case there is ever a confusion in the gitub branch names or work items or notes this can help to provide clarity.

--------------------- TEMPORARY ---------------------

# Testing

_Coming soon..._

Tests will be run with the following:

```bash
npm test
```
