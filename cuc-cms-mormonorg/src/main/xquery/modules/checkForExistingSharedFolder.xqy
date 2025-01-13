xquery version "1.0-ml";
declare variable $site-name as xs:string external;
declare option xdmp:mapping "false";
let $services-uri as xs:string := fn:concat(fn:lower-case($site-name), "/") 
let $uri as xs:string := fn:concat("/", 
	$services-uri)
return fn:starts-with(cts:uris($services-uri,"limit=1"),$services-uri) or
        fn:starts-with(cts:uris($uri,"limit=1"),$uri)