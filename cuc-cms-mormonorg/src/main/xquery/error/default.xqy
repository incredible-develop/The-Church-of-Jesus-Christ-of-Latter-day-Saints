xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "../modules/template.xqy";

declare option xdmp:mapping "true";

declare variable $title as xs:string := 'Error Page';

declare variable $pageUri as xs:string := fn:concat($settings:shared-prefix,"/error");
declare variable $errorTitle as xs:string := xdmp:get-request-field("errorTitle","Error!");
declare variable $errorMsg as xs:string := xdmp:get-request-field("errorMsg","An error occured.");
declare variable $extraContent as item()* := xdmp:get-request-field("extraContent","");
declare variable $refer-link as item()* := xdmp:get-request-field("referLink","/");

xdmp:set-response-content-type( "text/html" ),
'<!DOCTYPE html >',
    core:template-apply(
        $title,
        $pageUri,
        <page>
            <head>
                <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/error/styles/error.css" />
            </head>
            
            <scripts>
                <script type="text/javascript" src="{$settings:cdn-path}/lds-edit/scripts/jquery.form.js">&nbsp;</script>
                <script>$(".active").removeClass("active")</script>
            </scripts>
            
            <content>
                <div>
                   <h2 class='red'>{$errorTitle}</h2>
                   <h4 class='red' id='msg'>{$errorMsg}</h4>
                   {
                        if (fn:exists($refer-link)) then (
                             <h4 class='red' id='extra'>Click <a href="{fn:concat($settings:shared-prefix, $refer-link)}">here</a> to return to front-end</h4>
                        ) else ()
                   }
               </div>
            </content>
        </page>
    )
