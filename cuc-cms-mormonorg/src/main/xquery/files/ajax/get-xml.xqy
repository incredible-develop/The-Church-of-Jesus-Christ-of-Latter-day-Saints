xquery version "1.0-ml";

import module namespace ff = "http://lds.org/code/shared/lds-edit/file-functions" at "../modules/file-functions.xqy";

declare variable $uri as xs:string := xdmp:get-request-field('uri')[. ne ""];

xdmp:set-response-content-type("html"),
ff:view-edit-xml($uri)
