xquery version "1.0-ml";

module namespace api = "http://lds.org/code/shared/lds-edit/api-functions";

import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "../content-admin/modules/content-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../modules/ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../modules/utility-functions.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace cache-control = "http://lds.org/code/modules/cache-control-functions" at "/modules/cacheControlFunctions.xqy";
import module namespace ldses-param = "http://lds.org/code/services/lds-edit/parameters" at "/v1/modules/params.xqy";
import module namespace common = "http://marklogic.com/lds-edit-services/common" at "/v1/modules/common.xqy";

import module namespace srf = "http://lds.org/code/shared/lds-edit/custom/render-functions" at "/custom/lds-edit/render-functions.xqy";
import module namespace c = "http://lds.org/code/shared/common/common-functions" at "/shared/common/commonFunctions.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace df = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../ice/modules/dynamicForms.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace its = "http://www.w3.org/2005/11/its";

declare option xdmp:mapping "true";

declare variable $path as xs:string := xdmp:get-original-url();
declare variable $site as xs:string? := fn:tokenize($path, '/')[2];
declare variable $lang as xs:string? := ( xdmp:get-request-field('lang')[. != ''], fn:tokenize($path, '/')[5] )[1];
declare variable $uri as xs:string := fn:substring-after($path, $lang);
declare variable $childSite as xs:string? := xdmp:get-request-field('site');
declare variable $page-length as xs:string? := xdmp:get-request-field('pageLength');
declare variable $page as xs:string? := xdmp:get-request-field('page');
declare variable $id as xs:string? := xdmp:get-request-field('id');
declare variable $siteProperties as element(siteProperties)? := cts:search(/siteProperties, core:get-filter-query() );
declare variable $id-map as map:map := map:map();
declare variable $file-map as map:map := map:map();

declare variable $sites-nodes as element(site)* := $core:siteProperties/sites/site;
declare variable $hrefElementNamesToChange := $core:siteProperties/transformOptions/hrefNodeNames/name;

declare function api:build-json-array(
    $uri as xs:string*,
    $site as xs:string*,
    $contents as element()*,
    $contentObj as map:map?,
    $content-type as xs:string,
    $config as map:map
) as json:array {
    let $contentsArray as json:array := json:array()
    let $contentsJson as item()* :=
        for $content as element() in $contents
        return (
            api:build-content-json($uri, $site, $content, $contentObj, $content-type, $config)
        )
    let $updateArray as empty-sequence() :=
        if (fn:count($contentsJson) > 0) then (
            for $item in $contentsJson
            return
                json:array-push($contentsArray, $item)
        ) else ()

    return (
        $contentsArray
    )
};

declare function api:imageTransform(
    $content as element(),
    $contentJson as item()
) {
    for $image in $content//image
    let $path as xs:string* := fn:tokenize(xdmp:path($image), "/")[2 to fn:last() - 1]
    let $imageJson as map:map? :=
        if ( fn:exists($image/src) and fn:not($image/src = "") ) then (
            api:get-image-json($image)
        ) else ()
    return (
        api:imageJsonTypeCheck($path, $contentJson, 'image', $imageJson)
    )
};

declare function api:updateImage(
    $path as xs:string*,
    $jsonObj as json:object,
    $imgName as xs:string,
    $imgObj as json:object
) {
    if (fn:empty($path)) then (
        map:put($jsonObj, $imgName, $imgObj)
    ) else if (fn:contains($path[1], "[") and map:contains($jsonObj, fn:replace($path[1], "\[.*\]", ""))) then (
        api:imageJsonTypeCheck($path[2 to fn:last()], map:get($jsonObj, fn:replace($path[1], "\[.*\]", "")), $imgName, $imgObj, xs:integer(fn:substring-before(fn:substring-after($path[1], "["), "]")))
    ) else if (fn:not(map:contains($jsonObj, $path[1]))) then (
        api:imageJsonTypeCheck($path[2 to fn:last()], $jsonObj, $imgName, $imgObj)
    ) else (
        api:imageJsonTypeCheck($path[2 to fn:last()], map:get($jsonObj, $path[1]), $imgName, $imgObj)
    )
};

declare function api:imageJsonTypeCheck(
    $path as xs:string*,
    $json as item(),
    $imgName as xs:string,
    $imgObj as json:object
) {
    api:imageJsonTypeCheck($path, $json, $imgName, $imgObj, ())
};

declare function api:imageJsonTypeCheck(
    $path as xs:string*,
    $json as item(),
    $imgName as xs:string,
    $imgObj as json:object,
    $arrayIndex as xs:integer?
) {
    typeswitch ( $json )
    case json:object return ( api:updateImage($path, $json, $imgName, $imgObj) )
    case json:array return (
        let $arrayIndex := if ( fn:empty($arrayIndex) ) then ( 1 ) else ( $arrayIndex )
        return (
            api:imageJsonTypeCheck($path, $json[$arrayIndex], $imgName, $imgObj)
        )
    )
    default return ()
};

declare function api:wysiwygTransform(
    $content as element(),
    $contentJson as item()
) {
    for $wysiwyg in $content//node()[@type = 'wysiwyg']
    let $pathTokens as xs:string* := fn:tokenize(xdmp:path($wysiwyg), "/")[2 to fn:last() - 1]
    let $processedWysiwyg as element() := srf:defaultProcess($wysiwyg, $content/@locale, $content/ldse:ldse-meta/ldse:document/@uri, <options><host>{c:getHost()}</host></options>)
    let $processedWysiwyg := api:wysiwygImageTransform($processedWysiwyg)
    let $wysiwygText as xs:string? := xdmp:quote($processedWysiwyg/node())
    return (
        api:updateWysiwyg($pathTokens, $contentJson, fn:local-name($processedWysiwyg), $wysiwygText)
    )
};

declare function api:replace-reference-elements(
    $document as element()
) as element() {
    let $referenceElement as element() := ($document//*[@is-reference eq 'true'])[1]
    let $referencedDocument as element()? := cf:getContentById($referenceElement)
    let $newReferencedDocument as element()? :=
        if ( fn:exists($referencedDocument) ) then (
            element { fn:local-name($referencedDocument) } {
                if ( $referenceElement/@type eq 'array' ) then (
                    attribute type { 'array' }
                ) else (),
                $referencedDocument/*
            }
        ) else ()

    let $doc :=
        if ( fn:exists($referencedDocument) ) then (
            mem:node-replace($referenceElement, $newReferencedDocument)/*
        ) else (
            mem:node-delete($referenceElement)/*
        )
    return (
        if (fn:exists($doc//*[@is-reference eq 'true'])) then (
            api:replace-reference-elements($doc)
        ) else (
            $doc
        )
    )
};

declare function api:contentTransformation(
    $content as element(),
    $contentJson as item()
) {
    for $wysiwyg in ( $content/body/div, $content/div, $content/body/header, $content/block )
    let $path as xs:string* :=
        for $s in fn:tokenize(xdmp:path($wysiwyg), "/")[2 to fn:last() - 1]
        return (
            fn:replace($s, "\[.*\]", "")
        )
    let $processedWysiwyg as element() := srf:defaultProcess($wysiwyg, ( $content/@locale, $content/@lang )[1], ( $content/@uri, $content/@data-uri )[1], <options><host>{c:getHost()}</host></options>)
    let $processedWysiwyg := api:wysiwygImageTransform($processedWysiwyg)
    let $wysiwygText as xs:string? := xdmp:quote($processedWysiwyg/node())
    let $name as xs:string? :=
        switch ( $wysiwyg/@class )
        case "body-block" return ( "bodyBlock" )
        case "resources" return ( "footer" )
        case "bodyBlock" return ( "bodyBlock" )
        case "heading" return ( "header" )
        default return ()
    let $name as xs:string? :=
        if ( fn:exists($name) ) then (
            $name
        ) else (
            fn:local-name($wysiwyg)
        )
    return (
        api:updateWysiwyg($path, $contentJson, $name, $wysiwygText, fn:local-name($processedWysiwyg))
    )
};

declare function api:updateWysiwyg(
    $path as xs:string*,
    $jsonObj,
    $textName as xs:string,
    $text as xs:string?
) {
    api:updateWysiwyg($path, $jsonObj, $textName, $text, ())
};

declare function api:updateWysiwyg(
    $pathTokens as xs:string*,
    $jsonObj,
    $textName as xs:string,
    $text as xs:string?,
    $old-name as xs:string?
) {
    let $propertyName := fn:replace($pathTokens[1], '\[.*\]', '')
    let $arrayIndex as xs:integer := xs:integer((fn:replace($pathTokens[1], '.*\[(\d)\]', '$1')[. castable as xs:integer], 1)[1])

    let $get-obj as item()* := map:get($jsonObj, $propertyName)
    return (
        if ( fn:empty($pathTokens) ) then (
            map:put($jsonObj, $textName, $text)
        ) else if ( $get-obj castable as json:array ) then (
            api:updateWysiwyg($pathTokens[2 to fn:last()], $get-obj[$arrayIndex], $textName, $text)
        ) else if ( fn:not(map:contains($jsonObj, $propertyName)) ) then (
            api:updateWysiwyg($pathTokens[2 to fn:last()], $jsonObj, $textName, $text)
        ) else (
            api:updateWysiwyg($pathTokens[2 to fn:last()], map:get($jsonObj, $propertyName), $textName, $text)
        ),
        if ( fn:exists($old-name) ) then (
            map:delete($jsonObj, $old-name)
        ) else ()
    )
};

declare function api:build-content-json(
    $uri as xs:string*,
    $site as xs:string*,
    $content as element(),
    $contentObj as map:map?,
    $content-type as xs:string,
    $config as map:map
) as item() {
    let $contentJson as item() := json:transform-to-json-object($content, $config)

    let $updateImgs := api:imageTransform($content, $contentJson)
    let $updateWysiwyg := api:wysiwygTransform($content, $contentJson)
    let $updateHtmlLegacyContent := api:contentTransformation($content, $contentJson)

    let $content-map as map:map := map:get($contentJson, $content-type)
    let $key as xs:string :=  
        if ( fn:exists(map:get($content-map, 'content')) and fn:not(fn:name($content) = 'custom-page') ) then (
            'contents'
        ) else ( 'content' )
    let $_ as empty-sequence() := (
        if ( fn:exists($contentObj) ) then (
            map:put($content-map, $key, $contentObj)
        ) else ()
    )
    return (
        map:get($contentJson, $content-type)
    )
};

declare function api:get-image-json(
    $image-node as element()
) as map:map? {
    let $imageJson as map:map := json:object()
    let $imageSrcs as json:array := api:getImages($image-node/src/fn:string())
    let $puts as empty-sequence() := (
        map:put($imageJson, "srcs", $imageSrcs),
        map:put($imageJson, "src", c:getHost() || $image-node/src/xs:string(.)),
        map:put($imageJson, "alt", $image-node/alt/xs:string(.))
    )
    return (
        $imageJson
    )
};

declare function api:get-content-json(
    $uri as xs:string*,
    $site as xs:string?,
    $content-type as xs:string,
    $content as element()*,
    $meta as map:map?,
    $config as map:map,
    $addHeader as xs:boolean
) {
    api:get-content-json($uri, $site, $content-type, $content-type, (), $meta, $content, $config, $addHeader)
};

declare function api:get-content-json(
    $uri as xs:string*,
    $site as xs:string?,
    $content-type as xs:string,
    $layout as xs:string?,
    $contentObj as map:map?,
    $metaObj as map:map?,
    $content as element()*,
    $config as map:map,
    $addHeader as xs:boolean
) {
    let $masterObj as map:map := json:object()
    let $buildObj :=
        if (c:stringNotEmpty($layout)) then (
            let $metaObj as map:map := if (fn:exists($metaObj)) then ($metaObj) else (json:object())

            let $layout as empty-sequence() := map:put($metaObj, "layout", $layout)
            let $itemsArray as item()* := (
                api:build-json-array($uri, $site, $content, $contentObj, $content-type, $config)
            )
            let $buildSiteHeader := (
                if ($addHeader) then (
                    let $site-header as element(site-header)? := cf:getSiteHeader($lang, $site)
                    let $update-config as empty-sequence() := map:put($config, 'array-element-names', api:get-array-names($site-header))
                    let $siteHeaderJson := map:get(json:transform-to-json-object($site-header, $config), "site-header")
                    return (
                        map:put($itemsArray[1], "site-header", $siteHeaderJson)
                    )
                ) else ()
            )
            return (
                map:put($masterObj, 'meta', $metaObj),
                map:put($masterObj, 'data', $itemsArray)
            )
        ) else ()
    return (
        xdmp:to-json($masterObj)
    )
};

declare function api:get-all-content(
    $params-in as map:map,
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*
) {
    let $lang as xs:string* := (map:get($params-in, "lang"), "eng")[1]
    let $uri as xs:string* := api:getForwardSlashURLS(map:get($params-in, "uri"))
    let $site as xs:string* := map:get($params-in, "site")
    let $id as xs:string* := map:get($params-in, "id")
    let $page-length as xs:integer := xs:integer(((map:get($params-in, "page-length"))[. castable as xs:integer], $core:siteProperties/default-pagination/xs:integer(.), 10)[1])
    let $page as xs:integer := xs:integer(((map:get($params-in, "page"))[. castable as xs:integer], 1)[1])
    let $contents as element()* := cf:get-file-by($lang, $id, $uri, ())
    let $relatableContent as element(relatable-content)? := $core:siteProperties/related-data/relatable-content
    return (
        if ( $contents/fn:local-name(.) = "custom-page" ) then (
            api:get-custom-page-json($ignoreElementNames, $ignoreAttributeNames, $uri, $site, $contents[fn:local-name(.) = 'custom-page'], $page-length, $page, $relatableContent)
        ) else (
            api:get-article-json($ignoreElementNames, $ignoreAttributeNames, $uri, $site, $contents, fn:true())
        )
    )
};

declare function api:cleanItems(
    $items as element()*
) as element()* {
    for $item at $i in $items
    let $item :=
        let $arrayExists as xs:string* := fn:distinct-values($item//node()[@type = 'array']/fn:local-name(.))
        return
            if ($arrayExists) then (
                api:get-node(mem:node-delete($item//node()[@type = 'array']/@type))
            ) else ( $item )
    let $item :=
        let $itsTranslateExists as xs:string* := fn:distinct-values($item//node()[@its:translate = 'no']/fn:local-name(.))
        return
            if ($itsTranslateExists) then (
                api:get-node(mem:node-delete($item//node()[@its:translate = 'no']/@its:translate))
            ) else ( $item )
    return
        $item
};

declare function api:get-node(
    $item as node()
) as element() {
    typeswitch ( $item )
    case document-node() return ( $item/* )
    default return ( $item )
};

declare function api:get-custom-page-content(
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*,
    $uri as xs:string*,
    $site as xs:string*,
    $custom-page as element()?,
    $config as map:map,
    $page-length as xs:integer?,
    $page as xs:integer?,
    $relatableContent as element(relatable-content)*
) as map:map* {
    let $templateId as xs:string := $custom-page/template-id/fn:string()
    let $template as element()* := cf:getTemplateById($templateId)
    let $uri as xs:string? := ( $custom-page/@uri, $custom-page/ldse:ldse-meta/ldse:document/@uri)[1]
    let $contentObj as map:map := json:object()
    let $json-items as empty-sequence() := api:json-items($template, $uri, $config, $site, $contentObj, $relatableContent)

    let $resourceObj := json:object()
    let $_addResources :=
        let $_ := 
            for $item as element(entry) in ( $custom-page/resources/entry, $custom-page/resource-strings/entry )
            return (
                map:put($resourceObj, $item/@key, ( $item/value/xs:string(.), $item/fn:string() )[1])
            )
        return (
            map:put($contentObj, 'resource-strings', $resourceObj)
        )
        
    let $paginationItem as xs:string? := $template/pagination[. eq "true"]/@content-type
    let $paginationJson := (
        if ($paginationItem) then (
            let $paginationResults as element(search:response)? := if ($paginationItem eq 'article') then (cf:getPaginatedArticles($lang, (), (), $custom-page//site-context/fn:string(.), ($templateId = 'news'), 1 + ($page-length * ($page - 1)), $page-length, "descending")) else ()
            let $paginationJson as item()* := xdmp:from-json(api:get-article-json($ignoreElementNames, $ignoreAttributeNames, $uri, $site, $paginationResults, fn:false()))
            let $articlesJson as json:array :=
                let $data := map:get($paginationJson, "data")
                return (
                    if (json:array-size($data) eq 0) then (
                        json:array()
                    ) else (
                        $data
                    )
                )
            let $paginationInfo as empty-sequence() := map:put($contentObj, "articles", $articlesJson)
            return
                $paginationJson
        ) else ()
    )
    let $metaObj as map:map? := map:get($paginationJson, "meta")
    return (
        $contentObj,
        $metaObj
    )
};

declare function api:json-items(
    $template as element()*,
    $uri as xs:string,
    $config as map:map,
    $site as xs:string*,
    $contentObj as map:map,
    $relatableContent as element(relatable-content)*
) as empty-sequence() {
    for $item as element() in $template/content/*
    let $elementName as xs:string := fn:local-name($item)
    let $items as element()* := cf:get-custom-page-items($elementName, fn:local-name($item), $item/@content-type, $uri)
    let $items as element()* :=
        if ($item/@has-referenced-items eq "true") then (
            (: Replace reference elements :)
            for $item as element() in $items
            let $newDoc := api:replace-reference-elements($item)
            return (
                $newDoc
            )
        ) else ( $items )
    let $arrays as xs:string* := api:get-array-names($items)
    let $item-config as map:map := json:config("custom")
    let $set as empty-sequence() := (
        map:put($item-config, "whitespace", "ignore"),
        map:put($item-config, "array-element-names", $arrays),
        map:put($item-config, "ignore-element-names", map:get($config, "ignore-element-names")),
        map:put($item-config, "ignore-attribute-names", map:get($config, "ignore-attribute-names"))
    )
    let $items as element()* := api:cleanItems($items) ! api:addParametersHref($lang, $site, .)
    let $contentName as xs:string := fn:local-name($items[1])
    let $json-items as item()* := map:get( json:transform-to-json-object($items, $item-config), $contentName )
    return (
        let $itemArray as json:array := json:array()
        let $buildItemArray := api:build-item-array($items, $json-items, $itemArray)
        return (
            map:put($contentObj, $elementName, $itemArray)
        )
    )
};

declare function api:build-item-array(
    $items as element()*,
    $json-items as item()*,
    $itemArray as json:array
) as json:array? {
    for $item as element() at $i in $items
    let $json-item as item()? := $json-items[$i]
    let $updateImage := api:imageTransform($item, $json-item)
    let $updateWysiwyg := api:wysiwygTransform($item, $json-item)

    return (
        json:array-push($itemArray, $json-item)
    )
};

declare function api:get-validSiteHeader(
    $content as element()?,
    $uri as xs:string*,
    $siteParam as xs:string*
) as xs:string?{
    let $sites := ($siteParam, ($content//uri-definition[./uri-path = $uri]/site-context/xs:string(.)))
    return
        (
            $sites[$sites-nodes[@allow-header/xs:boolean(.)]/@value = .],
            $sites-nodes[@default/xs:boolean(.)]/@value
        )[1]
};

declare function api:get-custom-page-json(
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*,
    $uri as xs:string*,
    $site as xs:string?,
    $customPageElement as element(custom-page)?,
    $page-length as xs:integer?,
    $page as xs:integer?,
    $relatableContent as element(relatable-content)*
) {
    let $arrayElementNames as xs:string* := api:get-array-names($customPageElement)
    let $customPage := api:addParametersHref($lang, $site, $customPageElement)
    let $config as map:map := json:config("custom")
    let $set := (
        map:put($config, "whitespace", "ignore"),
        map:put($config, "array-element-names", $arrayElementNames),
        map:put($config, "ignore-element-names", ( $settings:ignore-elements, $ignoreElementNames)),
        map:put($config, "ignore-attribute-names", ( $settings:ignore-attributes, $ignoreAttributeNames))
    )
    let $site as xs:string? := api:get-validSiteHeader($customPage, $uri, $site)
    let $custom-page-json as map:map* := api:get-custom-page-content($ignoreElementNames, $ignoreAttributeNames, $uri, $site, $customPage, $config, $page-length, $page, $relatableContent)
    return (
        api:get-content-json($uri, $site, 'custom-page', $customPage/template-id, $custom-page-json[1], $custom-page-json[2], $customPage, $config, fn:true())
    )
};

declare function api:get-article-json(
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*,
    $uri as xs:string*,
    $site as xs:string?,
    $articles as element()*,
    $addHeader as xs:boolean
) {
    let $meta := json:object()
    let $setMeta := (
        typeswitch ($articles)
        case element(search:response) return (
            map:put($meta, 'total', $articles/@total/fn:string(.)),
            map:put($meta, 'start', $articles/@start/fn:string(.)),
            map:put($meta, 'page-size', $articles/@page-length/fn:string(.))
        )
        default return ()
    )
    let $articles as element()* :=
        typeswitch ($articles)
        case element(search:response) return (cf:getContentFromSearch($articles))
        case element(article) return ($articles)
        case element() return (
            $articles
        )
        default return ()
    let $arrayElementNames as xs:string* := api:get-array-names($articles)
    let $articles as element()* := (api:cleanItems($articles) ! api:addParametersHref($lang, $site, .))
    let $config as map:map := json:config("custom")
    let $set as empty-sequence() := (
        map:put($config, "whitespace", "ignore"),
        map:put($config, "array-element-names", $arrayElementNames),
        map:put($config, "ignore-element-names", ( $settings:ignore-elements, $ignoreElementNames)),
        map:put($config, "ignore-attribute-names", ( $settings:ignore-attributes, $ignoreAttributeNames))
    )
    let $site as xs:string? := api:get-validSiteHeader($articles, $uri, $site)[1]
    return (
        api:get-content-json($uri, $site, fn:name($articles), $articles, $meta, $config, $addHeader)
    )
};

declare function api:get-array-names(
    $content as element()*
) as xs:string* {
    fn:distinct-values($content//node()[@type = 'array']/fn:local-name(.))
};

declare function api:get-manual-json(
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*,
    $uri as xs:string*,
    $site as xs:string?,
    $articles as element()?,
    $addHeader as xs:boolean
) as xs:string {
    let $meta := json:object()
    let $setMeta :=
        typeswitch ($articles)
        case element(search:response) return (
            map:put($meta, 'total', $articles/@total/fn:string(.)),
            map:put($meta, 'start', $articles/@start/fn:string(.)),
            map:put($meta, 'page-size', $articles/@page-length/fn:string(.))
        )
        default return ()
    let $articles as element()* :=
        typeswitch ($articles)
        case element(search:response) return ( cf:getContentFromSearch($articles) )
        case element(ldswebml) return ( $articles )
        case element(html) return ( $articles )
        default return ()

    let $arrayElementNames as xs:string* := api:get-array-names($articles)
    let $articles as element()* := (api:cleanItems($articles) ! api:addParametersHref($lang, $site, .))
    let $config as map:map := json:config("custom")
    let $set as empty-sequence() := (
        map:put($config, "whitespace", "ignore"),
        map:put($config, "array-element-names", $arrayElementNames),
        map:put($config, "ignore-element-names", ( $settings:ignore-elements, $ignoreElementNames)),
        map:put($config, "ignore-attribute-names", ( $settings:ignore-attributes, $ignoreAttributeNames))
    )
    let $site as xs:string? := api:get-validSiteHeader($articles, $uri, $site)[1]
    return (
        api:get-content-json($uri, $site, fn:local-name($articles), $articles, $meta, $config, $addHeader)
    )
};


declare function api:getForwardSlashURLS(
    $url as xs:string
) as xs:string+ {
    $url,
    if ( functx:index-of-string-last($url, '/') eq fn:string-length($url) ) then (
        functx:substring-before-last($url, '/')
    ) else ( $url || '/' )
};


declare function addParametersHref(
    $lang as xs:string,
    $site as xs:string?,
    $contentObj as element()
) as element()* {
    changeHrefNode($lang, $site, $contentObj)
};

declare private function changeHrefNode(
    $lang as xs:string,
    $site as xs:string?,
    $node as node()
) as node() {
    if ( $node instance of element() ) then (
        if (fn:local-name($node) = $hrefElementNamesToChange/xs:string(.)) then (
            element {fn:node-name($node)} {
                $node/@*,
                $node/node()[fn:not(. instance of text())] ! api:changeHrefNode($lang, $site, .),
                text { api:addParametersToLink($lang, $site, $hrefElementNamesToChange[./xs:string(.) = fn:local-name($node)], $node/text()) }
            }
        ) else (
            element { fn:node-name($node) } {
                $node/@*,
                $node/node() ! api:changeHrefNode($lang, $site, .)
            }
        )
    ) else ($node)
};

declare function api:addParametersToLink(
    $lang as xs:string,
    $site as xs:string?,
    $name as element(name),
    $href as xs:string
) as xs:string {
    let $config := map:map()
    let $_ :=
        (
            if ($name/@addLang = 'true') then (
                map:put($config, 'lang', $lang)
            ) else (),
            if ($name/@addSite = 'true') then (
                if ( fn:not(fn:matches($href, "^/si/(institute|seminary)")) and fn:matches($href, "^/si/?.*") ) then (
                    map:put($config, 'site', $site)
                ) else ()
            ) else ()
        )

    return (
        if ( fn:contains($href, "//") ) then (
            $href
        ) else (
            api:buildRelitaveUrl($href, $config)
        )
    )
};

declare function api:buildRelitaveUrl(
    $url as xs:string?,
    $params as map:map?
) as xs:string {
    let $params :=
        if (fn:exists($params)) then $params
        else map:map()
    let $gen-params :=
        for $param in fn:tokenize(fn:substring-after($url, '?'), "[?&amp;]")
        let $tokens := fn:tokenize($param, '=')
        return
            if (fn:exists($tokens[1]) and fn:not(fn:exists(map:get($params, $tokens[1])))) then
                map:put($params, $tokens[1], $tokens[2])
            else ()

    let $add-lang := map:put($params, 'lang', $c:lang)
    let $add-clang := if ( $c:clang ne $c:lang) then map:put($params, 'clang', $c:clang) else ()
    let $add-country := if ( $c:country) then map:put($params, 'country', $c:country) else ()
    let $querystring :=
        fn:string-join(
            for $key in map:keys($params)
            order by fn:lower-case($key)
            return (
                fn:concat($key, '=', map:get($params, $key))
            )
            , '&amp;'
        )

    let $url := fn:replace($url, '^/+', '')
    let $url :=
        if (fn:matches($url, '\?')) then
            fn:substring-before($url, '?')
        else $url
    let $url :=
        if (fn:string-length($querystring) > 0) then (
            fn:concat($url, '?', $querystring)
        ) else ( $url )
    return (
        fn:concat('/', $url)
    )
};

declare variable $placeholderImg as xs:string :=
    let $imgUrl as xs:string* := $core:siteProperties/images/placeholder[@lang = $lang]
    let $defaultImgUrl as xs:string* := $core:siteProperties/images/default-placeholder
    return (
        core:get-display-uri( ( $imgUrl, $defaultImgUrl, '' )[1] )
);

declare function api:getImages(
    $imagePath as xs:string?
) as json:array {
    let $imagesArray := json:array()
    let $buildArray as empty-sequence() :=
        let $imagePathXml as xs:string? := fn:substring-after($imagePath, '/bc')
        let $image-xml-crops as element(crop)* := cf:get-image-xml($imagePathXml)/image-processing/crop
        let $imagePathAfter as xs:string := '/' || functx:substring-after-last($imagePathXml, '/')
        let $root as xs:string := fn:substring-before($imagePath, '/bc')
        let $imagePathXml as xs:string? :=
            if ( fn:exists($image-xml-crops) ) then (
                $imagePath
            ) else (
                functx:substring-before-last(functx:substring-before-last($imagePathXml, '/'), '/') || $imagePathAfter
            )
        let $image-xml-crops as element(crop)* :=
            if ( fn:exists($image-xml-crops) ) then (
                $image-xml-crops
            ) else (
                cf:get-image-xml($imagePathXml)/image-processing/crop
            )
        let $imagePathBefore as xs:string := $root || '/bc' || functx:substring-before-last($imagePathXml, '/') || '/'
        where c:stringNotEmpty($imagePath)
        return (
            for $size as element(resize) in $image-xml-crops/resize
            let $imageObject as map:map := json:object()
            let $width as xs:string? := $size/@width
            let $height as xs:string? := $size/@height
            let $name as xs:string? := $size/../@aspect-ratio-name
            let $host as xs:string := c:getHost()
            let $url as xs:string := $host || $imagePathBefore || $width || 'x' || $height || $imagePathAfter
            let $_ := (
                map:put($imageObject, 'width', $width),
                map:put($imageObject, 'height', $height),
                map:put($imageObject, 'type', $name),
                map:put($imageObject, 'url', $url)
            )
            return (
                json:array-push($imagesArray, $imageObject)
            )
        )
    return (
        $imagesArray
    )
};

declare function api:wysiwygImageTransform(
    $node as node()
) as node() {
    typeswitch ($node)
    case element(img) return
        api:build-image-url($node)
    case element() return
        element {fn:node-name($node)}{
            $node/@*,
            for $n in $node/node() return api:wysiwygImageTransform($n)
        }
    default return $node
};

declare function api:build-image-url(
    $image as element()
) as element(img) {
    let $host as xs:string := c:getHost()
    let $imagePath as xs:string? := $image/@src
    let $url as xs:string :=
        if ( fn:contains($imagePath, "//") ) then (
            $imagePath
        ) else ( $host || $imagePath )
    return (
        element img {
            $image/@*[fn:local-name(.) ne 'src'],
            attribute src { $url },
            $image/*
        }
    )
};

declare function api:getLargestStandard(
    $image as element()
) as element () {
    let $imagePath := $image/@src
    let $sizes as element(ldse:size)* :=
        for $size in $settings:ldse-settings/ldse:image-crop-settings/ldse:aspect-ratio[@name="standard"]/ldse:size
        order by xs:integer($size/@width), xs:integer($size/@height)
        return
            $size
    let $largestStandard := $sizes[fn:last()]
    let $imagePathBefore as xs:string := functx:substring-before-last($imagePath, '/') || '/'
    let $imagePathAfter as xs:string := '/' || functx:substring-after-last($imagePath, '/')
    let $width as xs:string? := $largestStandard/@width
    let $height as xs:string? := $largestStandard/@height
    let $host as xs:string := c:getHost()
    let $url as xs:string := if(fn:contains($imagePath, "//")) then($imagePath) else ($host || $imagePathBefore || $width || 'x' || $height || $imagePathAfter)
    let $transform :=
        element img {
            $image/@*[fn:local-name(.) ne 'src'],
            attribute src { $url },
            $image/*
        }
    return
        $transform
};

declare function api:getPaginatedArticles(
    $lang as xs:string?,
    $id as xs:string?,
    $uriPath as xs:string*,
    $site as xs:string?,
    $start as xs:integer,
    $pageSize as xs:integer,
    $sortDirection as xs:string?
) as element(search:response) {
    api:getPaginatedArticles((), $lang, $id, $uriPath, $site, (), (), $start, $pageSize, (), $sortDirection)
};

declare function api:getPaginatedArticles(
    $lang as xs:string?,
    $id as xs:string?,
    $uriPath as xs:string*,
    $site as xs:string?,
    $filterNonNews as xs:boolean?,
    $start as xs:integer,
    $pageSize as xs:integer,
    $sortDirection as xs:string?
) as element(search:response) {
    api:getPaginatedArticles((), $lang, $id, $uriPath, $site, $filterNonNews, (), $start, $pageSize, (), $sortDirection)
};

declare function api:getPaginatedArticles(
    $term as xs:string?,
    $lang as xs:string?,
    $id as xs:string*,
    $uriPath as xs:string*,
    $site as xs:string?,
    $filterNonNews as xs:boolean?,
    $filterTypes as xs:string*,
    $start as xs:integer,
    $pageSize as xs:integer,
    $sortType as xs:string?,
    $sortDirection as xs:string?
) as element(search:response) {
    let $searchTags as xs:string* := if ($filterNonNews) then (api:getNewsTags($lang)[(. = $filterTypes)[fn:exists($filterTypes)],fn:true()[fn:not(fn:exists($filterTypes))]]) else ($filterTypes[. ne ''])
    return (
        search:search(($term,'')[1], api:buildArticleSearchOptions($lang, $id, $site, $uriPath, $searchTags, $sortType, $sortDirection), $start, $pageSize)
    )
};

declare function api:getNewsTags($lang as xs:string) as xs:string* {
    cts:search(/article-types,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName("news-include"), "true", "exact"),
            cts:element-attribute-value-query(xs:QName("article-types"), xs:QName("locale"), $lang, "exact")
        ))
    )/types[./news-include eq 'true']/name
};

declare function api:buildArticleSearchOptions(
    $lang as xs:string?,
    $id as xs:string?,
    $site as xs:string?,
    $uriPath as xs:string*,
    $searchTags as xs:string*,
    $sortType as xs:string?,
    $sortDirection as xs:string?
) as element(search:options) {
    <options xmlns="http://marklogic.com/appservices/search">
        <searchable-expression>/article</searchable-expression>
        <additional-query>
            {
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName("article"), xs:QName("type"), "article", "exact"),
                    cts:element-attribute-value-query(xs:QName("article"), xs:QName("locale"), $lang, "exact")[fn:exists($lang)],
                    cts:element-attribute-value-query(xs:QName("article"), xs:QName("id"), $id, "exact")[fn:exists($id)],
                    cts:element-value-query(xs:QName("uri-path"), $uriPath, "exact")[fn:exists($uriPath)],
                    cts:element-value-query(xs:QName("tag") , $searchTags, "exact")[fn:exists($searchTags)],
                    cts:element-value-query(xs:QName("site-context"), $site, "exact")[fn:exists($site)]
                ))
            }
        </additional-query>
        <search-option>unfiltered</search-option>
        <return-results>true</return-results>
        <transform-results apply="raw"/>
        <term>
            <empty apply="all-results"/>
            <term-option>case-insensitive</term-option>
            <term-option>diacritic-insensitive</term-option>
            <term-option>punctuation-insensitive</term-option>
            <term-option>whitespace-insensitive</term-option>
            <term-option>lang={$lang}</term-option>
        </term>
        {
(:        Need to change this sort variable :)
            let $sort as xs:string := ( $sortDirection[. = ('asc', 'ascending')], 'descending' )[1]
            return (
                if ($sortType = 'date') then (
                    <sort-order type="xs:date" direction="{$sort}">
                        <element ns="" name="publication-date"/>
                    </sort-order>
                ) else (
                    <sort-order type="xs:string" direction="{$sort}">
                        <element ns="" name="content">
                            <element ns="" name="title"/>
                        </element>
                    </sort-order>
                )
            )
        }
    </options>
};

declare function api:get-category-content(
    $params-in as map:map?,
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*
) {
    let $id as xs:string? := map:get($params-in, 'catId')
    let $uri as xs:string? := map:get($params-in, 'uri')
    let $categories as element()* := cf:get-categories($uri)
    let $content as element()* :=
        for $category as element(category) in $categories
        let $cat-id as xs:string := ( $category/@id, ldsemeta:get-document-id($category) )[1]
        let $contents as element()* := api:transform-contents($cat-id)
        order by $category/sequence
        return (
            mem:node-insert-child($category, $contents)/*
        )
    let $meta := json:object()
    let $setMeta := (
        typeswitch ($content)
        case element(search:response) return (
            map:put($meta, 'total', $content/@total/fn:string(.)),
            map:put($meta, 'start', $content/@start/fn:string(.)),
            map:put($meta, 'page-size', $content/@page-length/fn:string(.))
        )
        default return ()
    )
    let $arrayElementNames as xs:string* := api:get-array-names( ( $content, $categories ) )
    let $config as map:map := json:config("custom")
    let $set as empty-sequence() := (
        map:put($config, "whitespace", "ignore"),
        map:put($config, "array-element-names", $arrayElementNames),
        map:put($config, "ignore-element-names", ( $settings:ignore-elements, $ignoreElementNames)),
        map:put($config, "ignore-attribute-names", ( $settings:ignore-attributes, $ignoreAttributeNames))
    )
    return api:get-content-json((), (), 'category', $content, $meta, $config, fn:false())
};

declare function api:transform-contents(
    $id as xs:string
) as element()* {
    for $content as element() in cf:get-category-content($id)
    let $form-name as xs:string := $content//ldse:form
    let $form as element(ldse:formTemplate)? := df:getFormTemplateWithoutMode($form-name)
    let $title as xs:string? := df:get-title($content, $form)
    let $uri as xs:string := ( $content/content/uri-path[. != ""], $content/@uri )[1]
    return (
        <contents type="array">
            <title>{$title}</title>
            <uri>{$uri}</uri>
        </contents>
    )
};

declare function api:get-tag-content(
    $params-in as map:map?,
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*
) {
    let $id as xs:string? := map:get($params-in, 'catId')
    let $uri as xs:string? := map:get($params-in, 'uri')
    let $tags as element()* := cf:get-tags($uri)
    let $content as element()* :=
        for $tag as element(category) in $tags
        order by $tag/sequence
        return (
            $tag
        )
    let $meta := json:object()
    let $setMeta := (
        typeswitch ($content)
        case element(search:response) return (
            map:put($meta, 'total', $content/@total/fn:string(.)),
            map:put($meta, 'start', $content/@start/fn:string(.)),
            map:put($meta, 'page-size', $content/@page-length/fn:string(.))
        )
        default return ()
    )
    let $arrayElementNames as xs:string* := api:get-array-names($content)
    let $config as map:map := json:config("custom")
    let $set as empty-sequence() := (
        map:put($config, "whitespace", "ignore"),
        map:put($config, "array-element-names", $arrayElementNames),
        map:put($config, "ignore-element-names", ( $settings:ignore-elements, $ignoreElementNames)),
        map:put($config, "ignore-attribute-names", ( $settings:ignore-attributes, $ignoreAttributeNames))
    )
    return api:get-content-json((), (), 'tags', $content, $meta, $config, fn:false())
};

declare function api:get-content() {
    let $ignoreElementNames as xs:QName* := ( xs:QName("template-id"), xs:QName("resources"), xs:QName("channel"), xs:QName("_value"), xs:QName('ldse:ldse-meta') )
    let $ignoreAttributeNames as xs:QName* := ( xs:QName("class"), xs:QName('status'), xs:QName("its:translate"), xs:QName('duplicate'), xs:QName('type'), xs:QName('auto-publish-ref'), xs:QName('fetch-data') )
    return (
        api:get-all-content($ignoreElementNames, $ignoreAttributeNames)
    )
};

declare function api:get-all-content(
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*
) as xs:string {
    let $page-length as xs:integer := xs:integer( ( $page-length, $siteProperties/default-pagination/xs:integer(.), 10 )[1] )
    let $page as xs:integer := xs:integer( ( $page, 1 )[1] )
    let $contents as element()* := cf:get-file-by($lang, $id, $uri, ())
    return (
        if ( $contents/fn:local-name(.) = "custom-page" ) then (
            api:get-custom-page-json($ignoreElementNames, $ignoreAttributeNames, $uri, $childSite, $contents[fn:local-name(.) = 'custom-page'], $page-length, $page, ())
        ) else (
            api:get-items-json($ignoreElementNames, $ignoreAttributeNames, $uri, $childSite, $contents, fn:true())
        )
    )
};

declare function api:build-json-dictionary(
    $arrayElementNames,
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*,
    $items as element(resources)*
) {
    let $masterObj := json:object()
    let $metaObj := json:object()

    let $config := json:config("custom")
    let $set as empty-sequence() := (
        map:put($config, "whitespace", "ignore"),
        map:put($config, "array-element-names", ($arrayElementNames)),
        map:put($config, "ignore-element-names", $ignoreElementNames),
        map:put($config, "ignore-attribute-names", $ignoreAttributeNames)
    )
    let $itemsArray as json:array := json:array()
    let $_buildObject :=
        for $item as element(resources) in $items
        let $id as xs:string := $item/ldse:ldse-meta/ldse:document/@id
        let $name as xs:string := $item/name
        let $dictObj := json:object()
        let $dictArr as json:array := json:array()
        let $terms := json:object()
        let $_buildTerms :=
            for $entry as element() in $item/properties/entry
            let $key as xs:string := $entry/@key
            let $val as item()* := xdmp:quote($entry/value/node())
            return (
                map:put($terms, $key, $val)
            )
        return (
            map:put($dictObj, 'type', 'dictionary'),
            map:put($dictObj, 'id', $id),
            map:put($dictObj, 'name', $name),
            map:put($dictObj, 'terms', $terms),
            json:array-push($itemsArray, $dictObj)
        )

    let $_ := (
        map:put($masterObj, 'meta', $metaObj),
        map:put($masterObj, 'items', $itemsArray)
    )

    return $masterObj
};

declare function api:dictionary-functions(
    $bundles as xs:string*,
    $lang as xs:string,
    $site as xs:string?
) {
    api:dictionary-functions('', (), (), $bundles, $lang, $site)
};

declare function api:dictionary-functions(
    $arrayElementNames,
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*,
    $bundles as xs:string*,
    $lang as xs:string
) {
    api:dictionary-functions('', (), (), $bundles, $lang, ())
};

declare function api:dictionary-functions(
    $arrayElementNames,
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*,
    $bundles as xs:string*,
    $lang as xs:string,
    $site as xs:string?
) {
    let $items as element(resources)* := cf:getDictionary($lang, $bundles, $site)
    return (
(:        cache-control:addCacheHeader(()),:)
        if($ldses-param:outputFormatIsJSON) then (
            ldses-param:declareReturnType(),
            xdmp:to-json(api:build-json-dictionary($arrayElementNames, $ignoreElementNames, $ignoreAttributeNames, $items))
        ) else if($ldses-param:outputFormatIsXML) then (
            ldses-param:declareReturnType(),
            element bundles {
                $items
            }
        ) else (
            common:error("lds-edit-services:UNSUPPORTED-FORMAT", fn:concat("'", $ldses-param:format, "' is not a supported format."))
        )
    )
};

declare function api:get-items-json(
    $ignoreElementNames as xs:QName*,
    $ignoreAttributeNames as xs:QName*,
    $uri as xs:string*,
    $site as xs:string?,
    $articles as element()*,
    $addHeader as xs:boolean
) as xs:string {
    let $meta := json:object()
    let $setMeta := (
        typeswitch ($articles)
            case element(search:response) return (
                map:put($meta, 'total', $articles/@total/fn:string(.)),
                map:put($meta, 'start', $articles/@start/fn:string(.)),
                map:put($meta, 'page-size', $articles/@page-length/fn:string(.))
            )
            default return ()
    )
    let $articles as element()* :=
        typeswitch ($articles)
        case element(search:response) return (cf:getContentFromSearch($articles))
        case element(article) return ($articles)
        default return ( $articles )
    let $articles as element()* := api:fetch-data-items($articles)

    let $arrayElementNames as xs:string* := api:get-array-names($articles)
(:    let $articles as element(article)* := (api:cleanItems($articles) ! api:addParametersHref($lang, $site, .)):)
    let $config as map:map := json:config("custom")
    let $set as empty-sequence() := (
        map:put($config, "whitespace", "ignore"),
        map:put($config, "array-element-names", $arrayElementNames),
        map:put($config, "ignore-element-names", ( $settings:ignore-elements, $ignoreElementNames)),
        map:put($config, "ignore-attribute-names", ( $settings:ignore-attributes, $ignoreAttributeNames))
    )
    let $articles as element()* := api:get-distinct-articles($articles)
    let $site as xs:string? :=
        for $article as element() in $articles
        return api:get-validSiteHeader($article, $uri, $site)
    return (
        api:get-content-json($uri, $site, fn:local-name($articles[1]), $articles, $meta, $config, $addHeader)
    )
};

declare function api:fetch-data-items(
    $content as element()
) as element() {
    let $id as xs:string := ( ldsemeta:get-document-id($content), $content/@id )[1]
    let $fetch-nodes as element()* := $content//node()[@fetch-data = 'true']/..
    let $update :=
        for $item as element() in $fetch-nodes
        let $get-content as element() :=
            element { fn:name($item) } {
                $item/@*,
                for $child-item as element() in $item/element()
                return (
                    element { fn:name($child-item) } {
                        $child-item/@*,
                        cf:get-file-by($lang, $child-item/fn:string(), (), ())
                    }
                )
            }
        let $new-file as element() := util:get-root( mem:advanced-operation(("replace", $item, $mem:start-mod-qname, $get-content, $mem:end-mod-qname)) )
        return (
            map:put($id-map, $item/fn:string(), $item/fn:string()),
            map:put($file-map, 'file', $new-file)
        )
    return (
        if ( fn:exists($id) and fn:exists($fetch-nodes) ) then (
            map:get($file-map, 'file'), xdmp:log(map:get($file-map, 'file'))
        ) else ( $content )
    )
};

declare function api:get-distinct-articles(
    $articles as element()*
) as element()* {
    for $article as element() in $articles
    where fn:empty(map:get($id-map, $article/@id))
    return $article
};
