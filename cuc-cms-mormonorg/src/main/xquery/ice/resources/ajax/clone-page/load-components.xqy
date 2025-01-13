xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "/content-admin/modules/functions.xqy";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare boundary-space preserve;
declare option xdmp:mapping "true";
declare option xdmp:update "true";

let $json-map as map:map :=
    let $request-body as xs:string? := xdmp:get-request-body("text")
    return (
        if( $request-body[fn:not(. = "")] ) then (
            xdmp:from-json($request-body)
        ) else ( map:map() )
    )
let $site as xs:string := xdmp:get-request-field('site')
let $lang as xs:string := xdmp:get-request-field('lang')
let $uri as xs:string := xdmp:get-request-field('uri')
let $text as xs:string? := (map:get($json-map, "search"), xdmp:get-request-field('search'))[1]
let $currentUser as xs:string := ac:getUserName()
let $hasPermission :=  ac:has-permission('ldse:edit-doc', $lang, $uri, $site)


return
    if ($hasPermission) then
        let $components :=
            for $component in cts:search(/custom-page,
                    cts:and-query((
                        cts:directory-query('/preview/', 'infinity'),
                        cts:element-attribute-value-query(xs:QName('ldse:document'),xs:QName('uri'), $uri, 'exact'),
                        cts:element-attribute-value-query(xs:QName('ldse:document'),xs:QName('locale'), $lang, 'exact'),
                        cts:element-value-query(xs:QName('ldse:site-context'),$site, 'exact')
                    ))
                )/content/*
            let $content :=
                cts:search(fn:collection(),
                    cts:and-query((
                        cts:directory-query('/preview/', 'infinity'),
                        cts:element-attribute-value-query(xs:QName('ldse:document'),xs:QName('id'), $component/fn:string(), 'exact'),
                        cts:element-attribute-value-query(xs:QName('ldse:document'),xs:QName('locale'), $lang, 'exact'),
                        cts:element-value-query(xs:QName('ldse:site-context'),$site, 'exact')
                    ))
                )/node()
            let $map := map:map()
            let $element :=  element data {attribute id {$content/@id}, attribute uri {$uri}, $content/fn:base-uri()}
            let $childComponents := af:findNestedComponents($element, $lang, $map)
            let $childComponentCount := fn:count(map:keys($map))
            let $href := $settings:shared-prefix||'/form?lang='||$content/@locale||'&amp;site='||$site||'&amp;id='||$content/@id
            return element content {
                attribute type {fn:name($content)},
                attribute id {$content/@id},
                attribute title {$content/ldse:ldse-meta/ldse:document/@title/fn:string()},
                attribute href {$href},
                attribute childComponentCount {$childComponentCount}

            }

        let $content-json :=
            for $component as element() in ($components)
            return
                json:obj((
                    json:escapedKeyValue("type", (($component/@type), "")[1]),
                    json:escapedKeyValue("id", ($component/@id, "")[1]),
                    json:escapedKeyValue("title", ($component/@title, "")[1]),
                    json:escapedKeyValue("href", ($component/@href, "")[1]),
                    json:escapedKeyValue("childComponentCount", ($component/@childComponentCount, "")[1])
                ))

        return (
            xdmp:set-response-content-type('application/json'),
            json:arr(
                $content-json
            )
        )
    else 'Access denied'
