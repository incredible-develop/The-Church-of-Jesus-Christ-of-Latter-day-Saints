(:
    This is an endpoint for LDS Publisher Registration Services
:)
xquery version "1.0-ml";
import module namespace ldses-param = "http://lds.org/code/services/lds-edit/parameters" at "/v1/modules/params.xqy";
import module namespace create-site = "http://lds.org/code/services/lds-publisher/create-site" at "/setup/modules/create-site.xqy";
import module namespace common = "http://marklogic.com/lds-edit-services/common" at "/v1/modules/common.xqy";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "false";
let $isPost as xs:boolean := $ldses-param:requestMethod = "POST"
return
    if($isPost) then (
        let $username as xs:string? := xdmp:get-request-field("username")
        let $person-name as xs:string? := xdmp:get-request-field("person-name")
        let $person-email as xs:string? := xdmp:get-request-field("person-email")
        let $complete-post as xs:boolean := fn:exists($username) and  
            fn:exists($person-name) and fn:exists($person-email)
        return 
            if($complete-post) then (
                create-site:register($username, $person-name, $person-email)
            ) else (
                common:error("lds-edit-services:Missing username, name, or email", 
                    "Required", $ldses-param:outputFormatIsJSON)
        )
    ) else (
        common:error("lds-edit-services:More Than On Bundle Name", 
           "Please include only one bundle name for an insert (e.g. 'rice?bundle=test')", $ldses-param:outputFormatIsJSON)
    )