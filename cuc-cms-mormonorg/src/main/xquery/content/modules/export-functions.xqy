xquery version "1.0-ml";

module namespace export-functions = "http://lds.org/code/shared/lds-edit/content/export"; 

import module namespace content-functions = "http://lds.org/code/shared/lds-edit/content/content-functions" at "content-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace content-workflow = "http://lds.org/code/shared/lds-edit/content/content-workflow" at "content-workflow.xqy";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace hldse = "http://lds.org/code/lds-edit/history";

declare option xdmp:mapping "true";
declare variable $host as xs:string := $util:host;

declare function getDocsByIds($ids as xs:string*)as element()*{
   cts:search(/*,
        cts:and-query((
            core:get-filter-query(),         
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $ids, ("exact"))
        ))
    )
};

declare function get-history-doc($ids as xs:string*) as element()* {
   cts:search(/*,
        cts:and-query((
            core:get-filter-query(),         
            cts:element-attribute-value-query(xs:QName('hldse:document'), xs:QName('id'), $ids, ("exact"))
        ))
    )
};

declare function buildExportTable($files as element()*, $status as xs:string?) as element(table) {
    let $tab as element(table) := <table>{
        buildExportRows($files, $status)
    }</table>
    return $tab
};

declare function buildExportRows($files as element()*, $status as xs:string?) as element(row)* {
    for $row as element(row) in buildExportRow($files, $status)
    
    order by $row/CONTEXT
    return ($row)
};

declare function buildExportRow($file as element(), $status as xs:string?) as element(row) {
    let $uri as xs:string? := if ( $status = "comments" ) then ( ldsemeta:get-history-document-uri($file) ) else ( ldsemeta:get-document-uri($file) )
    let $type as xs:string := if ( $status = "comments" ) then ( ldsemeta:get-history-document-type($file) ) else ( content-functions:getFileType($file) )
    let $id as xs:string? := ldsemeta:get-document-id($file)
    let $publisher as xs:string? := ldsemeta:get-publish-date($file)/@username
    let $publish-date as xs:string? := fn:format-dateTime(ldsemeta:get-publish-date($file)/@date, "[Y0001]-[M01]-[D01]", 'eng', (), ())
    let $creator as xs:string := ldsemeta:get-created-date($file)/@username
    let $created-date as xs:string? := fn:format-dateTime(ldsemeta:get-created-date($file)/@date, "[Y0001]-[M01]-[D01]", 'eng', (), ())
    let $unpublisher as xs:string? := ldsemeta:get-unpublish-date($file)/@username
    let $unpublish-date as xs:string? := fn:format-dateTime(ldsemeta:get-unpublish-date($file)/@date, "[Y0001]-[M01]-[D01]", 'eng', (), ())
    let $comment as element()? := $file/hldse:events/hldse:comment[1]
    return (
        <row>
            <TYPE>{ $type }</TYPE>
            <TITLE>{if ( $status = "comments" ) then ( ldsemeta:get-history-document-title($file) ) else ( ldsemeta:get-document-title($file) )}</TITLE>
            <ROOTCONTEXT>{content-functions:getRootContext($uri)}</ROOTCONTEXT>
            <LINK>{ fn:concat($host, $uri, '?lang=eng') }</LINK>,
            {if ($status ne "") then (
                if ($status eq "preview") then (
                    <CREATED-BY>{ $creator }</CREATED-BY>,
                    <CREATED>{ $created-date }</CREATED>
                ) else if ($status eq "publish") then (
                    <PUBLISHED-BY>{ $publisher }</PUBLISHED-BY>,
                    <PUBLISHED>{ $publish-date }</PUBLISHED>
                ) else if ( $status = "comments" ) then (
                    <COMMENT>{$comment/node()}</COMMENT>,
                    <COMMENTED-BY>{xs:string($comment/@username)}</COMMENTED-BY>,
                    <COMMENT-DATE>{xs:string($comment/@date)}</COMMENT-DATE>
                ) else (
                    <UNPUBLISHED-BY>{ $unpublisher }</UNPUBLISHED-BY>,
                    <UNPUBLISHED>{ $unpublish-date }</UNPUBLISHED>
                )
            ) else (
                    <CREATED-BY>{ $creator }</CREATED-BY>,
                    <CREATED>{ $created-date }</CREATED>,
                    <PUBLISHED-BY>{ $publisher }</PUBLISHED-BY>,
                    <PUBLISHED>{ $publish-date }</PUBLISHED>,
                    <UNPUBLISHED-BY>{ $unpublisher }</UNPUBLISHED-BY>,
                    <UNPUBLISHED>{ $unpublish-date }</UNPUBLISHED>
            )},
            <WORDS>{ ldsemeta:get-document-words($file) }</WORDS>
            <TGP>{ fn:format-number(ldsemeta:get-document-tgp($file), "0.00") }</TGP>
        </row>
    )
};
