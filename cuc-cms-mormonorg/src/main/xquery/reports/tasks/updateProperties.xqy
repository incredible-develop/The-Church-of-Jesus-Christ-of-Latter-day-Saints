xquery version "1.0-ml";

import module namespace report = "http://lds.org/code/shared/lds-edit/reportFunctions" at "../modules/reportsFunctions.xqy";
import module namespace batch = "http://lds.org/code/shared/common/process/batch-processing" at "/shared/common/process/batch/batchFunctions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare option xdmp:mapping "true";

declare variable $OPTIONS as element(batch:options)? :=
    <options xmlns="http://lds.org/code/shared/common/process/batch-processing">
        <chunk-size>2000</chunk-size>
    </options>;

let $site as xs:string := $core:site
let $report as element(report)? := report:getReport('web-content')
let $QNames as xs:QName*:= 
    for $QName as xs:string in report:getQNames($report)
    return (xs:QName($QName))
    
let $uris as xs:string* := 
    cts:uri-match('*.xml', ("document"),
        cts:and-query((
            if ($settings:manage-shared) then (
                cts:directory-query(
                    (fn:concat('/preview/', $site, '/content/'),
                     fn:concat('/published/', $site, '/content/'),
                     '/preview/shared/', '/published/shared/'),
                     'infinity')
            ) else (
                cts:directory-query(
                    (fn:concat('/preview/', $site, '/content/'),
                     fn:concat('/published/', $site, '/content/')),
                     'infinity')
            ),
            cts:element-query($QNames, cts:and-query(()) ),
            cts:or-query((
                cts:properties-query(
                    cts:element-range-query(fn:QName("http://marklogic.com/xdmp/property", "last-modified"),">=", current-dateTime() - xs:dayTimeDuration("PT22H"))
                ),
                cts:not-query(
                    cts:properties-query(
                            cts:element-query(fn:QName("http://marklogic.com/xdmp/property", "words"), cts:and-query(()) )
                    )
                )
            ))
        ))
    )
    
let $batch as empty-sequence() := batch:initiate($uris, xdmp:function(xs:QName("report:addProperties")), $OPTIONS)

return fn:count($uris)
