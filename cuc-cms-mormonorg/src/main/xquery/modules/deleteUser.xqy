xquery version "1.0-ml";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare option xdmp:mapping "false";
declare variable $user as xs:string external;
sec:remove-user($user)