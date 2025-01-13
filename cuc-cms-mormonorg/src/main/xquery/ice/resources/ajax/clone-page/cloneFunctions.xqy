xquery version "1.0-ml";

module namespace cloneFunctions = "http://lds.org/code/shared/lds-edit/clone-functions";

import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../../modules/ldse-meta.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../../modules/dynamicForms.xqy";
import module namespace tf = "http://lds.org/code/shared/lds-edit/fromTrigger" at "../../../../translation/from/modules/fromTriggerFunctions.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at "../../../../modules/site-properties.xqy";
import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "/content-admin/modules/content-functions.xqy";
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "/content-admin/modules/functions.xqy";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace meta = "http://lds.org/schema/meta/base/v1";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare variable $localeMap as map:map := map:map();
declare variable $idMap as map:map := map:map();
declare variable $filesSaved as map:map := map:map();
declare variable $compMap as map:map := map:map();
declare variable $site as xs:string := $core:site;

declare function copyFilesByUri($locale as xs:string, $from-site as xs:string, $newLocale as xs:string, $to-site as xs:string,
    $currentUri as xs:string, $newUri as xs:string, $recurse as xs:boolean, $currentID as xs:string?, $site-prefix as xs:string?, $updToUniversalTemplate as xs:string?) as empty-sequence() {

    let $put as empty-sequence() := map:put($compMap, 'currentID', $currentID)
    let $newCustomPageId as xs:string := getNewId($newLocale, $currentID)
    let $put as empty-sequence() := map:put($compMap, $currentID, $newCustomPageId)
    let $files as element()* :=
        if($settings:clone) then (
        (:If this is the new Dynamic Cloning feature, fetching by URI is a problem since subcomponents gets pulled as well. So We are going to only fetch by ID:)
        ldsemeta:get-files-by($currentID, $locale, (), (), $from-site)
        ) else ( ldsemeta:get-files-by((), $locale, $currentUri, (), $from-site) )
    let $allFileIds as xs:string* := ldsemeta:get-document-id($files)
    let $collections as element(collection)* := $files[self::collection]
    let $refIds as xs:string* := $collections/items/item[fn:not(. = $allFileIds)]
    let $newCollectionFiles as element()* :=
        if(fn:exists($refIds)) then (
            ldsemeta:get-files-by($refIds,$locale,(),())
        ) else ()
    let $allFiles as element()* := ($files,$newCollectionFiles)
    let $put as empty-sequence() := mapCompUpdate($files, $newLocale)
    return (
        copyFile($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $allFiles, $recurse, $site-prefix, $updToUniversalTemplate)
    )
};

declare function copyFile($locale as xs:string, $from-site as xs:string, $newLocale as xs:string, $to-site as xs:string, $currentUri as xs:string, $newUri as xs:string, $file as element(), $recurse as xs:boolean?, $site-prefix as xs:string?, $updToUniversalTemplate as xs:string?) as empty-sequence() {
    let $oldId as xs:string := ldsemeta:get-document-id($file)
    let $custom-page-id := cts:search(/custom-page,
                                cts:and-query((
                                    cts:directory-query('/preview/', 'infinity'),
                                    cts:element-value-query(xs:QName('ldse:site-context'), $to-site, 'exact' ),
                                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $newUri, 'exact' )
                                )))/@id
    let $wrapperId as xs:string := (map:get($compMap, map:get($compMap, 'currentID')), $custom-page-id)[1]
    let $docType as xs:string := fn:name($file)
    let $newId as xs:string := if ($docType eq 'custom-page') then
                                   $wrapperId
                               else getNewId($newLocale, $oldId)
    let $recurse as xs:boolean := if ($recurse) then ($recurse) else (fn:false())
    let $hasChildComponents := $file//element()[@fetch-data = "true" or @is-reference = "true"]
    where fn:not(isSaved($newId))
    return (
        let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:_build-default-meta($file, $newId, $newLocale, $newUri, 'preview')
        let $updated-ldse-meta :=
            if ($updToUniversalTemplate ne 'yes' ) then
                element ldse:ldse-meta
                {
                    $ldse-meta/@*,
                    $ldse-meta/* except ($ldse-meta/ldse:form-options, $ldse-meta/ldse:translation-event),
                    element ldse:form-options
                    {
                        $ldse-meta/ldse:form-options/@*,
                        $ldse-meta/ldse:form-options/* except ($ldse-meta/ldse:form-options/ldse:site-context,
                        $ldse-meta/ldse:form-options/ldse:site,
                        $ldse-meta/ldse:form-options/ldse:wrapper-id,
                        $ldse-meta/ldse:form-options/ldse:siteUriContext),
                        if ($ldse-meta/ldse:form-options/ldse:site-context) then element ldse:site-context {$to-site} else (),
                        if ($ldse-meta/ldse:form-options/ldse:site) then element ldse:site {$to-site} else (),
                        if ($ldse-meta/ldse:form-options/ldse:siteUriContext) then element ldse:siteUriContext {$site-prefix} else (),
                        if ($docType ne 'custom-page') then element ldse:wrapper-id {$wrapperId} else ()
                    }
                }
            else
                element ldse:ldse-meta
                {
                    $ldse-meta/@*,
                    $ldse-meta/* except ($ldse-meta/ldse:form-options),
                    element ldse:form-options
                    {
                        $ldse-meta/ldse:form-options/@*,
                        $ldse-meta/ldse:form-options/* except ($ldse-meta/ldse:form-options/ldse:pageId,
                        $ldse-meta/ldse:form-options/ldse:templateId,
                        $ldse-meta/ldse:form-options/ldse:templateName,
                        $ldse-meta/ldse:form-options/ldse:wrapper-id,
                        $ldse-meta/ldse:form-options/ldse:site-context,
                        $ldse-meta/ldse:form-options/ldse:site,
                        $ldse-meta/ldse:form-options/ldse:siteUriContext),
                        if ($ldse-meta/ldse:form-options/ldse:site-context) then element ldse:site-context {$to-site} else (),
                        if ($ldse-meta/ldse:form-options/ldse:site) then element ldse:site {$to-site} else (),
                        if ($ldse-meta/ldse:form-options/ldse:siteUriContext) then element ldse:siteUriContext {$site-prefix} else (),
                        if ($ldse-meta/ldse:form-options/ldse:templateId) then element ldse:templateId {'mo-universal-template'} else (),
                        if ($ldse-meta/ldse:form-options/ldse:templateName) then element ldse:templateName {'mo-universal-template'} else (),
                        if ($ldse-meta/ldse:form-options/ldse:pageId) then element ldse:pageId {'mo-universal-template'} else (),
                        if ($docType ne 'custom-page') then element ldse:wrapper-id {$wrapperId} else ()
                    }
                }
        let $newXml as element() := tf:remove-context($file)
        let $newXml as element() := updateId($newXml, $newId, $oldId)
        let $newXml as element() := updateCompId($newXml)
        let $newXml as element() := updateParentId($newXml)
        let $newXml as element() := tf:updateUri($newXml, $newUri)
        let $newXml as element() := tf:updateStatus($newXml, 'preview')
        let $newXml as element() := tf:updateLdseMeta($newXml, $updated-ldse-meta)
        let $newXml as element() := tf:updateLocale($newXml, $newLocale)
        let $newXml as element() := if ($hasChildComponents) then
            updateChildRefs($newXml, $locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $recurse, $site-prefix, $updToUniversalTemplate)
        else $newXml
        let $newXml as element() := updateCollectionItems($newXml, $newLocale)
        let $newXml as element() := updatePreTags($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $newXml, $site-prefix, $updToUniversalTemplate)
        let $newXml as element() := updateCustomPage($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $newXml, $site-prefix, $updToUniversalTemplate)
        let $newXml as element() := updateUriDefinitionInCustomPage($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $newXml)
        let $newXml as element() := updateUriHistoryInCustomPage($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $newXml)
        let $newXml as element() := if ($updToUniversalTemplate eq 'yes') then updToUniversalTemplateInCustomPage($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $newXml) else $newXml
        let $form-name as element()? := ldsemeta:get-form-options($newXml)/form
        let $form as element()? := form:getFormTemplate($form-name)
        let $folderSufix as xs:string? := $form/ldse:folder
        let $filePrefix as xs:string? :=
            if (fn:starts-with($form/ldse:file-prefix, "$")) then (
                form:getVariable(fn:substring-after($form/ldse:file-prefix, "$"))
            ) else ( $form/ldse:file-prefix )
        let $dbPath as xs:string :=
            core:build-db-path($newUri, $newLocale, $newId, $newXml,
                <options>
                    <folder>{ $folderSufix }</folder>
                    <file-prefix>{ $filePrefix }</file-prefix>
                </options>
            )
        return (
            core:save-file($dbPath, $newXml, ())
        )
    )
};

declare function copyFileUsedByClongingInsideComponentOnly($locale as xs:string, $site as xs:string, $newUri as xs:string, $file as element(), $newId as xs:string) as element() {
    let $site-prefix := sp:get-site-properties($site)/site-context/fn:string()
    let $custom-page := form:get-custom-page($newUri, $locale, $site)
    let $template-id := $custom-page/ldse:ldse-meta/ldse:form-options/ldse:templateId/fn:string()
    let $wrapper-id := $custom-page/@id/fn:string()
    let $oldId as xs:string := ldsemeta:get-document-id($file)
    let $form := xs:string(fn:node-name($file))
    where fn:not(isSaved($newId))
    return (
        let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:_build-default-meta($file, $newId, $locale, $newUri, 'preview')
        let $updated-ldse-meta :=
            element ldse:ldse-meta
            {
                $ldse-meta/@*,
                $ldse-meta/* except ($ldse-meta/ldse:form-options, $ldse-meta/ldse:translation-event),
                element ldse:form-options
                {
                    $ldse-meta/ldse:form-options/@*,
                    $ldse-meta/ldse:form-options/* except ($ldse-meta/ldse:form-options/ldse:form,
                    $ldse-meta/ldse:form-options/ldse:site-context,
                    $ldse-meta/ldse:form-options/ldse:site,
                    $ldse-meta/ldse:form-options/ldse:siteUriContext,
                    $ldse-meta/ldse:form-options/ldse:templateId,
                    $ldse-meta/ldse:form-options/ldse:templateName,
                    $ldse-meta/ldse:form-options/ldse:wrapper-id,
                    $ldse-meta/ldse:form-options/ldse:current-page),
                    element ldse:form {$form},
                    element ldse:site-context {$site},
                    element ldse:siteUriContext {$site-prefix},
                    element ldse:wrapper-id {$wrapper-id},
                    (: currently all child components user template-id in template-name. Need to keep it this way or some functionalities will break :)
                    element ldse:template-name {$template-id},
                    element ldse:current-page {$newUri}
                }
            }

        let $newXml as element() := tf:remove-context($file)
        let $newXml as element() := updateId($newXml, $newId, $oldId)
        let $newXml as element() := updateCompId($newXml)
        let $newXml as element() := updateParentId($newXml)
        let $newXml as element() := tf:updateUri($newXml, $newUri)
        let $newXml as element() := tf:updateStatus($newXml, 'preview')
        let $newXml as element() := tf:updateLocale($newXml, $locale)
        let $newXml as element() := tf:updateLdseMeta($newXml, $updated-ldse-meta)
        let $newXml as element() := updateCollectionItems($newXml, $locale)
        let $form-name as element()? := ldsemeta:get-form-options($newXml)/form
        let $form as element()? := form:getFormTemplate($form-name)
        let $folderSufix as xs:string? := $form/ldse:folder
        let $filePrefix as xs:string? :=
            if (fn:starts-with($form/ldse:file-prefix, "$")) then (
                form:getVariable(fn:substring-after($form/ldse:file-prefix, "$"))
            ) else ( $form/ldse:file-prefix )
        let $dbPath as xs:string :=
            core:build-db-path($newUri, $locale, $newId, $newXml,
                <options>
                    <folder>{ $folderSufix }</folder>
                    <file-prefix>{ $filePrefix }</file-prefix>
                </options>
            )
        let $save :=  core:save-file($dbPath, $newXml, ())
        return $newXml
    )
};

declare function updateCountry($locale as xs:string, $xml as element()) as element(){
    let $country as xs:string? := (util:get-country-from-locale($locale), "chq")[1]
    return mem:node-replace($xml/ldse:ldse-meta/ldse:document/@source, attribute source { $country })
};

declare function updateChildRefs($xml as element(), $locale as xs:string, $from-site as xs:string, $newLocale as xs:string, $to-site as xs:string, $currentUri as xs:string, $newUri as xs:string, $recurse as xs:boolean, $site-prefix as xs:string?, $updToUniversalTemplate as xs:string?) {
    let $child-nodes := $xml//element()[@fetch-data = "true" or @is-reference = "true"]
    return (
        if ($child-nodes) then (
            let $new-child-nodes :=
                for $child-node in $child-nodes
                let $child-file := ldsemeta:get-file-by($child-node/fn:string(.),$locale,(),())
                let $copy := copyFile($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $child-file, $recurse, $site-prefix, $updToUniversalTemplate)
                let $id := getNewId($locale, $child-node)
                return element {fn:local-name($child-node)} {$child-node/@* , $id }

            return mem:congruent-replace($child-nodes, $new-child-nodes)
        ) else ($xml)
    )
};

declare function updateCollectionItems($xml as element(), $locale as xs:string) as element() {
    if ( fn:node-name($xml) eq xs:QName('collection') ) then (
        let $items as element(items) :=
            element items {
                for $item as element(item) in $xml/items/item
                return (
                    element item {
                         $item/@*,
                         getNewId($locale, xs:string($item))
                    }
                )
            }
        return (
            mem:node-replace($xml/items, $items)
        )
    ) else ( $xml )
};

declare function updateCustomPage($locale as xs:string, $from-site as xs:string, $newLocale as xs:string, $to-site as xs:string, $currentUri as xs:string, $newUri as xs:string, $xml as element(), $site-prefix as xs:string?, $updToUniversalTemplate as xs:string?) as element() {
    if (fn:node-name($xml) eq xs:QName('custom-page')) then (
        let $content as element(content) :=
            element content {
                attribute its:translate {'no'},
                for $node as element() in $xml/content/*
                let $oldId as xs:string? := xs:string($node)
                return (
                    if ( fn:matches($oldId, '(^[0-9]*-[a-z,A-Z]{3}.*$)') ) then (
                        let $file as element()? := ldsemeta:get-file-by($oldId, $locale, (), ())
                        let $copy as item()* := copyFile($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $file, fn:false(), $site-prefix, $updToUniversalTemplate)
                        return if ($updToUniversalTemplate eq 'no') then
                            element { fn:node-name($node) } {
                                $node/@*,
                                getNewId($newLocale, $oldId)
                            }
                        else
                            element { fn:node-name($node) } {
                                $node/@* except $node/@region,
                                attribute region {'page-components'},
                                getNewId($newLocale, $oldId)
                            }
                    ) else ( $node )
                )
            }
        return (
            mem:node-replace($xml/content, $content)
        )
    ) else ( $xml )
};

declare function updateUriDefinitionInCustomPage($locale as xs:string, $from-site, $newLocale as xs:string, $to-site, $currentUri as xs:string, $newUri as xs:string, $xml as element()) as element() {

    if (fn:node-name($xml) eq xs:QName('custom-page')) then (

        let $_site-prefix := sp:get-site-properties($to-site)/site-context/fn:string()

        let $site-prefix := if (fn:starts-with($_site-prefix, '/') and $_site-prefix ne '/') then
                                fn:substring-after($_site-prefix, '/')
                            else $_site-prefix

        let $_uri := if (fn:starts-with($newUri, '/')) then
                        fn:substring-after($newUri, '/')
                     else $newUri

        let $uri := if (fn:starts-with($_uri, $site-prefix||'/') and  $site-prefix ne '/') then
                        let $s := fn:substring-after($_uri, $site-prefix||'/')
                        return if ($s eq '') then
                                   '/'
                               else $s
                    else $_uri

        let $uri-definition as element (uri-definition) :=
            element uri-definition {$xml/uri-definition/@*,
            $xml/uri-definition/* except ($xml/uri-definition/site-context, $xml/uri-definition/uri, $xml/uri-definition/uri-path),
            element site-context {$to-site},
            element uri {$uri},
            element uri-path {$newUri}}
        return (
            mem:node-replace($xml/uri-definition, $uri-definition)
        )
    ) else ( $xml )
};

declare function updateUriHistoryInCustomPage($locale as xs:string, $from-site, $newLocale as xs:string, $to-site, $currentUri as xs:string, $newUri as xs:string, $xml as element()) as element() {
    if (fn:node-name($xml) eq xs:QName('custom-page')) then
        let $uri-history  := <uri-history  its:translate="no" xmlns:its="http://www.w3.org/2005/11/its">
            <page-uri timestamp="{fn:current-dateTime()}">{$newUri}</page-uri>
        </uri-history>
        return if ($xml/uri-history) then
            mem:node-replace($xml/uri-history, $uri-history)
        else mem:insert-after($xml/uri-definition, $uri-history)
    else $xml
};

declare function updToUniversalTemplateInCustomPage($locale as xs:string, $from-site, $newLocale as xs:string, $to-site, $currentUri as xs:string, $newUri as xs:string, $xml as element()) as element() {

    if (fn:node-name($xml) eq xs:QName('custom-page')) then (
        let $newTemplateId := element template-id {'mo-universal-template'}
        return (
            mem:node-replace($xml/template-id, $newTemplateId)
        )
    ) else ( $xml )
};

declare function copyRewriteRule($locale as xs:string, $newLocale as xs:string, $currentUri as xs:string, $newUri as xs:string, $site as xs:string, $to-site as xs:string) as empty-sequence() {
    let $file as element(rewriteRules)? :=
        cts:search(/rewriteRules,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), $locale, 'exact'),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('site'), $site, 'exact')
            ))
        )
    let $global as element(rewriteRules)? :=
        cts:search(/rewriteRules,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), 'global', 'exact'),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('site'), $site, 'exact')
            ))
        )

    let $newLocaleFile as element(rewriteRules)? :=
        cts:search(/rewriteRules,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), $newLocale, 'exact'),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('site'), $to-site, 'exact')
            ))
        )
    let $removedPrefixCurrentUri as xs:string := removeSharedPrefix($currentUri)
    let $removedPrefixNewUri as xs:string := removeSharedPrefix($newUri)
    let $oldRule as element(rule)? := ($file/rule[@path eq $removedPrefixCurrentUri and @params eq "0"], $global/rule[@path eq $removedPrefixCurrentUri and @params eq "0"])[1]
    let $newRule as element(rule) :=
        element rule {
            attribute path { if ( fn:contains($removedPrefixNewUri, '/' ) ) then ( $removedPrefixNewUri ) else ( fn:error() ) },
            attribute params {0},
            if ( fn:contains($oldRule, "?url=") ) then (
                fn:concat(fn:substring-before(xs:string($oldRule), '?'), '?url=', $newUri)
            ) else (
                xs:string($oldRule)
            )
        }
    where fn:exists($oldRule)
    return (
        if ( fn:exists($newLocaleFile) and fn:exists($newLocaleFile/rule[1]) ) then (
            xdmp:node-insert-before($newLocaleFile/rule[1], $newRule)
        ) else if ( fn:exists($newLocaleFile) and fn:empty($newLocaleFile/rule[1]) ) then (
            xdmp:node-insert-child($newLocaleFile, $newRule)
        ) else (
            let $createdFile as element(rewriteRules) := <rewriteRules status="preview" locale="{$newLocale}" site="{$to-site}"> {$newRule} </rewriteRules>
            let $dbPath as xs:string := core:build-db-path((), $newLocale, (), $createdFile, ())
            return(
                core:save-file($dbPath, $createdFile, ())
            )
        )
    )
};

(: This function removes the shared prefix if found :)
declare function removeSharedPrefix($uri as xs:string) as xs:string{
    let $sharedPrefix as xs:string? := $settings:shared-prefix
    return (
        if ( $sharedPrefix ne '' and fn:starts-with($uri,$sharedPrefix) ) then (
            fn:substring-after($uri, $sharedPrefix)
        ) else (
            $uri
        )
    )
};

declare function updatePreTags($locale as xs:string, $from-site as xs:string, $newLocale as xs:string, $to-site as xs:string, $currentUri as xs:string, $newUri as xs:string, $nodes as item()*, $site-prefix as xs:string?, $updToUniversalTemplate) as item()* {
    for $node as item() in $nodes
    return (
        typeswitch ($node)
            case text() return $node
            case comment() return $node
            case element(ldse:ldse-meta) return $node
            case element(pre) return updatePreTag($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $node, $site-prefix, $updToUniversalTemplate)
            case element(xhtml:pre)   return updatePreTag($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $node, $site-prefix, $updToUniversalTemplate)
            default return (
                element {fn:node-name($node)} {
                    $node/@*,
                    updatePreTags($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $node/node(), $site-prefix, $updToUniversalTemplate)
                }
            )
    )
};

declare function updatePreTag($locale as xs:string, $from-site as xs:string, $newLocale as xs:string, $to-site as xs:string, $currentUri as xs:string, $newUri as xs:string, $pre as element(), $site-prefix as xs:string?, $updToUniversalTemplate as xs:string?) as item()* {
    let $typeAndName as xs:string? := fn:substring-before(fn:substring-after(xs:string($pre),"["),"]")
    let $type as xs:string? := fn:lower-case(fn:tokenize($typeAndName,":")[1])
    let $oldId as xs:string? := fn:tokenize($typeAndName,":")[2]
    return (
        if ( fn:matches($oldId, '(^[0-9]*-[a-z,A-Z]{3}.*$)') ) then (
            let $file as element()? := ldsemeta:get-file-by($oldId, $locale, (), ())
            let $newId as xs:string := getNewId($newLocale, $oldId)
            let $copy as item()* := copyFile($locale, $from-site, $newLocale, $to-site, $currentUri, $newUri, $file, fn:false(), $site-prefix, $updToUniversalTemplate)
            return (
                element pre {fn:concat("[", $type, ":", $newId, "]")}
            )
        ) else ($pre)
    )
};


declare function isSaved($newId as xs:string) as xs:boolean {
    if (fn:exists(map:get($filesSaved, $newId))) then (
        map:get($filesSaved, $newId)
    ) else (
        let $save as empty-sequence() := map:put($filesSaved, $newId, fn:true())
        return (fn:false())
    )
};

declare function endSlash($uri as xs:string) as xs:string {
    if (fn:substring($uri, fn:string-length($uri) - 1, 1) ne '/') then (
        fn:concat($uri,'/')
    ) else ($uri)
};

declare function getNewId($locale as xs:string, $oldId as xs:string) as xs:string {
    if (fn:exists(map:get($idMap, $oldId))) then (
        map:get($idMap, $oldId)
    ) else (
        let $newId as xs:string := util:generate-unique-id($locale)
        let $save as empty-sequence() := map:put($idMap, $oldId, $newId)
        return ($newId)
    )
};

declare function mapCompUpdate($files as element()*, $newLocale as xs:string) as empty-sequence() {
    for $file as element() in $files
    return (
        if ( ( fn:exists($file/@compId) and fn:not($file/@compId = "") ) or ( fn:local-name($file) = "component" and fn:not($file/@parent = "") and fn:exists($file/@parent) ) ) then (
            let $oldId as xs:string := ($file/@compId, $file/@parent)[1]
            let $newId as xs:string := getNewId($newLocale, $oldId)
            return (
                map:put($compMap, $oldId, $newId)
            )
        ) else ()
    )
};

declare function updateId($xml as element(), $newId as xs:string, $oldId as xs:string) as element() {
    let $id as xs:string? := map:get($compMap, $oldId)
    let $xml as element() :=
        if ( fn:exists($xml/@id) ) then (
            mem:node-replace($xml/@id, attribute id { $newId })
        ) else ( $xml )
    let $xml as element() :=
        if ( fn:exists($xml/search-meta/source) ) then (
            mem:node-replace($xml/search-meta/source, element source { $newId })
        ) else ( $xml )
    return $xml
};

declare function updateCompId($xml as element()) as element() {
    let $id as xs:string? := map:get($compMap, $xml/@compId)
    let $xml as element() :=
        if ( fn:exists($xml/@compId) and fn:not($xml/@compId = "") ) then (
            mem:node-replace($xml/@compId, attribute compId { $id })
        ) else ( $xml )
    return $xml
};

declare function updateParentId($xml as element()) as element() {
    let $id as xs:string? := map:get($compMap, $xml/@parent)
    let $xml as element() :=
        if ( fn:exists($xml/@parent) and fn:not($xml/@parent = "") ) then (
            mem:node-replace($xml/@parent, attribute parent { $id })
        ) else ( $xml )
    return $xml
};


declare function clone-selected-components(
    $locale as xs:string,
    $uri as xs:string,
    $ids as xs:string*,
    $clone as xs:string?,
    $region as xs:string?,
    $site as xs:string?
) as item()* {
    let $page as element()? := cf:get-custom-page-with-uri-lang-site($uri, $locale, $site)
    return
        if ($page) then
            let $templateId as xs:string := $page/ldse:ldse-meta/ldse:form-options/ldse:templateId/fn:string()
            let $wrapperId as xs:string := $page/@id/fn:string()
            let $fileUri as xs:string :=  fn:substring-before($page/base-uri(),'/page')
            let $allowableComponents as xs:string* := sp:get-templates($templateId)/region[@id eq $region]/*/@content-type/fn:string()
            let $process as element()* :=
                for $id in $ids
                let $content as element() := cf:get-content-by-id($id, ( 'preview', 'unpublish' ))
                let $componentType as xs:string := fn:local-name($content)
                let $allowed := $allowableComponents[. eq $componentType]
                let $clonedDoc as item()* :=
                    if ($allowed) then
                        af:clone-component($locale, $uri, $id, $fileUri, (), $wrapperId, $templateId)
                    else ()
                let $clonedDocId as xs:string? := ($clonedDoc)[1]
                return
                    if ($allowed) then
                        element {$componentType} {attribute is-id {"true"},
                                                  attribute region {$region},
                                                  $clonedDocId}
                    else ()
            return if ($process) then
                        let $new-page as element() := mem:node-insert-child($page/content, $process)/*
                        let $new-page as element() := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })/*
                        let $updateCustomPage := core:document-replace($page, $new-page)
                        let $count := count($process)
                        return if ($count > 1) then
                                    $count ||' components were cloned to '||$uri
                                else
                                    $count ||' component was cloned to '||$uri
                   else 'No component was cloned to '||$uri
        else $uri ||'is not found'
};
