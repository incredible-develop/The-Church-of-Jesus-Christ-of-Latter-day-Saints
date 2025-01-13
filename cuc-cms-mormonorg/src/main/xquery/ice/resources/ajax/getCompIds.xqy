xquery version "1.0-ml";

import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at '../../../../content-admin/modules/functions.xqy';
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace rice = "http://lds.org/code/shared/lds-edit/riceFunctions" at "../../../string-manager/modules/stringFunctions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare boundary-space preserve;
declare option xdmp:mapping "true";
declare option xdmp:update "true";

(: pass variables :)
declare variable $locale as xs:string := xdmp:get-request-field("locale");
declare variable $site as xs:string := xdmp:get-request-field("site");
declare variable $id as xs:string? := xdmp:get-request-field("id");
declare variable $batchid as xs:string? := xdmp:get-request-field("batchid");
declare variable $additional as xs:string? := xdmp:get-request-field("additional");
declare variable $ids as xs:string* := xdmp:get-request-field("ids[]");

(: List of components and its info, including ids, required by Send Form to Translation :)
xdmp:set-response-content-type("application/json"),
let $idList as xs:string* :=
    if (fn:not(fn:exists($additional))) then
    (: normal behavior: return info of component and its dependencies by using only its id :)
        if (fn:string-length($batchid) <= 0 and fn:string-length($id) > 0) then
            af:findAllFilesUsedByPageSettings($id, $locale)
        else if (fn:string-length($batchid) > 0) then
            cts:search(/batch-submit, cts:element-attribute-value-query(xs:QName('batch-submit'),xs:QName('id'), $batchid))/file/fn:string()
        else ( )
    (: extended behavior: return info of components to display in Send Form by using a explicit list of requested ids :)
    else ( $ids )
let $getInfo :=
    for $idKey in $idList
    let $doc as element()? :=
        cts:search(fn:collection(),
            cts:and-query((
                cts:directory-query('/preview/', 'infinity'),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $idKey, 'exact'),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale, 'exact'),
                cts:or-query((
                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
                cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $site, 'exact')
                ))
            ))
        )/node()
    let $type as xs:string? :=
        if (name($doc) eq 'resources') then
            'resources'
        else
            name($doc)

    let $uri as xs:string? :=
        if ($type eq 'resources') then
            $doc/name/fn:string()
        else $doc/ldse:ldse-meta/ldse:document/@uri/fn:string()

    return
    (: pack the info and sent it back :)
        if ($doc) then
            object-node {
                'id': $doc/ldse:ldse-meta/ldse:document/@id/fn:string(),
                'type': $type,
                'uri': $uri,
                'title': $doc/ldse:ldse-meta/ldse:document/@title/fn:string(),
                'words': $doc/ldse:ldse-meta/ldse:document/@words/fn:string(),
                'tgp': $doc/ldse:ldse-meta/ldse:document/@tgp/fn:string()
            }
        else ( )
return array-node{$getInfo}
