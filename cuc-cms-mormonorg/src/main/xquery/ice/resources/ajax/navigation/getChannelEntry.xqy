xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";

declare variable $host as xs:string := $util:host;

declare variable $country as xs:string := util:escape-chars(xdmp:get-request-field("country", ""));
declare variable $preLang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));

declare variable $lang as xs:string := if ($country ne '') then (fn:concat($preLang,'-',$country)) else ($preLang);
                  
declare variable $request as xs:string := util:escape-chars(xdmp:get-request-field("request", ""));                  
declare variable $index as xs:string := util:escape-chars(xdmp:get-request-field("index", ""));
declare variable $count as xs:string := util:escape-chars(xdmp:get-request-field("count", ""));

xdmp:set-response-content-type( "text/html" ),
if ($request eq 'channel') then (
    ice:buildChannelEntry((), $count, $index)
) else if ($request eq 'subchannel') then (
    ice:buildChannelsList((), $index)
) else ()
