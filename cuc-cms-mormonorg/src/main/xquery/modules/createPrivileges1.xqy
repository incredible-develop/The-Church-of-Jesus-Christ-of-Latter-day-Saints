xquery version "1.0-ml";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare variable $privileges as element(privs) external;
declare option xdmp:mapping "false";
for $priv as element() in $privileges/*
let $privExists as xs:boolean := try {
        exists(sec:get-privilege(string($priv), "uri"))
    }
    catch ($e) {
        false()
    }
where $priv/@type = "uri" and not($privExists)
return if($privExists) then () 
    else sec:create-privilege(string($priv/@name), string($priv), "uri", ())
