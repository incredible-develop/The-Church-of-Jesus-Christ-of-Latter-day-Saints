xquery version "1.0-ml";

import module namespace ff = "http://lds.org/code/shared/lds-edit/file-functions" at "../modules/file-functions.xqy";

declare variable $uri as xs:string := xdmp:get-request-field('uri');
declare variable $locale as xs:string := xdmp:get-request-field('locale');
declare variable $id as xs:string := xdmp:get-request-field('id');
declare variable $directory as xs:string := xdmp:get-request-field('directory');
declare variable $root-element as xs:string? := xdmp:get-request-field('root-element')[. != ""];
declare variable $id-qname as xs:string? := xdmp:get-request-field('id-qname')[. != ""];
declare variable $path as xs:string := xdmp:get-request-field('path');
declare variable $mode as xs:string? := xdmp:get-request-field('mode')[. != ""];

ff:check-file($id, $locale, $uri, $directory, $root-element, $id-qname, $path, $mode)
