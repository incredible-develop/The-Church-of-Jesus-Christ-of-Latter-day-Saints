xquery version "1.0-ml";

declare namespace func = "http://lds.org/code/shared/lds-edit/function-apply";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";

(:declare option xdmp:update "true";:)
declare option xdmp:mapping "false";


declare variable $params as map:map external;


declare variable $fn as xdmp:function := map:get($params, "fn");
declare variable $mode as xs:string := map:get($params, "mode");
declare variable $port as xs:integer?  := map:get($params, "port");
declare variable $c as xs:integer  := map:get($params, "c");
declare variable $param1 as item()* := map:get($params, "p1");
declare variable $param2 as item()* := map:get($params, "p2");
declare variable $param3 as item()* := map:get($params, "p3");
declare variable $param4 as item()* := map:get($params, "p4");
declare variable $param5 as item()* := map:get($params, "p5");
declare variable $param6 as item()* := map:get($params, "p6");
declare variable $param7 as item()* := map:get($params, "p7");
declare variable $param8 as item()* := map:get($params, "p8");
declare variable $param9 as item()* := map:get($params, "p9");

let $set-mode as item()? := core:set-mode($mode)
let $set-port as item()? := core:set-port($port)
return (
    (: Ordered for optimzation :)
         if ($c = 4) then xdmp:apply($fn, $param1, $param2, $param3, $param4)
    else if ($c = 3) then xdmp:apply($fn, $param1, $param2, $param3)
    else if ($c = 2) then xdmp:apply($fn, $param1, $param2)
    else if ($c = 1) then xdmp:apply($fn, $param1)
    else if ($c = 0) then xdmp:apply($fn)
    else if ($c = 5) then xdmp:apply($fn, $param1, $param2, $param3, $param4, $param5)
    else if ($c = 6) then xdmp:apply($fn, $param1, $param2, $param3, $param4, $param5, $param6)
    else if ($c = 7) then xdmp:apply($fn, $param1, $param2, $param3, $param4, $param5, $param6, $param7)
    else if ($c = 8) then xdmp:apply($fn, $param1, $param2, $param3, $param4, $param5, $param6, $param7, $param8)
    else if ($c = 9) then xdmp:apply($fn, $param1, $param2, $param3, $param4, $param5, $param6, $param7, $param8, $param9)
    else xdmp:apply($fn)
)
