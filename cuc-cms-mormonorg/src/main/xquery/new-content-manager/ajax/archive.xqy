xquery version "1.0-ml";
import module namespace tArchive = "http://lds.org/code/shared/lds-edit/archiveFunctions" at "../../translation/archives/modules/archiveFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare option xdmp:mapping "true";

xdmp:set-response-content-type("application/json"),
(:Calls the update expected return date function:)
if($tArchive:has-edit-permission) then (
    let $dateString as xs:string? := xdmp:get-request-field("date")[. ne '']
    let $date as xs:dateTime? := 
        if(fn:exists($dateString)) then (
            xs:dateTime(fn:concat($dateString,"T00:00:00"))
       ) else ()
    return
        tArchive:updateProjectedReturn(
            xdmp:get-request-field("uri")[. ne ''],
            $date
        )
) else (
     let $errorMsg as xs:string:="Sorry, You don't have permission" 
     let $errorTitle as xs:string:= "Access Denied!"
     return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
)
