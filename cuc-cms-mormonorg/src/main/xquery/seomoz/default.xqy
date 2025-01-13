xquery version "1.0-ml";

import module namespace seomoz = "http://lds.org/code/shared/lds-edit/seo-functions" at "modules/seoModule.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $title as xs:string := "SEO Moz Page";
declare variable $pageUri as xs:string := "/shared/lds-edit/seomoz";

declare variable $returnURL as xs:string? := xdmp:get-request-field("returnURL","");
declare variable $live-domain as xs:string? := $settings:live-domain;

let $login := okta:okta-login()
return
 xdmp:set-response-content-type( "text/html" ),
    core:template-apply(
        $title,
        $pageUri,
        <page>
            <head>
                <link rel="stylesheet" href="{$settings:shared-prefix}/shared/lds-edit/seomoz/styles/seomoz.css">&nbsp;</link>
            </head>

            <scripts>
            {
                seomoz:getTableTemplate(),
                <script type="text/javascript" src="{$settings:shared-prefix}/shared/lds-edit/seomoz/scripts/seomoz.js">&nbsp;</script>,
                if($returnURL ne "") then(
                    <script>$(function(){{$("#getSeoDataBtn").click()}});</script>
                )  else()
            }
            </scripts>

            <content>
                    <section id="summary" class="ldse-section ldse-summary cf">
                        <header class="ldse-section--header">
                            <h2>SEO Moz Data</h2>
                            <span class="subtext"></span>
                        </header>
                        <div class="ldse-section--body">
                            <form class="ldse-form ldse-search ldse-box ldse-tableize" action="" onsubmit="return(false)">
                                <span class="ldse-tableize--fill">
                                    <input type="text" placeholder="URL Field" onkeydown="checkEnter(function(){{getSeoData()}})" value="{seomoz:url-switch-domains($returnURL, $live-domain)}" id="targetURLFld" class="ldse-square-right"/>
                                </span>
                                <span>
                                    <input type="button" id="getSeoDataBtn" value="&#57351;" class="ldse-square-left" />
                                </span>
                            </form>
                            <div class="ldse-form ldse-fullbleed ldse-section--body">&nbsp;</div>
                            <div id="dataTable">&nbsp;</div>
                            <div class="ldse-table-buttons">{
                                       if($returnURL ne "") then(
                                            <button onclick="returnToURL({xdmp:to-json-string($returnURL)})" id="doneBtn" class="ldse-button primary ldse-icon-check2" style="display: inline-block; ">Done</button>
                                        )
                                        else()
                             }&nbsp;</div>
                             <div id="displayDescription">&nbsp;</div>
                         </div>
                    </section>
            </content>
        </page>
    )
