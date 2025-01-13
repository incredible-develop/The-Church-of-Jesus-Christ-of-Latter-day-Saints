xquery version "1.0-ml";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare option xdmp:mapping "false";
declare variable $site as xs:string external;
let $uri as xs:string := fn:concat("/preview/", $site, "/")
return
    sec:remove-privilege($uri, "uri");
xquery version "1.0-ml";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare option xdmp:mapping "false";
declare variable $site as xs:string external;
let $uri2 as xs:string := fn:concat("/published/", $site, "/")
return
    sec:remove-privilege($uri2, "uri");
