xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";
import module namespace func = "http://lds.org/code/shared/lds-edit/function-apply" at "../../../../invoke/function-apply.xqy";
import module namespace clone = "http://lds.org/code/shared/lds-edit/clone-functions" at "cloneFunctions.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at "../../../../modules/site-properties.xqy";

declare boundary-space preserve;
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

let $host as xs:string := $util:host

let $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"))
let $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""))
let $site as xs:string? := util:escape-chars(xdmp:get-request-field("site", ""))
let $locale as xs:string := if ($country ne '') then (fn:concat($lang, '-', $country)) else ($lang)
let $langDropDown as xs:string? := xdmp:get-request-field("langDropDown")
let $to-site := if (fn:contains($langDropDown, ' | ' )) then
                    fn:substring-before($langDropDown, ' | ')
                else $site
let $newLocale := if (fn:contains($langDropDown, ' | ' )) then
                    fn:substring-after($langDropDown, ' | ')
                else $langDropDown
let $new-site-prefix := sp:get-site-properties($to-site)/site-context/fn:string()
let $currentUri as xs:string := util:escape-chars(xdmp:get-request-field("currentPage", ""))
let $_newUri as xs:string := fn:lower-case(util:escape-chars(xdmp:get-request-field("newUri", "")))
let $newUri as xs:string := if (fn:string-length($new-site-prefix) > 1) then
                                if (fn:starts-with($_newUri, $new-site-prefix)) then
                                    $_newUri
                                else fn:concat($new-site-prefix, $_newUri)
                            else $_newUri
let $action as xs:string := util:escape-chars(xdmp:get-request-field("action", "clone"))
let $recurse as xs:string := util:escape-chars(xdmp:get-request-field("recurse", "false"))
let $recurse as xs:boolean := $recurse eq 'true'
let $currentID as xs:string := util:escape-chars(xdmp:get-request-field("currentID", ""))

let $post-function as xdmp:function? :=
    let $post-clone-process as element(ldse:post-clone-process)? := $settings:post-clone-process
    where fn:exists($post-clone-process)
    return (
        xdmp:function(fn:QName($post-clone-process/@namespace, $post-clone-process/@name), $post-clone-process/@path)
    )

let $updToUniversalTemplate as xs:string? := util:escape-chars(xdmp:get-request-field("updToUniversalTemplate", "no"))
return (
    if (ac:has-permission("ldse:clone-page", $locale, $currentUri)) then (
        let $copyFiles as item()* := clone:copyFilesByUri($locale, $site, $newLocale, $to-site, $currentUri, $newUri, $recurse, $currentID, $new-site-prefix, $updToUniversalTemplate)
        let $copyRewrite as item()* := clone:copyRewriteRule($locale, $newLocale, $currentUri, $newUri, $site, $to-site)
        let $apply-post-finction as item()* :=
            if (fn:exists($post-function)) then (
                func:apply($post-function, $core:mode, $core:mode, $action, $currentUri, $newUri, $locale, $newLocale)
            ) else ()

        return (
            (:Return the Redirect URL in case of this new clone feature:)
            if($settings:clone)
            then(fn:concat('//', $settings:app-domain, $newUri, '?lang=', $newLocale))
            else()
            (:xdmp:redirect-response( core:build-url($newUri, $newLocale, ()) ):)
        )
    ) else (
        let $errorMsg as xs:string:="Sorry, You don't have permission"
        let $errorTitle as xs:string:= "Access Denied!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )

)
