xquery version "1.0-ml";
import module namespace sec="http://marklogic.com/xdmp/security" at 
    "/MarkLogic/security.xqy";
declare option xdmp:mapping "false";
declare variable $userName as xs:string external;
declare variable $userPassword as xs:string external;
    sec:user-set-password($userName, $userPassword)
