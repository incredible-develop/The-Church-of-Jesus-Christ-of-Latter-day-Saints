xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "../../../../content-admin/modules/content-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare boundary-space preserve;
declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

let $host as xs:string := $util:host

let $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"))
let $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""))
let $locale as xs:string := if (fn:not($country = '')) then (fn:concat($lang, '-', $country)) else ($lang)

let $currentPage as xs:string := util:escape-chars(xdmp:get-request-field("currentPage", ""))
let $action as xs:string := util:escape-chars(xdmp:get-request-field("action", "clone"))
let $currentID as xs:string := util:escape-chars(xdmp:get-request-field("currentID", ""))
let $recurse as xs:string := util:escape-chars(xdmp:get-request-field("recurse", ""))

let $sharedPrefix as xs:string? := $settings:shared-prefix
let $pageTemplate := cf:get-custom-page-by-id-and-lang($currentID, $lang)/ldse:ldse-meta/ldse:form-options/ldse:templateId/fn:string()
let $convertToUniversalTemplate := if ($pageTemplate eq 'mo-universal-template') then
                                        fn:false()
                                    else cf:getTemplateById($pageTemplate)/@convert-to-universal-template/fn:string() eq 'true'
return
if (ac:has-permission("ldse:clone-page", $locale, $currentPage)) then (
    xdmp:set-response-content-type( "text/html" ),
    <div id="ice-dialog2" class="padding-sm">
        <script type="text/javascript" src="{$sharedPrefix}/ice/resources/script/clonePage.js">&nbsp;</script>
        <style type="text/css">
            #clonePageForm .primary
            {{
                float: none;
                width: auto;
            }}
            #newUri
            {{
                background-color: #ffffff;
                border: #999999 solid 1px;
                padding: 3px;
                border-radius: 5px;
            }}
            .select.success
            {{
                border: solid 2px #669900 !important;
            }}
            #newUriSuccess
            {{
                border: solid 2px #669900 !important;
                background: #EEFFCC;
                color: #669900;
                display: block;
                font-size: 12px;
                margin-top: 10px;
                margin-bottom: 15px;
                padding: 15px 20px;
            }}
            .error
            {{
                border: solid 1px #C23232 !important;
                text-align: left;
                display: none;
                margin-top: 0;
            }}
            span.error
            {{
                display: block;
            }}
            #langSelects
            {{
                margin: 0;
                        max-height: 290px;
                        min-height: 48px;
                        overflow: auto;
                        padding-top: 5px;
                        padding-bottom: 15px;
            }}

            #langSelects span.select
            {{
                margin-bottom: 10px;
            }}

            #langSelects .uriError
            {{
                margin-top: -10px;
                margin-bottom: 10px;
            }}

            #langSelects button.ldse-icon-x
            {{
                float: right;
                margin-top: -10px;
                color: #58585D;
                font-size: 16px;
            }}

            .ldse-icon
            {{
                padding-left: 15px;
            }}

            .panel-wait
            {{
                    background: -moz-linear-gradient(center top , #40403F, #161616) repeat scroll 0 0 transparent;
                    background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(64,64,63,1)), color-stop(100%,rgba(22,22,22,1)));
                    border: 1px solid #161616;
                    border-radius: 6px 6px 6px 6px;
                    display: none;
                    height: 60px;
                    left: 50%;
                    margin-left: -110px;
                    margin-top: -30px;
                    position: fixed;
                    text-align: center;
                    top: 50%;
                    width: 220px;
                    z-index: 20000;
                }}

                .panel-wait span
                {{
                        background: url("/resources/images/loading_huge.gif") no-repeat scroll 0 0 transparent;
                        display: inline-block;
                        height: 15px;
                        text-align: center;
                        width: 200px;
                    }}

                    .panel-wait p
                    {{
                        color: #BBBBBB;
                        font-size: 14px;
                        line-height: 1;
                        margin: 10px 0;
                        text-align: center;
                        text-shadow: 0 -1px 1px black;
                    }}
        </style>
        <form class="ldse-section--body ldse-form" method="post" id="clonePageForm" action="{$sharedPrefix}/ice/resources/ajax/clone-page/clonePage{util:split-locale-param($locale)}">
            <input type="hidden" id="currentPage" name="currentPage" value="{$currentPage}"/>
            <input type="hidden" id="currentID" name="currentID" value="{$currentID}"/>
            <input type="hidden" id="recurse" name="recurse" value="{$recurse}"/>
            <input type="hidden" id="action" name="action" value="{$action}"/>
            <section>
                <dl>
                    <dt><label for="newUri">New Uri</label></dt>
                    <dd><input type="text" name="newUri" id="newUri" value="{$currentPage}" size="50" onchange="CP.hideErrors();" oninput="CP.validateUri()"/></dd>
                 </dl>
                  <dl>
                     <dd>
                        <span id="newUriError" class="error" style="color:#990000; display:none;"></span>
                     </dd>
                     <dd>
                        <span id="newUriSuccess" class="success" style="color:#669900; display:none;"></span>
                     </dd>
                   </dl>

                    <dl>
                        <dt><label for="langDropDown">New Site and Languages</label></dt>
                    </dl>
                    <dl id="langSelects">
                        <dd class="langSelect">
                            <div class="clearfix">
                            <select class="langDropDown">
                            {
                                <option value="Please Select a Language...">Please Select a Site and Language...</option>,
                                for $site-lang as xs:string in fn:distinct-values(ac:site-locales-by-permission("ldse:clone-page", $currentID))
                                order by $site-lang
                                return
                                    <option value="{$site-lang}">{(
                                        if($locale = $site-lang)
                                        then attribute selected {"selected"}
                                        else (),
                                        $site-lang
                                    )}
                                    </option>

                            }
                            </select>
                          </div>
                       </dd>
                   </dl>

                { if ($convertToUniversalTemplate) then (

                    <dl>
                        <dt><label for="langDropDown">Change page to use the Universal Template</label></dt>
                    </dl>,
                    <dl>
                        <dd>
                            <div class="clearfix">
                                <select id="changeToUniversalTemplate">
                                    {
                                        <option value="no">No</option>,
                                        <option value="yes">Yes</option>
                                    }
                                </select>
                            </div>
                        </dd>
                    </dl>
                )
                else ()}

                   <dl>
                   </dl>
                   <dl>
                       <dd>
                            <button class="ldse-button ldse-primary ldse-icon-copy float-right" onclick="CP.verifyUrls(); return false;" id="validate">Clone</button>
                        </dd>
                    </dl>
            </section>
        </form>
        <div class="panel-wait" id="md-wait"><p>Need Text</p><span></span></div>
    </div>
 ) else (xdmp:redirect-response("/error.xqy"))
