xquery version "1.0-ml";

module namespace content = "http://lds.org/code/shared/lds-edit/contentFunctions";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../ice/modules/iceFunctions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace content-functions = "http://lds.org/code/shared/lds-edit/content/content-functions" at "content-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace meta = "http://lds.org/schema/meta/base/v1";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare option xdmp:mapping "true";

declare function getUrisBySection($locale as xs:string, $section as xs:string) as xs:string* {
    cts:element-attribute-values(
        xs:QName('ldse:document'),
        xs:QName('uri'),
        (),
        (),
        cts:element-query(
            $settings:root-qnames,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), fn:concat('/',$section, '*'), ('unstemmed','wildcarded')),
                cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/")
            ))            
        )
    )
};

declare function getContentByUri($locale as xs:string, $uri as xs:string) as element()* {
    cts:search(/*,
        cts:element-query(
            $settings:root-qnames,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, ('unstemmed','wildcarded')),
                cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/")
            ))            
        )
        ,("unfiltered")
    )
};


declare variable $breakdown as map:map:= map:map();

declare function buildUriBreakDown($uris as xs:string*, $locale as xs:string, $section as xs:string) as element(li)* {
    let $_ as empty-sequence() := buildUriBreakdown($uris)
    let $map as map:map := getMap($section, $breakdown)
    return (
         buildNav($map, $locale)
    )
};

declare function buildNav($map as map:map, $locale as xs:string) as element(li)* {
    for $key as xs:string in map:keys($map)
    let $heir as xs:string? := map:get($map, 'heir')
    let $subValue as item()* := map:get($map, $key)
    let $seq as xs:int := if ($key eq 'uris') then (2) else (1)
    order by $seq, $key
    return (
        if (fn:not($key eq ('heir', 'uris')) and map:keys($subValue)[fn:not(. eq ('heir', 'uris'))]) then (
            <li>
                <a href="#" data-hash="/{fn:string-join(($heir,$key), '/')}">{$key}</a>
                <ul>{
                    buildNav($subValue, $locale)
                }</ul>
            </li>
        ) else if ($key eq 'uris') then (
            for $uri-title as xs:string in $subValue
            order by $uri-title
            return (
                <li>
                    <a href="#/{fn:string-join(($heir,$uri-title), '/')}" data-hash="/{fn:string-join(($heir,$uri-title), '/')}">{$uri-title}</a>
                </li>
            )
        ) else ()
    )
};

declare function buildUriBreakdown($uri as xs:string) as empty-sequence() {
    let $uri as xs:string := 
        if (fn:contains($uri, '#')) then (
            fn:substring-before($uri, '#')
        ) else ($uri)
    let $uri as xs:string := 
        if (fn:ends-with($uri, '/')) then (
            fn:substring($uri, 0, fn:string-length($uri) - 1)
        ) else ($uri)
    
    let $allTokens as xs:string* := fn:tokenize($uri, '/')[. ne '']
    let $tokens as xs:string* := ($allTokens)[1 to (fn:last() - 1)]
    let $uri-title as xs:string? := $allTokens[fn:last()]
    let $count as xs:int := fn:count($tokens)
    where $uri-title
    return (
        for $token as xs:string at $index in $tokens
        let $newMap as map:map := map:map()
        let $map as map:map := getMap($tokens[1 to ($index - 1)], $breakdown)
        let $exsits as map:map? := map:get($map, $token)
        let $addPage as empty-sequence() := 
            if ($index eq $count) then (
                let $M as map:map := if (fn:exists($exsits)) then ($exsits) else ($newMap)
                let $pages as xs:string* := map:get($M, 'uris')
                where fn:not($uri-title eq $pages)
                return (
                    map:put($M,'uris',($pages, $uri-title))
                )
            ) else ()
        return (    
            if (fn:exists($exsits)) then () else (
                let $heir as empty-sequence() := map:put($newMap, 'heir', fn:string-join($tokens[1 to $index], '/'))
                return (
                    map:put($map, $token, $newMap)
                )
            )
        )
    )
};

declare function getMap($tokens as xs:string*, $map as map:map) as map:map? {
    let $deeper as map:map? := map:get($map, $tokens[1])
    return (
        if (fn:exists($tokens) and fn:exists($deeper)) then (
           getMap(fn:remove($tokens, 1), $deeper)
        ) else (
            $map
        )
    )
};

declare function fullMap() as map:map {
    $breakdown
};

declare function buildRows($files as element()*) as element(tr)* {
    for $file as element() in $files
    let $uri as xs:string? := ldsemeta:get-document-uri($file)
    let $locale as xs:string := ldsemeta:get-document-locale($file)
    let $title as xs:string? := ldsemeta:get-document-title($file)
    let $type as xs:string := content-functions:getFileType($file)
    let $id as xs:string? := ldsemeta:get-document-id($file)
    let $status as xs:string := ldsemeta:get-document-status($file)
    let $langParams as xs:string := util:split-locale-param($locale)
    let $form-options as element(ldse:form-options)? := ldsemeta:get-form-options($file)
    let $options as element(options)? := 
        if ( fn:exists($form-options) ) then (
            element options { element variables { ice:stripNamespaces($form-options)/* } }
        ) else ()
    where $id ne ''
    order by $uri, $title
    return (
        <tr>
            <td><a href="{$uri}{$langParams}" onclick="ICE.linkToItem(this.href, '{$id}'); return false;">{$uri}</a></td>
            <td>{$type}</td>
            <td>{$title}</td>
            <td class="{fn:lower-case($status)}">{$status}</td>
            <td>{
                if (fn:exists($options)) then (
                    ice:add-ice($locale, $type, $file, $uri, $options)
                ) else ()
            }</td>
            <td>{
                if ( fn:exists(ldsemeta:get-translation-event($file)) ) then (
                    <a href="{$settings:shared-prefix}/ice/resources/ajax/getWorkflow{$langParams}&amp;id={$id}" title="Review Translation" data-pop-size="md" class="ixf-popup">Review</a>
                ) else ()
            }</td>{
             if (ac:has-permission('ldse:view-xml', $locale, '')) then (
                 <td>
                    <a href="{$settings:shared-prefix}/ice/resources/ajax/viewXml{$langParams}&amp;id={$id}" title="View File" data-pop-size="xl" class="ixf-popup">View File</a>
                 </td>
             ) else ()
             }
         </tr>
    )
};

declare function getStatus($file as element()) as xs:string {
    ldsemeta:get-document-status($file)
};

declare function buildSectionTable($files as element()*) as element(table){
    <table>{
        for $file as element() in $files
        let $uri as xs:string? := ldsemeta:get-document-uri($file)
        let $title as xs:string? := ldsemeta:get-document-title($file)
        let $locale as xs:string := ldsemeta:get-document-locale($file)
        let $type as xs:string := content-functions:getFileType($file)
        let $id as xs:string? := ldsemeta:get-document-id($file)
        let $status as xs:string := ldsemeta:get-document-status($file)
        where $id ne ''
        order by $uri, $title
        return (
            <row>     
                <URI>{$uri}</URI>
                <TYPE>{$type}</TYPE>
                <ID>{$id}</ID>
                <TITLE>{$title}</TITLE>
                <STATUS>{$status}</STATUS>
                <LOCALE>{$locale}</LOCALE>
            </row> 
        )
    }</table>
};
