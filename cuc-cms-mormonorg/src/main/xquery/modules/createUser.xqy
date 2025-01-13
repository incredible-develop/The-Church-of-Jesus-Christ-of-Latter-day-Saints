xquery version "1.0-ml";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare option xdmp:mapping "false";
declare variable $userName as xs:string external;
declare variable $userPassword as xs:string external;
declare variable $role as xs:string* external;
let $exists as xs:boolean :=
    sec:user-exists($userName)
let $set as xs:unsignedLong :=
    if($exists) then
        0
    else
       sec:create-user($userName, "", $userPassword, $role, (), ())
return()