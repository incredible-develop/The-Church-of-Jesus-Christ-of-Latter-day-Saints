xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace ldseUtil = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace ldsesUser="http://lds.org/code/lds-edit-services/user" at "/modules/userManagement.xqy";
import module namespace email = "http://lds.org/code/shared/lds-edit/email" at "/setup/modules/emailFunction.xqy";
import module namespace valid = "http://lds.org/code/shared/lds-edit/isValidFunctions" at "/ice/modules/isValidFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace ldses = "http://lds.org/code/lds-edit-services";
declare option xdmp:mapping "true";
declare variable $usernameToReset as xs:string? := xdmp:get-request-field("username");
declare variable $passwordToReset as xs:string? := xdmp:get-request-field("password");
declare variable $serviceSite as xs:string? := xdmp:get-request-field("site");
declare variable $context as xs:string := ldseUtil:getContext();
declare variable $cdnPath as xs:string := fn:string(cts:search(/ldse:ldse-settings/ldse:cdn-path,
    cts:directory-query(fn:concat($context, "lds-edit-services/content/_configuration/"),"1")));
declare variable $ixfVersion as xs:string := "1.1";
let $completePostBack as xs:boolean := exists($usernameToReset) and exists($passwordToReset) and exists($serviceSite)
let $resetPassword as empty-sequence() := if($completePostBack) then (
        let $siteReg as element()* := ldsesUser:getSite($serviceSite)
        let $creator as xs:string := $siteReg/ldses:creator/@ldsid
        let $isCreator as xs:boolean := ac:getUserName() = $creator
        let $validUserNameForSite as xs:boolean := fn:exists($siteReg/ldses:user[@username=$usernameToReset])
        return
            if($isCreator and $validUserNameForSite) then (
                let $subject as xs:string := "Password Reset Notification - LDS Edit Services"
                let $content as xs:string := fn:concat("This message is to let you know that the password for ",
                   $usernameToReset, " was reset on LDS Edit Services by ", ac:getPersonName() , " (",
                   ac:getPersonEmail(),"). If this request was made by you or someone you know then please disregard this message.<br/><br/>Sincerely,<br/>LDS Edit Services Team")
                let $fromName as xs:string := "LDS Edit"
                let $fromAddress as xs:string := "noreply@ldschurch.org"
                let $toName as xs:string := ($siteReg/ldses:contact/@name)[1]
                let $toAddress as xs:string := ($siteReg/ldses:contact/@email)[1]
                return (email:sendMail($subject, $content, "text/html", $fromName, $fromAddress, $toName, $toAddress),
                    ldsesUser:resetUserPassword($usernameToReset, $passwordToReset))
            ) else ()
    ) else ()
return
    xdmp:set-response-content-type("text/html"),
    <html>
        <head>
            <meta http-equiv="content-type" content="text/html; charset=utf-8" />
            <title>Setup - LDS-Edit-Services</title>
             <!--[if IE 7]><link rel="stylesheet" type="text/css" media="screen" href="{$cdnPath}/ixf/{$ixfVersion}/styles/screen-ie.css" /><![endif]-->

            <link rel="stylesheet" type="text/css" media="all" href="{$cdnPath}/ixf/{$ixfVersion}/styles/screen.css"/>
            <style type="text/css">label.error {{color: red;}}</style>
            <script type="text/javascript" src="{$cdnPath}/scripts/jquery/1.7.1/jquery.min.js">&nbsp;</script>
            <script type="text/javascript" src="{$cdnPath}/scripts/ui/1.8.13/jquery-ui.min.js">&nbsp;</script>
            <script type="text/javascript" src="{$cdnPath}/ixf/{$ixfVersion}/scripts/ixf-plugins.min.js">&nbsp;</script>
            <script type="text/javascript" src="{$cdnPath}/ixf/{$ixfVersion}/scripts/ixf-utilities.min.js">&nbsp;</script>
            <script><![CDATA[
            $(function(){
            ixf.popup.show.solo = true;
            ixf.setup();
            $('.ui-layout-west .ixf-table').masterDetail({
                    cacheResults:false,
                    loadFirst:false,
                    onloaddetail:function(){
                        ixf.setup($("#detail"));
                        }
                    });
                });
                 // wait for the DOM to be loaded
            ]]> </script>
        </head>
        <body class="master-detail">
         <a href="#body" class="invisible">Skip to content</a>
            <div class="ixf-header" role="navigation">
            <div class="ixf-appname">
                <a href="#appmenu" class="ixf-appname-link ixf-popup" data-pop-direction="left" title="Menu">LDS-EDIT</a>
            </div>
            <!-- END ixf-appname -->

            <ul class="ixf-nav">
                <li class="selected"><a href="/lds-edit-site/registration"><span>Site Registration</span></a></li>
            </ul>
            <!-- END ixf-nav -->
        </div><div class="ixf-subheader" role="navigation">
                <ul class="ixf-subnav">
                    <li class="selected">
                                <a href="/lds-edit-site/registration">
                                    <span>Site Registration</span>
                                </a>
                            </li>
                  </ul>
                <!-- END ixf-subnav -->
            </div>
               <div class="ixf-panels">

                   <div class="ixf-panel ui-layout-west" data-layout-size="187" data-layout-minSize="150">
                    <table class="ixf-table ixf-fixed master">
                        <thead>
                        <tr>
                            <th><a href="#x">Registered Sites</a></th>
                        </tr>
                        </thead>
                        <tbody>
                        {
                            let $secUser as xs:string? := ac:getUserName()
                            let $isSuper as xs:boolean := valid:isSuper()
                            return (
                                for $site as element(ldses:site) in /ldses:site
                                let $name as xs:string := $site/@name
                                where $name ne "lds-edit-services" and
                                    (($site/ldses:creator/@ldsid eq $secUser) or $isSuper)
                                order by $name
                                return <tr id="{$name}"><td><a href="ajax/update?site={$name}">{$name}</a></td></tr>
                            )
                        }
                        </tbody>
                    </table><!-- /ixf-table -->
                </div><!-- /ixf-panel -->

                   <div class="ixf-panel ui-layout-center padding-md" id="detail">
                    </div>
                   <!-- END ixf-container -->
                <!-- /ixf-panel -->
            </div>
        </body>
    </html>
