xquery version "1.0-ml";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare option xdmp:mapping "false";
declare variable $role as xs:string external;
declare variable $intendedPermissions as element(perms) external;

sec:role-set-default-permissions($role, 
   for $i as element() in $intendedPermissions/*
   return xdmp:permission(string($i/role), string($i/type))
)