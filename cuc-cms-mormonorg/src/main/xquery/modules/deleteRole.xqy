xquery version "1.0-ml";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare option xdmp:mapping "false";
declare variable $role as xs:string external;
sec:remove-role($role)
