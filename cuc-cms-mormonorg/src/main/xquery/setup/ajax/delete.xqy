xquery version "1.0-ml";
import module namespace deleteSite="http://lds.org/code/services/lds-publisher/delete-site" at "/setup/modules/delete-site.xqy";
import module namespace ldsesUser="http://lds.org/code/lds-edit-services/user" at "/modules/userManagement.xqy";
declare option xdmp:mapping "true";
let $login as xs:boolean := ldsesUser:login($deleteSite:serviceSite)
return 
deleteSite:delete(),
xdmp:redirect-response("../admin")