xquery version "1.0-ml";

import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at '../modules/functions.xqy';

declare variable $status as xs:string? := xdmp:get-request-field("status");
declare variable $action as xs:string? := xdmp:get-request-field("action");
declare variable $locale as xs:string? := xdmp:get-request-field("lang");
declare variable $site as xs:string? := xdmp:get-request-field("site");
declare variable $id as xs:string? := xdmp:get-request-field("id");

let $mark-ready as item()* := af:mark-all-items($status, $locale, $action, $site, $id)
return (
    xdmp:from-json(
        object-node {
            'translation': 'ready - ' || fn:format-dateTime(fn:current-dateTime(), '[D] [MNn,*-3] [Y]'),
            'success': fn:true(),
            'marked': $mark-ready/@marked/fn:string()
        }
    )
)