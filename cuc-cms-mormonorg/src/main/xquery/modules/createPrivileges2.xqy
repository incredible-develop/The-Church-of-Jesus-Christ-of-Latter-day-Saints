xquery version "1.0-ml";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare variable $role as xs:string external;
declare variable $privileges as element(privs) external;
declare option xdmp:mapping "false";
let $newPrivileges as xs:string* := for $i as element() in $privileges/* return string($i)
let $existingPrivileges as xs:string* := for $i as element() in sec:role-privileges($role) return string($i/sec:action)
let $privilegesToRemove as xs:string* := $existingPrivileges[not(. = $newPrivileges)]

return (
    for $priv as element() in $privileges/*
    let $type as xs:string := ($priv/@type, "execute")[1]
    return sec:privilege-add-roles(string($priv), $type, $role)) 
   