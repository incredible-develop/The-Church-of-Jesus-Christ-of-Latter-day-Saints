xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
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
let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
let $lang as xs:string := xdmp:get-request-field('lang')[. != ''][1]
let $text as xs:string? := (map:get($json-map, "search"), xdmp:get-request-field('search'))[1]
let $searchText as xs:string* := if ( fn:lower-case($text) = ('resources', 'custom-page', '*', "") ) then '*' else ( $text, fn:concat("*", $text), fn:concat('*', $text, '*'), fn:concat($text, "*") )
let $currentUser as xs:string := ac:getUserName()
let $can-see-templates :=
        for $template in cts:search(/sub-site, cts:element-value-query(xs:QName('name'), $site, 'exact'))/templates/template
        let $allow-access := fn:string-join($template/allow-access/username/fn:string(), ',')
        return if ($allow-access) then
            if (fn:contains($allow-access, $currentUser)) then
                $template/type/fn:string()
            else ()
        else $template/type/fn:string()
let $resources as element(resources)* :=
    if (fn:lower-case($text) eq 'custom-page') then
        ()
    else
        if (ac:has-permission('ldse:view-rice-admin', '', '', $site)) then
            cts:search(/resources,
                cts:and-query((
                    cts:directory-query('/preview/', 'infinity'),
                    cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $lang, "collation=http://marklogic.com/collation/"),
                    cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $site, 'exact'),
                    if ($searchText != "*") then (
                        cts:or-query((
                            cts:element-value-query(
                                xs:QName("name"),
                                $searchText,
                                ("wildcarded", "unstemmed", "punctuation-sensitive", "case-insensitive", "diacritic-insensitive", "whitespace-insensitive"),
                                16
                            ),
                            cts:element-value-query(
                                xs:QName("value"),
                                $searchText,
                                ("wildcarded", "unstemmed", "punctuation-insensitive", "case-insensitive", "diacritic-insensitive", "whitespace-insensitive"),
                                    -.0626
                            ),
                            cts:element-attribute-value-query(
                                xs:QName("entry"),
                                xs:QName("key"),
                                $searchText,
                                ("wildcarded", "unstemmed", "punctuation-sensitive", "case-insensitive", "diacritic-insensitive", "whitespace-insensitive"),
                                    -.0626
                            )
                        ))
                    ) else ()
                )),
            ("filtered", "score-simple")
            )
        else ()
let $custom-pages as element(custom-page)* :=
    if (fn:lower-case($text) eq 'resources') then
        ()
    else
        cts:search(/custom-page,
        cts:and-query((
            cts:directory-query('/preview/', 'infinity'),
            cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $lang, "collation=http://marklogic.com/collation/"),
            cts:not-query((
                cts:element-value-query(xs:QName('ldse:templateId'), 'mo-automation-template', 'exact')
            )),
            cts:element-value-query(xs:QName('ldse:templateId'), $can-see-templates, 'exact'),
            if ( fn:exists($site) ) then (
                    cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
            ) else (),
            if ($searchText != "*") then (
                cts:or-query((
                    cts:element-attribute-value-query(
                        xs:QName("ldse:document"),
                        xs:QName("uri"),
                        $searchText,
                        ("wildcarded", "unstemmed", "punctuation-sensitive", "case-insensitive", "diacritic-insensitive", "whitespace-insensitive"),
                        16
                    ),
                    cts:element-attribute-value-query(
                        xs:QName("ldse:document"),
                        xs:QName("title"),
                        $searchText,
                        ("wildcarded", "unstemmed", "punctuation-insensitive", "case-insensitive", "diacritic-insensitive", "whitespace-insensitive"),
                            -.0626
                    )
                ))
            ) else ()
        )),
        ("filtered", "score-simple")
         )
let $resources as element(content)* :=
        for $resource as element(resources) in $resources
        let $href := $settings:shared-prefix||'/string-manager/bundle-editor?lang=eng&amp;bundle='||$resource/@name||'&amp;locale='||$resource/@locale||'&amp;site='||$site
        order by if ($searchText = '*') then ($resource/@name) else (9999)
        return element content{attribute type {"resources"},
                               attribute id {$resource/@id},
                               attribute name {$resource/name},
                               attribute href {$href}
                              }

let $custom-pages as element(content)* :=
        for $custom-page as element(custom-page) in $custom-pages
        let $href := $settings:shared-prefix||'/content-admin?lang='||$custom-page/@locale||'&amp;site='||$site||'&amp;id='||$custom-page/ldse:ldse-meta/ldse:form-options/ldse:templateId||'&amp;uri='||$custom-page/ldse:ldse-meta/ldse:document/@uri
        let $template := $custom-page/ldse:ldse-meta/ldse:form-options/ldse:templateId/fn:string()
        let $showConvertToUniversal := if ($template eq 'mo-universal-template') then 'none' else 'inline'
        order by if ($searchText = '*') then ($custom-page/ldse:ldse-meta/ldse:document/@uri) else (9999)
        return element content{
                    attribute type {"custom-page"},
                    attribute id {$custom-page/@id},
                    attribute name {$custom-page/ldse:ldse-meta/ldse:document/@uri},
                    attribute href {$href}
        }
let $content-json :=
    for $content as element(content) in ($resources, $custom-pages)
    return
        json:obj((
            json:escapedKeyValue("type", ($content/@type, "")[1]),
            json:escapedKeyValue("name", ($content/@name, "")[1]),
            json:escapedKeyValue("id", ($content/@id, "")[1]),
            json:escapedKeyValue("href", ($content/@href, "")[1])
        ))

return (
    xdmp:set-response-content-type('application/json'),
    json:arr(
       $content-json
    )
)
