xquery version "1.0-ml";
module namespace deleteSite = "http://lds.org/code/services/lds-publisher/delete-site";
import module namespace ldsesUser="http://lds.org/code/lds-edit-services/user" at "/modules/userManagement.xqy";
declare option xdmp:mapping "true";
declare variable $serviceSite as xs:string? := xdmp:get-request-field("site");
declare function delete() as empty-sequence() {
    if(fn:exists($serviceSite)) then (
            ldsesUser:deleteConfigFiles($serviceSite)
    ) else fn:error(xs:QName("Error"),"Site does not exist")
};