xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";


declare boundary-space preserve;
declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

let $host as xs:string := $util:host

(: contains whole locale :)
let $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"))
let $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""))

let $locale as xs:string := if ($country ne '') then (fn:concat($lang,'-',$country)) else ($lang)
                  
let $page as xs:string := util:escape-chars(xdmp:get-request-field("page", ""))

let $sharedPrefix as xs:string? := $settings:shared-prefix

let $customPage as element(custom-page) := ice:get-custom-page($page, $locale)

let $custom-nav as xs:string := if ($customPage/@custom-nav ne '') then ($customPage/@custom-nav) else ('false')
let $theme as xs:string := if ($customPage/@theme ne '') then ($customPage/@theme) else ('auto')
let $width as xs:string := if ($customPage/@width ne '') then ($customPage/@width) else ('narrow')
let $translate as xs:string := if ($customPage/@translate ne '') then ($customPage/@translate) else ('true')

let $themes as element(theme)*  := core:get-siteProperties()/themes/theme

let $selectedThemeColor as xs:string? := $themes[. eq $theme]/@color
let $selectStyle as xs:string? := if ( fn:exists($selectedThemeColor) ) then ( fn:concat('background-color: ', $selectedThemeColor ,';') ) else ()
return
if (ac:has-permission("ldse:view-page-settings", $locale, $page) and $page ne '' and $locale ne '') then (
    xdmp:set-response-content-type( "text/html" ),
    <div id="ice-dialog" class="padding-sm" style="height:auto; overflow-y:auto;">
        <form method="post" class="ldse-form" action="{$sharedPrefix}/ice/resources/ajax/customPage/pageSettings{util:split-locale-param($locale)}">
            <input type="hidden" name="page" value="{$page}"/>
            <fieldset class="" style="width:100%;">
                <dl>
                    <dt>
                        <label for="themeSelect">Theme:</label>
                    </dt>
                    <dd>
                        <select id="themeSelect" name="theme" style="{$selectStyle}">
                            <option value="auto" style="background-color: white;">auto</option>{
                            for $t as element(theme) in $themes
                            let $value as xs:string := $t                            
                            let $style as xs:string := fn:concat('background-color: ', $t/@color ,';')
                            return (
                                element option {
                                    attribute value { $value },
                                    attribute style { $style },
                                    if ($t eq $theme) then (
                                        attribute selected {"selected"}
                                    ) else (),
                                    $value
                                }
                            )
                        }</select>
                    </dd>
                </dl>
                <dl>
                    <dt>
                       <label for="widthSelect">Width:</label>
                    </dt>
                    <dl>
                        <select name="width" id="widthSelect">{    
                            if ($width eq 'narrow') then (
                                <option value="narrow" selected="selected">Narrow</option>,
                                <option value="wide">Wide</option>
                            ) else (
                                <option value="narrow">Narrow</option>,
                                <option value="wide" selected="yes">Wide</option>
                            )
                        }</select>
                    </dl>
                </dl>
                <dl>
                    <dt>
                        <label for="customSelect">Navigation:</label>
                    </dt>
                    <dd>
                        <select name="custom-nav" id="customSelect">{
                            if ($custom-nav eq 'true') then (
                                <option value="true" selected="selected">Custom Navigation</option>,
                                <option value="false">Normal</option>
                            ) else (
                                <option value="true">Custom Navigation</option>,
                                <option value="false" selected="yes">Normal</option>
                            )
                        }</select>
                    </dd>
                </dl>
                <dl>
                    <dt>
                        <label for="translateSelect">Translation:</label>
                    </dt>
                    <dd>
                        <select name="translate" id="translateSelect">{
                            if ($translate eq 'true') then (
                                <option value="true" selected="selected">True</option>,
                                <option value="false">False</option>
                            ) else (
                                <option value="true">True</option>,
                                <option value="false" selected="yes">False</option>
                            )
                        }</select>
                    </dd>
                </dl>
                <dl>
                    <dt>
                        <label for=""></label>
                    </dt>
                    <dd>
                        <input type="submit" class="ldse-button ldse-primary float-right" style="max-width: 100%;" value="Save"/>
                    </dd>
                </dl>
            </fieldset>        
        </form>
        <script type="text/javascript"> ICE.setupForm(); </script>
    </div>
 ) else (
        let $errorMsg as xs:string:="Sorry, You don't have permission" 
        let $errorTitle as xs:string:= "Access Denied!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
