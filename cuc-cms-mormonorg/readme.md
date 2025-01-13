# CMS

# Table of Contents

-   [Introduction](#introduction)
-   [Creating a template](#creating-a-template)
-   [Content Pump](#content-pump)
-   [Running Scripts](#running-scripts)
-   [Local CMS Setup](#local-cms-setup)
-   [Setup](#setup)

# Introduction

The `CMS` is an in-house Content Management System (CMS) called LDS Publisher (LDSP), commonly known as cms. Common words thrown around for this are CMS, Publisher, or occasionally musketeer. This is the README for this repository.

# Creating a Template

## Create the new template file

To create a new template, go to the src/main/xquery/\_configuration/ALL/templates folder. It is probably easiest to start with an existing template such as moml-international-article.template.xml

Below are details about the different element/attributes within the file.

### Template

Attributes

-   id
-   display
-   added-fields
-   needs
-   suppress-reference
-   convert-to-universal-template

### Region

Within that template you will see `region` elements which define sections of the page that will contain defined components. The `region` element has a `fixed-order` attribute. If it is `true` then the child components will display in the order they are defined. If it is `false` the user will be provided a dropdown of the listed components to put in any order and as many times as they want.

### Component

You define a component to be used by making an element that has the component name as the element name.

Attributes

-   `content-type` - Matches the name of the component (ex: mo-content-block)
-   `title` - Displayed text for the component (ex: Content Block)
-   `only-one` - true means the component can only be used once
-   `fixed` - true means the component cannot be dragged to a different position in that section.

## Update page-transform.xqy

Search for `case 'mo-international-article-template'` and duplicate the row, making updates to the new row to reflect your new template name in two places.

Search for `declare function pt:mo-international-article-template-transform` and duplicate the entire function to which this is the start of. As of now, it seems you just modify the $template line to point to your template and update the function name to match as well.

# Content Pump

The content pump is how we move CMS data from one lane to another lane. This is especially needed for our new devops model which sets up its own empty instance of the CMS and data needs to be copied over.

## Linux Environment Set Up (Windows Users)

Content Pump requires a Linux/Unix based environment. Following the steps below will get a Linux Environemnt with the correct JDK version and Cloud Foundry CLI set up on your Windows machine

### Ubuntu Install and Update

-   Install Ubuntu using the instructions [here](https://confluence.churchofjesuschrist.org/display/CSP/Installing+Ubuntu+in+windows+WSL)
-   Once Ubuntu is installed, open it and run the command `sudo apt-get update`

### JDK Version 11 Install
-   Install openJDK version 11. In Ubuntu, run the command `sudo apt install openjdk-11-jdk`

### Cloud Foundry CLI installation

-   You will need the Clound Foundry CLI. You can get this by following the Linux Installation instructions [here](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)

### Linking your Content Pump directory

-   With everything installed, we will need to create a symlink or "soft link" to our content pump directory for easier access. Run the  command, `ln -s /mnt/C/{Your path here}/cuc-cms/contentpump  contentpump`. Be Sure that when you enter your path that you replace all back slashes `\` with forward slashes `/`. An example of this command would be `ln -s /mnt/C/Users/JohnDoe/Documents/cuc-cms/contentpump  contentpump`
-   Run the `dir` command and you should now see `contentpump` as a directory
-   Enter the directory by running the command `cd contentpump`

Your Linux environment is now set up and you can move on to the next steps. 

## Commands to run

### For devops sync only

In one terminal window make sure you are logged in to cloud foundry (cf). This command also pre-selects the correct Org and Space
`cf login --sso -o "Missionary Work" -s comeuntochrist-non-prod -a https://api.pvu.cf.churchofjesuschrist.org/`

Then run the following which maps ports on your local system (the #### on the left side of each command) to a port on the remote system (the #### on the right side of each command).
`cf ssh -L 5001:localhost:8001 -L 5000:localhost:8000 -L 5002:localhost:8002 -L 5003:localhost:8003 -L 20090:localhost:10090 -L 20095:localhost:10095 -L 5010:localhost:8010 -L 5011:localhost:8011 cuc-####-cms` replacing the `####` near the end with your equivalent cuc number.

The above needs to remain running in its own terminal when moving on to the next steps.

### For any sync

In a new terminal run the command for the content pump portion you need to run

-   Change into the directory: `cd contentpump`.
-   Run `./cuc-data-sync.sh -INPUT -OUTPUT -LANG` where options are replaced as follows
    -   `INPUT` would be `dev` `test`. You can also use `local` if your have good data locally. This can theoretically run faster as you don't have to download and upload which is what happens when pulling from another lane. It is pulled down to your machine and then up to the designated lane.
    -   `OUTPUT` would be `devops` (will use the devops domain defined in the above tunnel) `local` `dev` `test`
    -   `LANG` would be the name of the language (see available options in contentpump/mlcp/configuration/cuc/query-filters). `non-big-4` for all langs except eng/spa/por/fra
-   Example: `./cuc-data-sync.sh -dev -devops -russian` will use `test` as the input, sending to the `devops` lane defined in the tunneling command, and copy the `russian` language pages over

For a devops setup, you can use the above to copy over the setup files which would include all the sites/redirects/resources/etc to get the CMS mostly functional

`./cuc-data-sync.sh -dev -devops -setup`

### Troubleshooting / Warnings

-   Do not run more than one content pump at a time. Both will lock up.
-   If you run into any other issues in the terminal while trying to run the contentpump, your `java` version might be to blame. One potential solution is to downgrade your `java` version until it works correctly. We know that `11.x.x` versioning works and that version `17` didn't so ensure you're using something between those two. Also important to note that due to licensing reasons the church computers use `openSDK` versus the traditional `java` and the workforce app should replace it for you.
-   It is possible for Windows users to get the error `/bin/bash^M: bad interpreter: No such file or directory` when Ubuntu tries to run the `cuc-data-sync.sh` and `mlcp.sh` scripts. This is because of special return characters found in files edited with windows. Linux doesn't recognize these characters and they need to be removed. To remove them enter the `contentpump` directory and run the command `sed -i -e 's/\r$//' cuc-data-sync.sh`. Then go to the directory with the `mlcp.sh` script and run the command `sed -i -e 's/\r$//' mlcp.sh`. Go back and try the content pump again and it should run without the error.
-   It is possible to encounter read-write access issues on unix based systems with the `mlcp.sh` file. If that is the case, run the `chmod 755 mlcp.sh` command while in the `mlcp` directory.  

### For local setup

In addition to the above, also run the following to pull down some additional files that are normally created during a build
`./cuc-data-sync.sh -dev -local -local`

# Running Scripts

Sometimes we need to manipulate the content itself that is saved on our servers. For example, if we change an key/value pair from `invertTextColor: "false"` to `invertTextColor: false` (notice the difference can be as subtle as the value being a string versus a boolean) that will not change the current data in our database, so everything will still be `"false"` instead of the new `false` value we want to implement. In order to fix this we need to create and run scripts that can crawl through our data and manipulate the data accordingly whether that be updating, deleting, or inserting new data.

## How to create scripts

Scripts consist of two main parts: 1) the comment header with a description of the script and 2) the actual script itself. Scripts will be saved to the `dbScripts` folder which is located at `src/main/xquery/dbScripts`. The name of the script should just be the name of the PR/jira with the `.xqy` file extension at the end (i.e. `CUC-1234-whatever-it-does.xqy`).

Here is a basic example that you can copy/paste as a template:

```
(:
    Date: 6 April, 2022
    Author: Rye Chuss Doode
    JIRA: CUC-1234-whatever-it-does
    Rerunable: Yes
    Description: This script will add new labels to the string bundle(s) for Instagram and YouTube
    QConsole Settings: database: cms; server: _app_cms_preview_10090; Query Type: XQuery
:)

let $social-media-bundles := for $i in cts:search(/resources, cts:element-value-query(xs:QName('name'), 'mormonorg-social-media-labels-config', 'exact'))/properties

let $instagramLabel :=
    <entry key="instagram">
        <value>Instagram</value>
    </entry>

let $youtubeLabel :=
    <entry key="youtube">
        <value>YouTube</value>
    </entry>

return
    (
        if ($i/entry[@key eq 'instagram']) then ()
        else xdmp:node-insert-child($i, $instagramLabel)
    ),
    (
        if ($i/entry[@key eq 'youtube']) then ()
        else xdmp:node-insert-child($i, $youtubeLabel)
    )

return 'CUC-1234 script completed.'
```

### How to run scripts

Before we run the scripts on the stage (or other) lanes we want to test them on our individual devops lane. In order to do this, ensure that your tunneling command (the `cf ssh -L 5001:localhost:8001 -L 5000:localhost:8000 -L 5002:localhost:8002 -L 5003:localhost:8003 -L 20090:localhost:10090 -L 20095:localhost:10095 -L 5010:localhost:8010 -L 5011:localhost:8011 cuc-####-cms` command that was ran in the [Content Pump section](#Content-Pump)) is running. If it's not running, refer to the Content Pump section to get that set up.

Once you are tunneling in, navigate to `localhost:5000/qconsole` in your browser. This will bring you to the console that allows you to run scripts. Copy/paste your script here and ensure that the settings at the top of the page match up with the `QConsole Settings` of your script file's description.

Once you're all set up, click the run button near the bottom of the window and any logs will show up in the logging section below the scripting area. Your script should have successfully been run so you can check out the devops lane to see if anything broke and if not then it should be ready for review by the other devs (create a PR if you're done).

## Troubleshooting

If `localhost:5000/qconsole` doesn't work, you can try `127.0.0.1/qconsole` or some of the other ports that are running in the tunneling command (i.e. `localhost:5001/qconsole`, `localhost:5002/qconsole`, etc.) and if that doesn't work, check if the `5000` port is being used on your machine (instructions found [here](https://wilsonmar.github.io/ports-open/)).

# Local CMS Setup

## Permissions you are going to need

You will need to have the following [Key Access](https://keyaccess.ldschurch.org/landing/) Permissions to connect to the CMS through the dev life cycle.

| Name                                   | Description                                                 | Category       |
| -------------------------------------- | ----------------------------------------------------------- | -------------- |
| Admin VPN Access                       | gp-ldsAdminAccess - Admin VPN - Admin VPN - Admin_VPN       | Admin VPN Zone |
| Mormon.org Previewer Group             | mormon_org_previewer - Mormon.org - Mormon org - Mormon_Org | Mormon.org     |
| SECURE_APZ                             |                                                             |                |
| SECURE_BBZ                             |                                                             |                |
| SECURE_CAZ                             |                                                             |                |
| SECURE_TAPZ                            |                                                             |                |
| SECURE_TAPZ_NP                         |                                                             |                |
| Splunk Access to Missionary Work Index |                                                             |                |

You will also need access to the Artifactory for Marklogic to run the CMS. We'll do this when you set up Docker later.

## Browser Plugins

You can override where your local environment pulls CMS data on the fly by adding an additional header to the http request.

Various extensions can facilitate this. Search for `ModHeaders`, `Modify Headers Value` or others that allow you to modify the headers sent with a page request. **Keep in mind** that is this an optional step and will only work on browsers where you can access these types of extensions, so might not be optimal with Safari, Mobile devices, etc.

Once installed you will need to add a header as follows

| URL                           | Header Name      | Header Value                                        |
| ----------------------------- | ---------------- | --------------------------------------------------- |
| local.churchofjesuschrist.org | X-Forwarded-Host | comeuntochrist-preview-test.churchofjesuschrist.org |

## Docker Setup

First, you will need to [install docker](https://docs.docker.com/get-docker/).

---

#### **Hyper-V and Virtualization (Windows Only)**

If you are running Windows, before Docker can work you will need to enable Hyper-V and Virtualization on your machine. If you are running MacOS, it should be simpler.

To enable Hyper-V, go to PowerShell and type the following command: `Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All`

Restart your computer and open the BIOS during the reboot (Look up instructions for how to do that before restarting your machine. Usually you press **ENTER** or **F2** repeatedly before the Windows logo appears on reboot).

In BIOS, find "VIRTUALIZATION TECHNOLOGY (VTx)" and press **+/-** to set it to "ENABLED."

When your system is back online, check your task manager and click on **Performance**. You should see "Virtualization : Enabled" in your CPU performance.

---

Run this command to authenticate with Docker. When prompted for a username and password, log in with your **church** username/password.

```bash
docker login icsdockerhub.ldschurch.org/ldsml/marklogic-development
```

If logging in didn't work or you need additional help - you can check out this webpage on getting docker set up: https://confluence.churchofjesuschrist.org/display/ALM/Getting+Started+with+Docker

You will then need to run this command to get marklogic downloaded so that you can run the CMS locally. I recommend doing this download in the CMS root folder so that it is all contained in one location.

```bash
docker pull icsdockerhub.ldschurch.org/ldsml/marklogic-development
```

Then to get marklogic running as a service on Docker to allow you to load the CMS you need to run the following command:

-   MacOS / Linux :

```bash
docker run -d -p 2022 -p 8000-8020:8000-8020 -p 8901:8901 -p 10090-10099:10090-10099 --name publisher -v $(pwd):/cms icsdockerhub.ldschurch.org/ldsml/marklogic-development
```

-   Windows (powershell):

```bash
docker run -d -p 2022 -p 8000-8020:8000-8020 -p 8901:8901 -p 10090-10099:10090-10099 --name publisher -v $(Get-Location):/cms icsdockerhub.ldschurch.org/ldsml/marklogic-development
```

Additionally, if you ever restart your computer or docker otherwise gets turned off after you've done these previous steps you'll need to run this command to start it up again.

```bash
docker run publisher
```

To verify the container is running as expected, execute a process-status query: `docker ps`. You should see a line of output (possibly wrapped) with a STATUS column indicating the total uptime.

### **If publisher doesn't show up**

If you do not see the "publisher" container you just created, type `docker ps -a` to see ALL containers, whether they are running or not. If you only see your publisher container after viewing all containers, you might want to try starting it again. A few commands that could help you start, stop or delete a container and try again are below.

> | Description                                                        | Command                                                                         |
> | ------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
> | View running containers                                            | `docker ps`                                                                     |
> | View all containers                                                | `docker ps -a`                                                                  |
> | Try starting up "publisher" container again                        | `docker start publisher`                                                        |
> | Stop "publisher" container                                         | `docker stop publisher`                                                         |
> | Stop all containers                                                | `docker stop $(docker ps -a -q)`                                                |
> | Remove the "publisher" container, so you can try building it again | `docker rm publisher`                                                           |
> | Delete the MarcLogic image (You will need to re-pull it)           | `docker rmi docker pull icsdockerhub.ldschurch.org/ldsml/marklogic-development` |
> | Remove all images (You will need to re-pull the MarkLogic image)   | `docker rmi $(docker images -q)`                                                |
>
> If commands are not working, try running your terminal as an Admin. You can find more cheat sheets online. You might also consider restarting your machine because that has worked in the past.

Docker should now be running MarkLogic properly, this can be checked at `http://localhost:8003`. We'll be using this more after we set up CMS, Maven, and Java.

## Java

In order to build the CMS you will need to have the Java Development Kit installed locally on your machine. As of the writing of this Document Java JDK is no longer free for commercial use and so it is recommended to use the OpenJDK instead. Amazon is currently distributing a free version of the JDK, that can be obtained from the instructions below.

1. Open: https://aws.amazon.com/corretto/
2. There will be multiple buttons, each of the buttons will direct you to a different version of Corretto. Click on the most recent (typically the one with the largest number).
3. Here you will find a table with all the different ways to install Corretto.
    - **For MacOS:** In the macOS row, click and download the link under the Download-link column with the `.pkg` extension (e.g. https://corretto.aws/downloads/latest/amazon-corretto-15-x64-macos-jdk.pkg)
    - **For Windows:** Download the Windows version, then skip steps 4 and 5.
4. After downloading the package, click on the package to activate the auto-installer and follow the installer's instructions. The auto-installer should automatically place a new folder called `amazon-corretto-xx.jdk` (xx being the version you installed) in `Library/Java/JavaVirtualMachines`. However, if this is not the case find the `amazon-corretto-xx.jdk` folder (Check your downloads folder) and place your new amazon-corretto-xx.jdk folder in `Library/Java/JavaVirtualMachines`.
5. Now that your JDK is in place, you need to tell your terminal where to find it. Open `/Users/<username>/.zshrc` add the following code. Remember to replace the "xx" with your version of Corretto.
    ```
    export JAVA_HOME=/Library/Java/JavaVirtualMachines/amazon-corretto-xx.jdk/Contents/Home
    export J2=$JAVA_HOME/bin
    ```
6. To check that everything is working correctly run `java -version` in a new terminal.

## Maven

To install Maven follow the _Download_, _Install_, and _Run_ steps on this website: https://maven.apache.org/index.html

**For MacOs:**

1. After opening the link, find and click on the download button. This will open a page where you can find the `Binary zip archive`
2. Click on the link beside `Binary zip archive`. The link will be something like: `"apache-maven-x.x.x-bin.zip"` (x.x.x being the newest version) and save the file.
3. Unzip the file to create a new directory called `apache-maven-x.x.x `.
4. Go to `/Library`, create a directory called `Maven` and move `apache-maven-x.x.x ` into your new `Maven` directory.
5. As with the JDK, we now need to tell the terminal where to find `Maven`. Open `/Users/<username>/.zshrc` and paste in the following code. Remember to replace "x.x.x" with your version.

    ```
    export M2_HOME=/Library/Maven/apache-maven-x.x.x
    export PATH=$PATH:$M2_HOME/bin
    ```

6. To make sure that everything is working run `mvn -version` in a new terminal.

**For Windows**

-   Add maven to your environment variables

## CMS Setup

To allow Maven to work with your cms you must have a `settings.xml` file. Navigate to `/Users/<username>/.m2` (MacOS file structure) and edit or create the settings.xml file.

-   Mac OS / Linux:

```bash
<your username> ~/.m2/settings.xml
```

-   Windows:

```bash
C:\Users\<your username>\.m2\settings.xml
```

Copy and paste the following code into your `settings.xml` file.

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemalocation="http://maven.apache.org/SETTINGS/1.1.0 https://maven.apache.org/xsd/settings-1.1.0.xsd">
<servers>
    <server>
    <username>ldsaccountid</username>
    <password>yourapikey</password>
    <id>mvn-lds</id>
    </server>
</servers>
<mirrors>
    <mirror>
    <id>mvn-lds</id>
    <name>Mirror to Artifactory</name>
    <url>https://docker-shared-prod.icsdocker.churchofjesuschrist.org/artifactory/mvn-lds</url>
    <mirrorOf>*</mirrorOf>
    </mirror>
</mirrors>
</settings>
```

Navigate to https://icsdocker.churchofjesuschrist.org/artifactory/ and click on login. Once logged in, click your name in the upper right corner type in your password and get an API Key. in the `settings.xml` file, replace `ldsaccountid` with your church username and `yourapikey` with the APIkey.

Once the settings.xml file is created, make sure that you are on the `mormonorg-release` branch. This branch is the most up to date branch with all of code you need to set up your cms locally. Once you are on the `mormonorg-release` branch, open a new terminal in your `cms` repository and run the following commands in order:

```bash
mvn xar:install-dependencies
mvn clean package
```

Now navigate to http://localhost:8003 and login with

> username: admin
>
> password: admin

Click where it says "File - Browse for XAR file or ML script to upload" and find the directory where you have your root CMS folder.

_<root CMS folder>/target/cms-XXXX-SNAPSHOT.xar_

Upload the XAR file and click **DEPLOY**

The CMS requires an HTTP header to be included in every request when authenticated through Web Access Management (WAM). For your convenience you should add a browser extension that will modify your headers upon every request, such as ModHeader.

| Key              | Value             |
| ---------------- | ----------------- |
| policy-cn        | ldsaccountid      |
| X-Forwarded-Host | localhost-preview |

You should be able to navigate to the CMS now: http://localhost:10090/cms
You will be creating a new user later in the `Create Personal Test Area`

## Configuring your local CMS

### **Copying Dev data to Local**

To get your local CMS fully running, you can copy the web pages, components, and string bundles that already exist in the dev cms so that you don't have to do it manually in your local cms. Because ComeUntoChrist.org is a global website most of the commonly used strings on the site are stored in a server so that they can be delivered to the appropriate websites in their correct language. We refer to these as string bundles.

Before you can access the dev server you must be connected to **External** or **Internal** Admin VPN access even when you are using the church network. You can change this in your `Cisco AnyConnect Secure Mobility Client`

### **Migrate Data from Dev Lane to Your Machine**

To migrate existing web pages, components, string bundles from our Dev Server to your local machine, you need to use a WebDAV. On MacOS, you can use your finder, click on `Go`, and then `Connect to Server`. If you are not using Mac, you can download an application called Oxygen. These instructions are written for someone using Oxygen, but any webDAV will work.

1. In order to properly copy all of the web page and component data from the Dev Server to your local machine, download this application: https://www.oxygenxml.com/xml_editor/download_oxygenxml_editor.html
2. Once you've selected the correct download for your operating system it will begin downloading. While it is downloading you need to create a free temporary account. This will be on the page it directed you to. Enter your name and country (the other fields are optional). This will then send you an email with your 30-day evaluation key.
3. Open Oxygen XML editor and navigate to the **Database Perspective** page (there's a list of buttons in the top-right, Database Perspective is the rightmost button in this list)

<img src="READMEImages/screen-shot-database-perspective.png" width="50%">

4. In the **Data Source Explorer** (located on the left side) press the "Configure Database Sources..." button (small gear).

<img src="READMEImages/screen-shot-configure-database-sources.png" width="50%">

5. Click the plus button below the **Connections** table. We will need to add two connections here.
    1. First connection
        - Name: `dev-cms`
        - Data Source: `WebDAV (S)FTP`
        - WebDAV/FTP URL: `http://l21441:10095`
        - User: `deployment`
        - Password: `deployment`
    2. Second connection
        - Name: `local-cms`
        - Data Source: `WebDAV (S)FTP`
        - WebDAV/FTP URL: `http://localhost:10095`
        - User: `admin`
        - Password: `admin`
6. Once you've established those connections, click OK and navigate to the **Data Source Explorer** again and open up dev-cms.
7. Navigate to `dev-cms > preview > cms > content ` and copy the **english** folder.
8. Now, navigate through the other connection to `local-cms > preview > cms > content` and paste the `english` folder that you copied earlier into this `content` folder. (The copying will take awhile)
9. Your local CMS should now be fully functional and have a copy of all of the components and English pages that currently exist in the Dev cms. You can close out of Oxygen XML editor.

## Create Personal Test Area

### **Create Personal Test User**

Assuming that your local CMS is set up, navigate to http://localhost:10090/

1. Press the green **Add User** button at the top.
2. Add a `username` (use your church username), a `name`, and add a `role` - set to **super**.
3. Press Save at the top

### **Create Personal Test Site**

Publisher needs a test site to store test pages.

1. In the top-left corner, click on the menu icon and then select **Content Admin.**
2. On the left-side navigation click **Sites**.
3. Click the green plus (+) button next to **Site**. (if this doesn't work, ensure your [string bundles are set up correctly](#Configuring-your-local-CMS))
4. Fill in the following fields:

    | Field             | Value                                                |
    | ----------------- | ---------------------------------------------------- |
    | Site Name         | churchofjesuschrist                                  |
    | Site Display Name | ComeUntoChrist                                       |
    | Preview Host      | comeuntochrist-preview-local.churchofjesuschrist.org |
    | Published Host    | local.churchofjesuschrist.org                        |
    | Site Context      | /comeuntochrist                                      |
    | Templates         | Comeuntochrist.Org Universal Template                |

5. Click **Save.**
6. You will now be on a page that says **Add Supported Language**. Click **Add Language** at the bottom right and choose "English" for simplicity.
7. Click **Save.**

### **Create a Test Page**

1. You will need to create a web page in your local cms to test and create components.
2. In the top-left corner, click on the menu icon and then select **Content Admin**.
3. Click on "Comeuntochrist.Org Universal Template" located on the left side of the page.
4. Click on the green plus (+) button next to "Comeuntochrist.Org Universal Template."
5. Add a page with the following information:

    | Field    | Value     |
    | -------- | --------- |
    | Title    | Test Page |
    | URI      | test-page |
    | OG Title | Test Page |

6. Click **Save**
7. Start your local server by going to the root of `hannah` then open your terminal and type the command `npm run dev`. It can take a few minutes to start.
8. Navigate to https://local.churchofjesuschrist.org/comeuntochrist/test-page.

# Setup

## Configure

-   Open the preview app server: <http://localhost:8001>
-   Find the App Servers list (top center panel of main page)
-   Click on the CMS preview app (\_app_cms_preview_10090)
    -   Change "root" to local system path: `{CMS Home Dir}/src/main/xquery`
    -   Change "modules" to `(file system)`
    -   Click the OK button to save changes
-   Navigate to Configure > Security > Roles in the preview app server window
-   Click on the `_app_cms_auth` role
    -   Check the "admin" check box in the role list
    -   Click the OK button to save changes
-   Add content contributor file (via webdav)
-   Update cms_auth user with server_field role

## Open project

    Navigate to http://localhost:[PORT for preview] for dashboard
    http://localhost:10090/cms/content-admin?lang=eng (example content admin location)

# Docker Setup if desired

1. Make sure your box is configured to work with the [internal ICS docker repository][1]
1. Run `docker-compose-up.sh` - this creates an individual specific `docker-compose.yml` and then runs `docker-compose up`
1. Run `npm install` in the root directory to install required dependencies for Grunt - use latest version of 4.x or later.
1. Run `grunt`. This will start a watch on the code folder and automatically sync code to the modules database so no copying is necessary.
1. Navigate to preview or content admin locations as specified in steps above.
1. Modify code and code will auto-sync to the correct location in the Modules database on the local docker instance. No modifications to the app server are necessary.
1. Navigate to `docker:10090/shared/xray` to test the services (not presently working).

[1]: https://ip.ldschurch.org/library/297/document/using-the-internal-docker-repository
