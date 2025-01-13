xquery version "1.0-ml";
module namespace json-snippet = "http://lds.org/code/shared/lds-edit/content/json-snippet";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

import module namespace content-settings = "http://lds.org/code/shared/lds-edit/content/content-settings" at "content-settings.xqy";
import module namespace content-module = "http://lds.org/code/shared/lds-edit/content/content-module" at "content-module.xqy";
import module namespace content-search = "http://lds.org/code/shared/lds-edit/content/content-search" at "content-search.xqy";
import module namespace content-workflow = "http://lds.org/code/shared/lds-edit/content/content-workflow" at "content-workflow.xqy";
import module namespace content-functions = "http://lds.org/code/shared/lds-edit/content/content-functions" at "content-functions.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '../../modules/site-properties.xqy';

import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../ice/modules/iceFunctions.xqy";
import module namespace json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace hldse = "http://lds.org/code/lds-edit/history";
declare namespace search = "http://marklogic.com/appservices/search";

declare option xdmp:mapping "true";

declare variable $site as xs:string? := xdmp:get-request-field('site');

declare function getRootString(
    $uri as xs:string
) as xs:string {
    let $uri as xs:string:= functx:replace-first($uri, ($settings:shared-prefix[. ne ''], '/')[1], '')
    return (
        if (fn:contains($uri, '/')) then (
            fn:substring-before($uri, '/')
        ) else if ($uri eq '') then (
           'home-page'
        ) else (
            $uri
        )
    )
};

declare function getUriString(
    $file as element()
) as xs:string? {
    typeswitch ($file)
    case element(resources) return (
        fn:concat($settings:shared-prefix, "/string-manager/bundle-editor?lang=", (ldsemeta:get-document-locale($file), "eng")[1], "&amp;bundle=", $file/name, "&amp;locale=", $file/@locale)
    )
    default return (
        ldsemeta:get-document-uri($file)
    )
};

declare function build-language-map() as map:map {
    let $map as map:map := map:map()
    let $_  as empty-sequence() :=
        for $language as element(language) in $languages
        return (
            map:put($map, fn:concat($language/@key, $core:mode), xs:string($language/englishName))
        )
   return (
        $map
   )
};

declare variable $languages as element(language)* := cts:search(/languages/language, cts:and-query(( () )) );
declare variable $language-map as map:map := build-language-map();
declare function get-full-language-name-by-locale(
    $lang as xs:string
) as xs:string? {
    map:get($language-map, fn:concat($lang, $core:mode))
};

declare function get-comment-uri-string(
    $file as element()
) as xs:string? {
    typeswitch ($file)
    case element(resources) return (
        fn:concat($settings:shared-prefix, "/string-manager/bundle-editor?lang=", (ldsemeta:get-document-locale($file), "eng")[1], "&amp;bundle=", $file/name, "&amp;locale=", $file/@locale)
    )
    default return (
        ldsemeta:get-history-document-uri($file)
    )
};

declare function getPreviewUrl(
    $file as node()
) as xs:string {
    typeswitch ($file)
    case element(resources) return (
        json:keyEscapedValue("previewUrl", (fn:concat($settings:shared-prefix, "/string-manager/bundle-editor?lang=", (ldsemeta:get-document-locale($file), "eng")[1], "&amp;bundle=", $file/name, "&amp;locale=", $file/@locale), "")[1])
    )
    default return (
        let $mode-param as xs:string? := 
            if ( fn:exists($settings:app-domain/@mode) ) then (
                '&amp;mode=' || $settings:app-domain/@mode
            ) else ()
        let $uri-param as xs:string? :=
            if ( fn:exists($settings:app-domain/@db-path[. = 'true']) and fn:exists($file) ) then (
                '&amp;uri=' || xdmp:url-encode($file/xdmp:node-uri(.))
            ) else ()
        let $site-properties as element(siteProperties)? := sp:get-site-properties($site)
        return (
            if ( fn:exists($site-properties) and fn:exists($site-properties/site-context) ) then (
                json:keyEscapedValue('previewUrl', '//' || $site-properties/urls/url[@env = 'preview'] || ldsemeta:get-document-uri($file) || '?lang=' || ldsemeta:get-document-locale($file)) || $mode-param || $uri-param
            ) else (
                let $preview-url as xs:string := core:build-url(ldsemeta:get-document-uri($file), (ldsemeta:get-document-locale($file), "eng")[1], ( $uri-param || $mode-param ) )
                let $domain-for-preview as xs:string? := ( $settings:app-domain, $settings:live-domain )[1]
                let $preview-right-url as xs:string := fn:replace($preview-url, "^(https?://).*?(/.*)$", fn:concat("$1", $domain-for-preview, "$2"))
                
                return json:keyEscapedValue("previewUrl", $preview-right-url )
            )
        )
    )
};

declare function getPageNum($options as item()*) as xs:string {
	($options/search:param/search:pageNum/fn:string(), "0")[1]
};

declare function getRoot(
    $file as node()
) as xs:string {
    if ( fn:node-name($file) != xs:QName('resources') and fn:node-name($file) != xs:QName('category') ) then (
        json:keyValue("root", getRootString(getUriString($file)) )
    ) else if ( fn:node-name($file) = xs:QName('category') ) then (
        json:keyValue("root", "category")
    ) else (
        json:keyValue("root", "rice")
    )
};

declare function getLanguage(
    $file as node()
) as xs:string {
    json:keyValue("language", get-full-language-name-by-locale(ldsemeta:get-document-locale($file)) ) 
};

declare function getLocale(
    $file as node()
) as xs:string {
     json:keyValue("locale", ldsemeta:get-document-locale($file))
};

declare function get-preview-locale(
    $file as node()
) as xs:string {
     json:keyValue("previewLocale", util:split-locale-param(ldsemeta:get-document-locale($file)))
};

declare function getType(
    $file as node()
) as xs:string {
	(
    	json:keyValue("fileType", fn:replace(ldsemeta:get-document-type($file), ":", ":&#8203;") )
    )
};

declare function getTitle(
    $file as node()
) as xs:string {
    json:keyValue("title",json:escapeString( (ldsemeta:get-document-title($file)[. != ''], getUriString($file))[1] ))
};

declare function getWord(
    $file as node()
) as xs:string {
    json:keyValue("words", fn:string(ldsemeta:get-document-words($file)))
};

declare function getCid(
    $file as node()
) as xs:string {
    json:keyValue("cid",json:escapeString(($file/ldse:ldse-meta/ldse:translation-event/ldse:translation-returned/@component-id)[1])) 
};

declare function getUri(
    $file as node()
) as xs:string {
    json:keyValue("uri",json:escapeString(getUriString($file))) 
};

(: Gets Document ID :)
declare function getId(
    $file as node()
) as xs:string {
     json:keyValue("id",ldsemeta:get-document-id($file))
};

declare function getPublished(
    $file as node()
) as xs:string {
    json:keyValue("published", content-search:formatDate( ldsemeta:get-publish-date($file)/@date) )
};

declare function getPublisher($file as node()) as xs:string{
    json:keyValue("publisher", ldsemeta:get-publish-date($file)/@username)
};

declare function getApprover($file as node()) as xs:string{
    json:keyValue("approver", $file/ldse:ldse-meta/ldse:translation-event/ldse:translation-approved/@username)
};

declare function get-creator($file as node()) as xs:string {
    json:keyValue("creator", $file/ldse:ldse-meta/ldse:created/@username)
};

declare function get-date-created($file as node()) as xs:string {
    json:keyValue("date-created", content-search:formatDate($file/ldse:ldse-meta/ldse:created/@date))
};

declare function get-modifier($file as node()) as xs:string {
    json:keyValue("modifier", $file/ldse:ldse-meta/ldse:last-modified/@username)
};

declare function get-date-modified($file as node()) as xs:string {
    json:keyValue("date-modified", content-search:formatDate($file/ldse:ldse-meta/ldse:last-modified/@date))
};

declare function get-unpublished-date($file as node()) as xs:string {
    json:keyValue("unpublished-date", content-search:formatDate($file/ldse:ldse-meta/ldse:unpublish-date/@date))
};

declare function get-unpublished-user($file as node()) as xs:string {
    json:keyValue("unpublisher", $file/ldse:ldse-meta/ldse:unpublish-date/@username)
};

declare function get-scheduled-publish($file as node()) as xs:string {
    json:keyValue("scheduledPublish", $file/ldse:ldse-meta/ldse:schedule-publish/@date)
};

declare function get-scheduled-unpublish($file as node()) as xs:string {
    json:keyValue("scheduledUnpublish", $file/ldse:ldse-meta/ldse:schedule-unpublish/@date)
};

declare function get-scheduled-publisher($file as node()) as xs:string {
    json:keyValue("scheduledPublisher", $file/ldse:ldse-meta/ldse:schedule-unpublish/@username)
};

declare function get-scheduled-unpublisher($file as node()) as xs:string {
    json:keyValue("scheduledUnpublisher", $file/ldse:ldse-meta/ldse:schedule-unpublish/@username)
};

declare function get-commenter($file as node()) as xs:string {
    json:keyValue("commenter", $file/@username)
};

declare function get-comment($file as node()) as xs:string {
    let $string as xs:string := fn:substring($file/node(), 0, 100)
    return json:keyEscapedValue("comment", $string)
};

declare function get-comment-date($file as node()) as xs:string {
    json:keyValue("commentedDate", content-search:formatDate($file/@date))
};

declare function get-comment-locale($file as node()) as xs:string {
    json:keyValue("locale", $file/hldse:current/hldse:ldse-meta/hldse:document/@locale)
};

declare function getSite($file as node()) as xs:string {
    json:keyValue("site", $file/ldse:ldse-meta/ldse:form-options/ldse:site-context)
};

declare function get-options($file as node()) as xs:string {
    json:keyValue("option", ice:csv-variables(<variables>{ldsemeta:get-form-options($file)/(@*|node())}</variables>))
};

declare function get-file-type($file as node()) as xs:string {
    json:keyValue("fileType", $file//*:ldse-meta/*:document/@type)
};

declare function get-is-custompage($file as node()) as xs:string? {
	if($file//*:ldse-meta/*:document/@type = "custom-page")
	then json:keyValue("isCustomPage", "true")
	else ()
};

declare function get-comment-type($file as node()) as xs:string {
    json:keyValue("commentFileType", $file/hldse:current/hldse:ldse-meta/hldse:document/@type)
};

declare function get-comment-title($file as node()) as xs:string {
    json:keyValue("commentTitle", $file/hldse:current/hldse:ldse-meta/hldse:document/@title)
};

declare function get-comment-id($file as node()) as xs:string {
    json:keyValue("id", $file/hldse:current/hldse:ldse-meta/hldse:document/@id)
};

declare function get-page($file as node()) as xs:string {
    json:keyValue("page", $file/@page)
};

declare function get-comment-options($file as node()) as xs:string {
    json:keyValue("option", ice:csv-variables(<variables>{$file/hldse:current/hldse:ldse-meta/hldse:form-options/node()}</variables>))
};

declare function get-comment-uri($file as node()) as xs:string {
    json:keyValue("uri", get-comment-uri-value($file))
};

declare function get-comment-uri-value($file as node()) as xs:string {
    $file/hldse:current/hldse:ldse-meta/hldse:document/@uri
};

declare function get-comment-root($file as node()) as xs:string {
    json:keyValue("root", getRootString(get-comment-uri-string($file)) )
};

declare function get-comment-preview-locale(
    $file as node()
) as xs:string {
     json:keyValue("previewLocale", util:split-locale-param($file/hldse:current/hldse:ldse-meta/hldse:document/@locale))
};

declare function getCommentPreviewUrl(
    $file as node()
) as xs:string {
    json:keyEscapedValue("previewUrl", core:build-url($file/hldse:current/hldse:ldse-meta/hldse:document/@uri, ($file/hldse:current/hldse:ldse-meta/hldse:document/@locale, "eng")[1], ()) )
};

declare function getStatus(
    $file as node()
) as xs:string {
    let $status as xs:string := ldsemeta:static-status($file)
    return (
        json:keyValue("status", $status)
    )
};

declare function get-sensitive-status( $file as node() ) as xs:string {
    let $status as xs:string? := ldsemeta:get-sensitive($file)/@status
    let $uri as xs:string? := ldsemeta:get-document-uri($file)
    let $sensitive-page as xs:string? := 
        for $sensitive-uri as xs:string in $settings:sensitive-uris/ldse:sensitive-uri
        where $sensitive-uri = $uri
        return (
            "yes"
        )
    return (
        json:keyValue("sensitive", ($status, $sensitive-page)[1])
    )
};

declare function get-data-post-status($file as node()) as xs:string
{
	let $status as xs:string := getStatus($file)
	let $status as xs:string :=
		if(fn:matches($status, "submitted") and fn:not(ac:has-permission("ldse:edit-any-submission", "", "")))
		then "view"
		else "edit"
	return json:keyValue("dataPostStatus", $status)
};

declare function get-submission-submitted-date($file as node()) as xs:string?
{
	json:keyValue("submissionSubmittedDate", content-search:formatDate(xs:string(ldsemeta:get-submission-date($file))))
};

declare function get-submission-created-date($file as node()) as xs:string?
{
	json:keyValue("submissionCreatedDate", content-search:formatDate(xs:string(ldsemeta:get-created-date($file)/@date)))
};

declare function getDefault(
    $file as node()
) as xs:string* {
    get-options($file),
    get-page($file),
    get-file-type($file),
    get-preview-locale($file),
    getRoot($file),
    getId($file),
    getUri($file),
    getLocale($file),
    getWord($file),
    getType($file),
    get-file-type($file),
    get-is-custompage($file),
    getTitle($file),
    get-data-post-status($file),
    getPreviewUrl($file),
    getSite($file),
    get-sensitive-status($file)
};

declare function build-preview-content-json(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
    return (
        json:obj((
            getDefault($file),
            get-date-created($file),
            get-creator($file),
		    json:keyValue("pageNum", $pageNum)
        ))
    )    
};

declare function build-modified-content-json(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
    return (
        json:obj((
            getDefault($file),
            get-date-modified($file),
            get-modifier($file),
		    json:keyValue("pageNum", $pageNum)
        ))
    )    
};

declare function build-published-content-json(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
    return (
        json:obj((
            getDefault($file),
            getPublished($file),
            getPublisher($file),
		    json:keyValue("pageNum", $pageNum)
        ))
    )    
};

declare function build-unpublished-content-json(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
    return (
        json:obj((
            getDefault($file),
            get-unpublished-date($file),
            get-unpublished-user($file),
		    json:keyValue("pageNum", $pageNum)
       ))
    )   
};

declare function build-published-json(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
    return (
        json:obj((
            getDefault($file),
            getPublished($file),
            getPublisher($file),
            getCid($file),
		    json:keyValue("pageNum", $pageNum)    
        ))
    )    
};

declare function build-scheduled-publish-json(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
    return (
        json:obj((
            getDefault($file),
            get-scheduled-publish($file),
            get-scheduled-publisher($file),
		    json:keyValue("pageNum", $pageNum)
        ))
    )    
};

declare function build-scheduled-unpublish-json(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
	
    return (
        json:obj((
            getDefault($file),
            get-scheduled-unpublish($file),
            get-scheduled-unpublisher($file),
		    json:keyValue("pageNum", $pageNum)
        ))
    )    
};

declare function build-comment-json(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string {
    let $file as element() := fn:root($doc)/element()
    let $comment as element()? := ($file/hldse:events/hldse:comment)[1]
	let $pageNum as xs:string := getPageNum($options)
    return ( 
        json:obj((
            get-comment-locale($file),
            get-commenter($comment),
            get-comment-root($file),
            get-comment-date($comment),
            get-comment-type($file), 
            get-comment-id($file),
            get-comment-title($file),
            get-comment-options($file),
            get-comment($comment),
            get-comment-uri($file),
            getCommentPreviewUrl($file),
            get-comment-preview-locale($file),
		    get-file-type($file),
		    get-is-custompage($file),
		    json:keyValue("pageNum", $pageNum)
        ))
    )    
};

declare function default-json(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string? {
    let $file as element() := fn:root($doc)/element()
    return ()
};

declare function all-default-json(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string? {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
    return (
        json:obj((
            getStatus($file),
            getDefault($file),
            getLanguage($file),
			json:keyValue("pageNum", $pageNum)
        ))
    )
};

declare function json-all(
    $doc as node(), 
    $cts-query as schema-element(cts:query)?, 
    $options as item()*
)  as xs:string {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
    return (
        json:obj((
            getDefault($file),
            getLanguage($file),
            getCid($file),
            getPublished($file),
            getStatus($file),
            getPublisher($file),
            getApprover($file),
            getWord($file),
            get-creator($file),
		    json:keyValue("pageNum", $pageNum)
        ))
    )
};

declare function build-submission-submitted($doc as node(), $cts-query as schema-element(cts:query)?, $options as item()*)  as xs:string? {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
    return
        json:obj((
		    getDefault($file),
			get-submission-submitted-date($file),
			json:keyValue("pageNum", $pageNum)
        ))
};

declare function build-submission-created($doc as node(), $cts-query as schema-element(cts:query)?, $options as item()*)  as xs:string? {
    let $file as element() := fn:root($doc)/element()
	let $pageNum as xs:string := getPageNum($options)
    return
        json:obj((
		    getDefault($file),
			get-submission-created-date($file),
			json:keyValue("pageNum", $pageNum)
        ))
};
