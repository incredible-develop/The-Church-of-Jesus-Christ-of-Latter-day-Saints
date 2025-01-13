xquery version "1.0-ml";

import module namespace r = "http://lds.org/code/shared/lds-edit/fast-i18n" at "/rice/modules/fast-i18n.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "/modules/template.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "/content-admin/modules/functions.xqy";
import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "/content-admin/modules/content-functions.xqy";
import module namespace c = "http://lds.org/code/shared/common/common-functions" at "/shared/common/commonFunctions.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $adminTemplate as xs:string* := fn:tokenize($template, "\s*,\s*");
declare variable $urlTemplateId as xs:string := xdmp:get-request-field('id', '');
declare variable $adminPage as element(page)? := af:getAdminPage($urlTemplateId);
declare variable $selectedTemplateId as xs:string? := ($urlTemplateId[. != ''], $adminPage/@id)[1];
declare variable $template as xs:string? := $adminPage/@template/xs:string(.);
declare variable $uri as xs:string? := util:escapeChars(xdmp:get-request-field('uri'))[. ne ""];
declare variable $custom-page as element(custom-page)? := cf:get-custom-page-by-uri($uri, $site);
declare variable $page as xs:string := '/content-admin';
declare variable $start as xs:int? := xs:int(util:escapeChars(xdmp:get-request-field("start", '1'))[. ne ""]);
declare variable $end as xs:int? := xs:int(util:escapeChars(xdmp:get-request-field("end", '25'))[. ne ""]);
declare variable $configMatch as xs:string? := $adminPage/@site;
declare variable $lang as xs:string := ( c:escapeChars(xdmp:get-request-field("lang")[1])[. != ""], "eng" )[1];
declare variable $pageUri as xs:string := ( $uri, $settings:shared-prefix || "/content" )[1];
declare variable $onlyOne as xs:string* := fn:tokenize($adminPage/@only-one, "\s*,\s*");
declare variable $contentHeader as xs:string := ( $adminPage, "" )[1];
declare variable $pubType as xs:string? := $adminPage/(@pub-type|@pubType)[. != ''];
declare variable $formVars as xs:string* := fn:concat("site-context:", $af:site, ",", "pub-type:", $pubType, ',', 'pageId:', $selectedTemplateId);
declare variable $formNames as xs:string* := fn:tokenize($adminPage/@formName, "\s*,\s*");
declare variable $templateElement as element(template)? := cf:getPageTemplates($template)[1];
declare variable $customPage as element(custom-page)* := ( for $t as xs:string in $adminTemplate return af:getCustomPages($t, $selectedTemplateId, $af:site, $uri), cf:get-content-by-id($content-id, ( 'preview', 'unpublish' )));
declare variable $site as xs:string? := ( xdmp:get-request-field('site')[. != ''], $af:site )[1];
declare variable $content as element()* := ( cf:get-content-by-uri($uri, $formNames), cf:get-content-by-id($content-id, ( 'preview', 'unpublish' )) );
declare variable $content-id as xs:string? := xdmp:get-request-field('contentId');

for $riceKey in $templateElement/resources/entry/@key
return
    r:get-page-string-ice-hidden($af:lang, $customPage, $riceKey) [fn:false()],

let $login := okta:okta-login()
return (
    if ( ac:has-permission("ldse:view-lds-edit-home", "", "", $site) ) then (
        xdmp:set-response-content-type("text/html"),
        '<!DOCTYPE html>',
        <html>
            <head>
                <meta charset="utf-8" />
                <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
                <meta name="viewport" content="width=device-width" />
                <link rel="stylesheet" type="text/css" media="screen" href="{$settings:shared-prefix}/resources/css/ldspublisher-ice.css" />
                <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/resources/css/ldspublisher.css" />
                <link rel="stylesheet" type="text/css" media="screen" href="{$settings:shared-prefix}/ice/resources/styles/incontext.css"/>

                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/screen.css" />
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/nodes.css" />
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/isotope.css" />
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/dashboard.css"/>
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/smoothness/jquery-ui-1.10.3.custom.min.css"/>
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/shadows.css"/>
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/dashboard.responsive.css"/>
                <style>
                    <![CDATA[
                    #nodes h1, #nodes h2 { margin-left: 17px; }
                ]]>
                </style>
            </head>
            <body>
	           <section class="ldse-section ldse-modal" style="display:none;" id="modal1"><div></div></section>
                <section class="ldse-page">
                    { af:buildAdminPageLinks() }
                    <div id="page">
                        <section id="nodes">{
                            if ( $selectedTemplateId = 'site-creation' ) then (
                                let $sites as element(sub-site)* := cf:get-sub-sites()
                                return (
                                    <h1>Sites</h1>,
                                    af:buildContentAdminPage($lang, $pageUri, $af:site, $adminPage, 'Site', 'sub-site', 'site-creator', $selectedTemplateId, $formVars, fn:false(), (), (), $sites)
                                )
                            ) else if ( $adminPage/@template = 'false' or fn:exists($adminPage/@formName) ) then (
                                if ( fn:exists($content) ) then (
                                    <h1>{$contentHeader}</h1>,
                                    af:render-template($uri, $content)
                                ) else (
                                    <h1>{$contentHeader}</h1>,
                                    for $formName as xs:string at $i in $formNames
                                    let $onlyOne as xs:boolean := $onlyOne[$i] eq 'true'
                                    let $contentItem as xs:string := cf:getFormTitle($formName)
                                    return (
                                        af:buildContentAdminPage($lang, $pageUri, $af:site, $adminPage, if ( $onlyOne ) then ($contentItem) else ($contentHeader), $contentItem, $formName, $selectedTemplateId, $formVars, $onlyOne, $pubType, $template)
                                    )
                                )
                            ) else if ( ( fn:exists($uri) and fn:exists($custom-page) ) or ( fn:exists($custom-page) and $onlyOne ) ) then (
                                <h1>{$custom-page/title/fn:string(.)}</h1>,
                                af:render-template(($uri, $custom-page/@uri)[1], $custom-page)
                            ) else (
                                let $onlyOne as xs:boolean := ($adminPage/@only-one/xs:string(.) eq 'true')
                                return (
                                    <h1>{$contentHeader}</h1>,
                                    af:buildContentAdminPage($lang, $uri, $af:site, $adminPage, $contentHeader, 'Page Settings', 'pageBuilder', $selectedTemplateId, $formVars, $onlyOne, (), $template)
                                )
                            )
                        }</section>
                    </div>
                </section>

                <scripts>
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/1.7.2/jquery.min.js"></script>
                    {ice:get-scripts()}
                    {af:addPageEdit($page, $af:lang, (), $custom-page, fn:false())}
                    <script src="{$settings:shared-prefix}/content-admin/resources/js/jquery-multisortable-0.2.min.js"></script>
                    <script src="{$settings:shared-prefix}/content-admin/resources/js/jquery.isotope.min.js"></script>
                    <script src="{$settings:shared-prefix}/content-admin/resources/js/nodes.js"></script>
                    <script src="{$settings:shared-prefix}/content-admin/resources/js/dashboard.js"></script>
                    <script src="{$settings:shared-prefix}/content-admin/resources/js/highcharts.js"></script>
                    <script src="{$settings:cdn-path}/scripts/other/handlebars/handlebars1.0.0.beta.6.min.js ">&nbsp;</script>
                </scripts>
                <div id="ldse-modal-backdrop" class="ldse-modal-backdrop" style="display:none;"></div>
            </body>
        </html>
    ) else (
        template:error-access-denied("Error!", "Sorry, you don't have permission to view this page.")
    )
)
