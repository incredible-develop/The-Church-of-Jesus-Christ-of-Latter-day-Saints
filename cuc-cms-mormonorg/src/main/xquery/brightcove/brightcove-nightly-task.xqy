xquery version "1.0-ml";

import module namespace brightcove = "http://lds.org/code/shared/lds-edit/brightcove/brightcove-service" at "brightcove-service.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace batch = "http://lds.org/code/shared/common/process/batch-processing" at "/shared/common/process/batch/batchFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";
declare variable $OPTIONS as element(batch:options)? :=
    <options xmlns="http://lds.org/code/shared/common/process/batch-processing">
        <chunk-size>1</chunk-size>
    </options>;
    
declare variable $docs as item()* := 
    cts:uris('/', "any",
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query( xs:QName('ldse:brightcove-service'), xs:QName('status'), "retry", "exact")
        ))
    );

let $set-mode as item()* := core:set-mode($settings:brightcove-mode)

return (
    batch:initiate($docs, xdmp:function(xs:QName("brightcove:nightly-task")), $OPTIONS),
    fn:count($docs), $docs
)
