xquery version "1.0-ml";

module namespace sf = "http://lds.org/code/shared/lds-edit/content-admin/slug-functions";

import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "content-functions.xqy";
import module namespace mem-op = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace c = "http://lds.org/code/shared/common/common-functions" at "/shared/common/commonFunctions.xqy";
import module namespace g = "http://lds.org/code/lds-edit/content-admin/globalVariables" at "globalVariables.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace df = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../ice/modules/dynamicForms.xqy";
import module namespace ldseUtil = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '../../modules/site-properties.xqy';
import module namespace rw = "http://lds.org/code/shared/lds-edit/rewrite-functions" at '../../ice/modules/rewrite-functions.xqy';

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $site as xs:string? := xdmp:get-request-field('site');
declare variable $site-properties as element(siteProperties)? := sp:get-site-properties($site);

declare function sf:getUniqueSlug(
    $slug as xs:string,
    $context as xs:string?,
    $id as xs:string,
    $lang as xs:string
) as xs:string {
    sf:getUniqueSlug($slug, $context, $id, $lang, ())
};

declare function sf:getUniqueSlug(
    $slug as xs:string,
    $context as xs:string?,
    $id as xs:string,
    $lang as xs:string,
    $itteration as xs:integer?
) as xs:string {
    let $newSlug := $slug || ( '-' || ($itteration + 1))[fn:exists($itteration)]
    let $notUnique as xs:boolean :=
        fn:exists(
            cts:search(fn:collection(),
                cts:and-query((
                    core:get-filter-query(),
                    cts:and-query((
                        cts:element-range-query(xs:QName("uri-path"), "=", $newSlug),
                        if ( fn:exists($context) and fn:not($context = "") ) then (
                            cts:element-value-query(xs:QName('site-context'), $context, 'exact')
                        ) else (),
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact')
                    )),
                    cts:not-query(
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact')
                    )
                ))
            )/*
        )
    return (
        if ($notUnique) then (sf:getUniqueSlug($slug, $id, $lang, (($itteration + 1)[fn:exists($itteration)], 0)[1])) else ($newSlug)
    )
};

declare function sf:getForwardSlashURLS(
    $url as xs:string
) as xs:string+ {
    $url,
    if ( functx:index-of-string-last($url, '/') eq fn:string-length($url) ) then (
        functx:substring-before-last($url, '/')
    ) else (
        $url || '/'
    )
};

declare function sf:postProcessUriChildPath(
    $origFile as element()?,
    $newXml as element()
) as element() {
    let $old-uri as xs:string? := $origFile/ldse:ldse-meta/ldse:document/@uri
    let $new-uri as xs:string := $newXml/ldse:ldse-meta/ldse:document/@uri
    return (
        if ( fn:not($old-uri = $new-uri) and fn:exists($origFile) ) then (
            let $uri-path as xs:string := $origFile/ldse:ldse-meta/ldse:document/@uri
            let $_ := sf:updateChildren($uri-path, $newXml)
            let $template as element(template) := cf:getTemplateById($newXml/ldse:ldse-meta/ldse:form-options/ldse:templateId)
            let $update-rule := rw:remove-rewrite-rule($old-uri, $new-uri, $template)
            return core:action-transform("ldse:unpublish", $newXml)
        ) else ( $newXml )
    )
};

declare function sf:updateChildren(
    $uri-path as xs:string,
    $newXml as element()
) as item()* {
    let $locale := fn:string($newXml/ldse:ldse-meta/ldse:document/@locale)
    let $site := fn:string(($newXml/ldse:ldse-meta/ldse:form-options/ldse:site-context)[1])
    let $childArticle as element()* :=
        cts:search(fn:collection(),
            cts:and-query((
                cts:or-query((
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName("uri"),  ($uri-path || "/"), 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName("uri"),  $uri-path, 'exact')
                )),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName("locale"),  $locale, 'exact'),
                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
                core:get-filter-query(),
                cts:not-query((
                    cts:element-query(xs:QName("custom-page"), cts:and-query(())),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName("id"), $newXml/ldse:ldse-meta/ldse:document/@id, 'exact')
                ))
            ))
        )/*
    for $i as element() in $childArticle
    let $newPath as element() := $newXml/uri-definition/uri-path
    let $newArticle as element() :=  mem-op:node-replace($i//@uri, attribute uri {$newPath/fn:string()})/*
    let $oldPath as element()? := $newArticle/uri-definition/uri-path
    let $newArticle as element() :=
        if (fn:exists($oldPath[. = $uri-path])) then (
            mem-op:node-replace($oldPath[. = $uri-path], element uri-path {$newPath/fn:string()})/*
        ) else ($newArticle)
    return (
        core:update-file( "ldse:unpublish", xdmp:node-uri($i), core:action-transform("ldse:unpublish", $newArticle), $i, ())
    )
};

declare function sf:postProcessUriDefinition(
    $origFile as element()?,
    $newXml as element(),
    $form as element(ldse:formTemplate)
) as element() {
    let $blacklist := $site-properties/invalidUris
    let $uriNodes := getUriNodes($newXml)
    let $newXml as element() :=
        if ( fn:not($origFile/uri-definition/uri = $newXml/uri-definition/uri) and fn:exists($origFile) ) then (
            let $uri-path as xs:string := $uriNodes/uri-path
            return mem-op:node-replace($newXml/ldse:ldse-meta/ldse:document/@uri, attribute uri {$uri-path})
        ) else ( $newXml )
    let $newXml as element() := sf:postProcessUriChildPath($origFile, $newXml)
    let $noUriNode := mem-op:node-delete($newXml/uri-definition)
    return mem-op:node-insert-child($noUriNode, $uriNodes)
};

declare function sf:getUriNodes(
    $newXml as element()
) as element(uri-definition)* {
    for $uriDefinition in functx:distinct-deep($newXml/uri-definition)
    let $site-context as xs:string := $site-properties/site-context
    let $inputUri as xs:string? := $uriDefinition/uri
    let $cleanUri := sf:cleanUri($inputUri, $site-context, $newXml)
    let $cleanUri as xs:string? :=
        if ( $cleanUri = '' ) then (
            '/'
        ) else ( $cleanUri )
    let $uriPath := ldseUtil:clean-db-uri('/' || $site-context || '/' || ($cleanUri)[$cleanUri != '/' and $cleanUri != ''])
    let $context := $newXml
    let $uriDefinitionNodes :=
        element uri-definition {
            $uriDefinition/@*,
            $uriDefinition/site-context,
            element uri { $cleanUri },
            element uri-path { $uriPath }
        }

    where (
        $uriPath,
        fn:not(
                let $templateUri := $newXml/ldse:ldse-meta/ldse:form-options/ldse:templateUri
                let $patterns := ($site-properties/invalidUris/all/pattern, $site-properties/invalidUris/node()[fn:local-name(.) = $site]/pattern)[fn:not(@ignoreUri = $templateUri)]
                return (
                    for $pattern in $patterns
                    return fn:matches($uriPath, $pattern/xs:string(.))
                )
        )
    )
    return (
        $uriDefinitionNodes
    )
};

declare function sf:cleanUri(
    $uri as xs:string,
    $site-context as xs:string?,
    $newXml as element()
) as xs:string {
    let $clean as xs:string := ldseUtil:sanitize-input($uri)
    let $clean as xs:string := fn:replace($clean, fn:codepoints-to-string((91, 63, 8220, 8221, 8217, 34, 35, 42, 44, 46, 38, 39, 93)), '')
    let $clean as xs:string := fn:replace($clean, '(^\s+|ldquo|rdquo|\s+$)', '')
    let $clean as xs:string := fn:replace($clean, '\s+', '-')
    let $clean as xs:string := fn:lower-case($clean)
    let $clean as xs:string := fn:replace($clean, '(—)|(–)|(&#x2013;)|(&#8211;)|(#x2014;)|(#8212;)', '-')
    let $clean as xs:string? := sf:getUniqueSlug($clean, $site, $newXml/@id/xs:string(.), $newXml/@locale/xs:string(.))
    let $clean as xs:string? := if(fn:starts-with($clean, "/")) then (fn:substring($clean, 2)) else ($clean)
    return $clean
};

declare function sf:check-rewrite-rules(
    $lang as xs:string,
    $site as xs:string?,
    $uri as xs:string,
    $id as xs:string?,
    $site-properties as element(siteProperties)
) as xs:string {
    let $file as element()? := cts:search(fn:collection(), cts:and-query(( core:get-filter-query(), cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact') )) )/*
    let $file-uri as xs:string? := $file/@uri
    let $rules as element(rewriteRules)? := cf:get-rewrite-rules($lang, $site)
    let $rule as element(rule)? := ldseUtil:get-root-uri($uri, $rules, 0)
    let $current-site-context :=  $site-properties/site-context/fn:string()
    let $properties-with-host as element(siteProperties)* := sp:get-site-properties-by($site-properties/urls/url)[@site != $site-properties/@site]
    let $site-contexts as xs:string* := $properties-with-host/site-context

    let $test1 := (: Check if uri match the prefix of another site's prefix :)
        for $context as xs:string in $site-contexts[. != '']
        let $_context := fn:replace($context||'/', '//', '/')
        let $count1 := fn:string-length($current-site-context)
        let $count2 := fn:string-length($_context)
        where ($context ne '/' and fn:starts-with($uri, $_context) and $count1 <= $count2)
                        or $uri = $context or $uri = $_context
        return 'matched'

    let $test2 := (: check if uri exists in other sites with the same host :)
            cts:search(/custom-page,
                cts:and-query((
                    cts:directory-query('/preview/', 'infinity'),
                    cts:element-value-query(xs:QName('ldse:site-context'), $properties-with-host/@site, 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact')
                )))

    let $test3 := (: check the consolidated sites prefixes :)
        let $site-properties := sp:get-site-properties($site)
        return
            for $i in cts:search(/site-additional-hosts/site,
                cts:and-query((
                    cts:not-query((
                        cts:element-attribute-value-query(xs:QName('site'), xs:QName('id'), $site, 'exact')
                    )),
                    cts:element-attribute-value-query(xs:QName('site'), xs:QName('host'), $site-properties/urls/url/fn:string(), 'exact')
                )))
            let $site-prefix := $i/@prefix||sp:get-site-properties($i/@id)/site-context/fn:string()
            where fn:starts-with($uri, $site-prefix||'/') or $uri eq $site-prefix
            return $site-prefix

    return
        if ( ( fn:exists($rule) and fn:not($file-uri = $uri) ) or ($test1) or ($test2) or ($test3)) then (
            'false'
        ) else ( 'true' )

};

declare function sf:is-unique-uri(
    $slug as xs:string*,
    $lang as xs:string,
    $id as xs:string?,
    $site as xs:string?
) as xs:boolean {
    fn:exists(
        cts:search(fn:collection(),
            cts:and-query((
                core:get-filter-query(),
                cts:and-query((
                    cts:or-query((
                        if ( fn:exists($slug) and fn:not($slug = "") ) then (
                            cts:element-value-query(xs:QName("uri-path"), $slug, 'exact')
                        ) else (),
                        if ( fn:exists($slug) and fn:not($slug = "") ) then (
                            cts:element-attribute-value-query(( xs:QName('article'), xs:QName('custom-page') ), xs:QName('uri'), $slug, 'exact')
                        ) else ()
                    )),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
                    cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
                )),
                if ( fn:exists($id) ) then (
                    cts:not-query(
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact')
                    )
                ) else ()
            ))
        )/*
    )
};

declare function sf:track-uri-change(
    $origFile as element()?,
    $newXml as element(),
    $form as element(ldse:formTemplate)
) as element() {
    let $currentDateTime := fn:current-dateTime()
    let $page-uri := <page-uri timestamp="{$currentDateTime}">{$newXml/ldse:ldse-meta/ldse:document/@uri/fn:string()}</page-uri>
    let $uri-history := if ($origFile/uri-history) then
                            if ($origFile/ldse:ldse-meta/ldse:document/@uri ne $newXml/ldse:ldse-meta/ldse:document/@uri) then
                                <uri-history  its:translate="no" xmlns:its="http://www.w3.org/2005/11/its">{$origFile/uri-history/*, $page-uri}</uri-history>
                            else
                                $origFile/uri-history
                        else
                           <uri-history  its:translate="no" xmlns:its="http://www.w3.org/2005/11/its">{$page-uri}</uri-history>
    return
       if ($newXml/uri-history) then
           mem-op:node-replace($newXml/uri-history, $uri-history)
       else
           mem-op:node-insert-child($newXml, $uri-history)
};
