xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../../modules/ldse-meta.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";

declare boundary-space preserve;
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";
declare option xdmp:update "true";

let $host as xs:string:= $util:host

let $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"))
let $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""))
let $locale as xs:string := if ($country ne '') then (fn:concat($lang,'-',$country)) else ($lang)
                  
let $page as xs:string := util:escape-chars(xdmp:get-request-field("page", ""))

let $customPage as element(custom-page) := ice:get-custom-page($page, $locale)

let $custom-nav as xs:string := util:escape-chars(xdmp:get-request-field("custom-nav", "false"))
let $width as xs:string := util:escape-chars(xdmp:get-request-field("width", "narrow"))
let $theme as xs:string := util:escape-chars(xdmp:get-request-field("theme", "auto"))
let $translate as xs:string := util:escape-chars(xdmp:get-request-field("translate", "true"))

let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:get-meta($customPage, (), (), (), "preview")
let $ldse-meta as element(ldse:ldse-meta) :=
    if ($translate eq "true") then (
        ldsemeta:translation-mark-ready($ldse-meta)
    ) else (
        ldsemeta:translation-remove-ready($ldse-meta)
    )
    
return (
    if (ac:has-permission("ldse:view-page-settings", $locale, $page) and fn:exists($customPage) ) then (
        let $pagePath as xs:string := if ( fn:exists($customPage) ) then (fn:substring-after(xdmp:node-uri($customPage), core:get-mode-root())) else ()
        
        let $newPage as element(custom-page) := 
            element custom-page {
                 attribute custom-nav {$custom-nav},
                 attribute theme {$theme},
                 attribute width {$width},
                 attribute status {'preview'},
                 if ($locale eq 'eng') then (
                    attribute translate {$translate}
                 ) else (),
                 $customPage/@*[fn:not(fn:node-name(.) = (xs:QName("theme"), xs:QName("width"), xs:QName("custom-nav"), xs:QName("status"), xs:QName("translate")))],
                 $ldse-meta,
                 $customPage/*[fn:not(self::ldse:ldse-meta)]
            }
        
        let $save as item()* := core:save-file(xdmp:node-uri($customPage), $newPage, ())

        return (
            xdmp:redirect-response( core:build-url($page, $locale, ()) )
        )
     ) else (
        let $errorMsg as xs:string:="Sorry, You don't have permission" 
        let $errorTitle as xs:string:= "Access Denied!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
)
