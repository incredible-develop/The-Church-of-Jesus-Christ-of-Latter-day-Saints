xquery version "1.0-ml";

import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "../modules/functions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace faster-json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";

declare variable $uri as xs:string? := util:escape-chars(xdmp:get-request-field('uri'))[. != ""];
declare variable $form as xs:string := util:escape-chars(xdmp:get-request-field('form'));
declare variable $id as xs:string := util:escape-chars(xdmp:get-request-field('id'));
declare variable $site as xs:string := util:escape-chars(xdmp:get-request-field('site'));
declare variable $archiveStatus as xs:string := util:escape-chars(xdmp:get-request-field('archiveStatus'));

let $request-path as xs:string := xdmp:get-request-header("referer")
let $save as item()* := 
    if ( $archiveStatus = 'archive' ) then (
        af:archive-content($uri, $form, $id, $site, $archiveStatus)
    ) else if ( $archiveStatus = "unarchive" ) then (
        af:unarchive-content($uri, $form, $id, $site, $archiveStatus)
    ) else ()

let $json := 
    object-node {
        "success": "true",
        "redirect": fn:string($request-path)
    }
return (
    xdmp:from-json($json)
)
