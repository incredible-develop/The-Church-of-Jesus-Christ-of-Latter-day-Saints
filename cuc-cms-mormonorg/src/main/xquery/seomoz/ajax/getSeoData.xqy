xquery version "1.0-ml";
 
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace seomoz = "http://lds.org/code/shared/lds-edit/seo-functions" at "../modules/seoModule.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $targetURL as xs:string := (xdmp:get-request-field("targetURL"),"")[1];

xdmp:set-response-content-type( "text/json" ),
let $mapData as map:map := seomoz:getMapData($targetURL)
return xdmp:to-json-string($mapData)
