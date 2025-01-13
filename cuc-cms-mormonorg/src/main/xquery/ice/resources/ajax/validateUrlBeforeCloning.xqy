xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '../../../modules/site-properties.xqy';
declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";
declare variable $permission as xs:string := "ldse:add-new-page";

let $url as xs:string? := util:escape-chars(xdmp:get-request-field("url", ""))
let $toSite as xs:string? :=  util:escape-chars(xdmp:get-request-field("toSite", ""))
let $lang as xs:string :=  util:escape-chars(xdmp:get-request-field("lang", "eng"))
let $urlPrefix as xs:string? := sp:get-site-properties($toSite)/site-context/fn:string()
let $newUrl := if ($urlPrefix ne '/' and fn:string-length($urlPrefix) > 1) then
                    if (fn:starts-with($url, $urlPrefix)) then
                        $url
                    else fn:concat($urlPrefix, $url)
               else $url
return (
    if ( fn:exists($newUrl) and fn:not($newUrl = '') ) then (
        let $path as xs:string :=
            if (fn:exists($settings:shared-prefix) and fn:starts-with($newUrl, $settings:shared-prefix)) then (
                fn:substring-after($newUrl, $settings:shared-prefix)
            ) else ($newUrl)
        let $path2 as xs:string := fn:concat($path, '/')

        (: Check to see if any custom pages exist with the specified path - if one exists we can't use the path :)
        let $isValidCustomPage as xs:boolean :=
            fn:empty(
                cts:search(/custom-page,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('uri'), ($path, $path2), 'exact'),
                    cts:element-attribute-value-query(xs:QName("custom-page"), xs:QName("locale"), $lang, "exact"),
                    cts:element-value-query(xs:QName("ldse:site-context"), $toSite, "exact")
                    ))
                )
            )
        return (
            xdmp:set-response-content-type("text/plain"),
            if ($isValidCustomPage )then ("true", $util:host) else ("false",$util:host)
        )
    )
    else ( 'false', $util:host )
    )



