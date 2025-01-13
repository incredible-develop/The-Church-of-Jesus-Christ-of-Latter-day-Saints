xquery version "1.0-ml";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare option xdmp:mapping "false";
declare variable $role as xs:string external;
declare variable $description as xs:string external;

try {
    sec:get-role-ids($role)
}
catch ($e) {
    sec:create-role($role, $description, (), (), ())
}