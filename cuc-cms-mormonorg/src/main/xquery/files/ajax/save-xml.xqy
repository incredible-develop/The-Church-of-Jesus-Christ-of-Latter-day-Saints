xquery version "1.0-ml";

import module namespace ff = "http://lds.org/code/shared/lds-edit/file-functions" at "../modules/file-functions.xqy";

declare variable $uri as xs:string := xdmp:get-request-field('uri');
declare variable $xml as xs:string := xdmp:get-request-field('newXml');
declare variable $mode as xs:string? := xdmp:get-request-field('mode');

ff:save-xml($uri, $xml, $mode)