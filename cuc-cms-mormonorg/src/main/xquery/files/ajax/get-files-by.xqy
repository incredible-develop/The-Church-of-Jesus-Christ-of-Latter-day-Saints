xquery version "1.0-ml";

import module namespace ff = "http://lds.org/code/shared/lds-edit/file-functions" at "../modules/file-functions.xqy";

declare variable $id as xs:string? := xdmp:get-request-field('id')[. ne ""];
declare variable $uri as xs:string? := xdmp:get-request-field('uri')[. ne ""];
declare variable $locale as xs:string? := xdmp:get-request-field('locale')[. ne ""];

xdmp:set-response-content-type("html"),
ff:get-duplicate-files($id, $uri, $locale)
