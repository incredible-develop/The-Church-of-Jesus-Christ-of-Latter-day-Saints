xquery version '1.0-ml';

module namespace archf = 'http://lds.org/code/lds-edit/content-admin/modules/archive-functions';

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "content-functions.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";

declare namespace ldse = 'http://lds.org/code/lds-edit';

declare function archf:archive-content(
    $uri as xs:string?,
    $form as xs:string,
    $docId as xs:string,
    $site as xs:string,
    $archiveStatus as xs:string
) as item()* {
    let $file as element()? := cf:get-file-by($lang, $docId, (), $site)
    let $uri as xs:string := ( $uri, ldsemeta:get-document-uri($file)[. != ""] )[1]
    let $new-uri as xs:string := util:clean-db-uri(fn:concat($uri, '/archive'))
    let $new-file as element() := mem:node-replace($file/@uri, attribute uri { $new-uri })/*
    let $new-file as element() := mem:node-replace($new-file/ldse:ldse-meta/ldse:document/@uri, attribute uri { $new-uri })/*
    let $new-file as element() := mem:node-replace($new-file/ldse:ldse-meta/ldse:document/@status, attribute status { "preview" })/*
    let $new-file as element() := mem:node-replace($new-file/@status, attribute status { "preview" })/*
    let $new-file as element() := if ( fn:exists($new-file//ldse:publish-date) ) then ( mem:node-delete($new-file//ldse:publish-date)/* ) else ( $new-file )
    let $file-path as xs:string := xdmp:node-uri($file)
    let $custom-page as element(custom-page)? := cf:get-custom-page-by-uri($new-uri, $site)
    return (
        if ( fn:empty($custom-page) ) then (
            archf:build-custom-page($custom-page, $new-uri)
        ) else (),
        core:update-file('ldse:unpublish', $file-path, $new-file, $file)
    )
};

declare function archf:build-custom-page(
    $custom-page as element(custom-page)
) {
    let $new-id as xs:string := util:generate-unique-id()
    let $new-custom-page as element(custom-page)? := 
        element { fn:local-name($custom-page) } {
            $custom-page/@* except $custom-page/(@id|@uri),
            attribute id { $new-id || '-eng' },
            attribute uri { $new-uri },
            $custom-page/node()
        }
    let $uri-path as element()? := $new-custom-page/uri-definition/uri-path
    let $uri-ele as element()? := $new-custom-page/uri-definition/uri
    let $new-title as xs:string := fn:concat($new-custom-page/title, ' Archive')
    let $new-custom-page as element(custom-page) := mem:node-replace($new-custom-page/ldse:ldse-meta/ldse:document/@id, attribute id { $new-id || '-eng' })
    let $new-custom-page as element(custom-page) := mem:node-replace($new-custom-page/ldse:ldse-meta/ldse:document/@uri, attribute uri { $new-uri })
    let $new-custom-page as element(custom-page) := mem:node-replace($new-custom-page/title, element title { $new-title })
    let $new-custom-page as element(custom-page) := if ( fn:exists($uri-ele) ) then ( mem:node-replace($new-custom-page/uri-definition/uri, element uri { fn:concat($uri-ele, '/archive') }) ) else ( $new-custom-page )
    let $new-custom-page as element(custom-page) := if ( fn:exists($uri-path) ) then ( mem:node-replace($new-custom-page/uri-definition/uri-path, element uri-path { fn:concat($uri-path, '/archive') }) ) else ( $new-custom-page )
    let $page-path as xs:string := core:build-db-path($new-uri, $lang, $new-id, $new-custom-page, <options><file-prefix>page-</file-prefix></options>)
    return (
        core:save-file($page-path, $new-custom-page, ())
    )
};

declare function archf:unarchive-content(
    $uri as xs:string?,
    $form as xs:string,
    $docId as xs:string,
    $site as xs:string,
    $archiveStatus as xs:string
) as item()* {
    let $file as element()? := cf:get-file-by($lang, $docId, (), $site)
    let $uri as xs:string := ( $uri, ldsemeta:get-document-uri($file)[. != ""] )[1]
    let $new-uri as xs:string := fn:replace($uri, '/archive', '')
    let $new-file as element() := mem:node-replace($file/@uri, attribute uri { $new-uri })/*
    let $new-file as element() := mem:node-replace($new-file/ldse:ldse-meta/ldse:document/@uri, attribute uri { $new-uri })/*
    let $new-file as element() := mem:node-replace($new-file/ldse:ldse-meta/ldse:document/@status, attribute status { "preview" })/*
    let $new-file as element() := mem:node-replace($new-file/@status, attribute status { "preview" })/*
    let $new-file as element() := if ( fn:exists($new-file//ldse:publish-date) ) then ( mem:node-delete($new-file//ldse:publish-date)/* ) else ( $new-file )
    let $file-path as xs:string := xdmp:node-uri($file)
    let $custom-page as element(custom-page)? := cf:get-custom-page-by-uri($new-uri, $site)
    return (
        core:update-file('ldse:unpublish', $file-path, $new-file, $file)
    )
};