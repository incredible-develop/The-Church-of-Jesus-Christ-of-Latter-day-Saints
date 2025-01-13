xquery version "1.0-ml";

import module namespace rewrite = "http://lds.org/code/shared/common/uri-rewrite-functions" at "/shared/common/uri/uriRewriteFunctions.xqy";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";
declare variable $permission as xs:string := "ldse:add-new-page";

let $url as xs:string? := util:escape-chars(xdmp:get-request-field("url", ""))
let $country as xs:string? :=  util:escape-chars(xdmp:get-request-field("country", ""))
let $preLang as xs:string :=  util:escape-chars(xdmp:get-request-field("lang", "eng"))
let $lang as xs:string := if ($country ne '') then (fn:concat($preLang,'-',$country)) else ($preLang)
let $site as xs:string :=  util:escape-chars(xdmp:get-request-field("site", ""))
return (
    if ( fn:exists($url) and fn:not($url = '') ) then (
        let $path as xs:string :=
            if (fn:exists($settings:shared-prefix) and fn:starts-with($url, $settings:shared-prefix)) then (
                fn:substring-after($url, $settings:shared-prefix)
            ) else ($url)
        let $path2 as xs:string := fn:concat($path, '/')
        let $rule as element(rule)* :=
            cts:search(/rewriteRules,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), ($lang, "global"), 'exact'),
                    cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('site'), $site, 'exact')
                ))
            )/rule[@params = "0" and @path = ($path, $path2)]

        let $isValidRewrite as xs:boolean := fn:empty($rule)
        let $urlCheck1 as xs:string := fn:concat($url, ".xqy")
        let $urlCheck2 as xs:string := fn:concat($url, "/default.xqy")
        let $isValidProjectUrl as xs:boolean :=
            fn:not(
                if (xdmp:modules-database() eq 0) then (
                    xdmp:uri-is-file($urlCheck1) or xdmp:uri-is-file($urlCheck2)
                ) else (
                    let $root as xs:string := xdmp:modules-root()
                    let $url1 as xs:string := fn:concat($root, fn:substring($urlCheck1, 2))
                    let $url2 as xs:string := fn:concat($root, fn:substring($urlCheck2, 2))
                    return rewrite:uri-is-file($url1) or rewrite:uri-is-file($url2)
                )
            )
        (: Check to see if any custom pages exist with the specified path - if one exists we can't use the path :)
        let $isValidCustomPage as xs:boolean :=
            fn:empty(
                cts:search(
                    /custom-page,
                    cts:and-query(
                        (
                            core:get-filter-query(),
                            cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('uri'), ($path, $path2), 'exact'),
                            cts:element-attribute-value-query(xs:QName("custom-page"), xs:QName("locale"), $lang, "exact"),
                            cts:element-value-query(xs:QName("ldse:site-context"), $site, "exact")
                        )
                    )
                )
            )


        (: Check to see if any page exists with this URI, Only in the new-dynamic setting.:)
        let $isValidDynamicURI as xs:boolean :=
            if($settings:new-dynamic eq "true")
            then (
                fn:empty(
                    cts:search(
                        /ldswebml,
                        cts:and-query(
                            (
                                core:get-filter-query(),
                                cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('uri'), ($url), 'exact'),
                                cts:element-attribute-value-query(xs:QName("ldswebml"), xs:QName("locale"), $lang, "exact")
                            )
                        )
                    )
                )
            )
            else (fn:true())

        return (
            xdmp:set-response-content-type("text/plain"),
            if ($isValidRewrite and $isValidProjectUrl and $isValidCustomPage and $isValidDynamicURI and ac:has-permission($permission, $lang, $url)) then ("true", $util:host) else ("false",$util:host)
        )
    ) else ( 'false', $util:host )
)
