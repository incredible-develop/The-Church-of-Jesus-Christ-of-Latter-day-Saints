xquery version "1.0-ml";

import module namespace report = "http://lds.org/code/shared/lds-edit/reportFunctions" at "../modules/reportsFunctions.xqy";
import module namespace batch = "http://lds.org/code/shared/common/process/batch-processing" at "/shared/common/process/batch/batchFunctions.xqy";

declare option xdmp:mapping "true";

declare variable $report as element(report)? := report:getReport('web-content');

declare variable $OPTIONS as element(batch:options)? :=
    <options xmlns="http://lds.org/code/shared/common/process/batch-processing">
        <chunk-size>1</chunk-size>
    </options>;
    
declare function local:generateReport($breakdown as xs:string) as element(generated-report) {
    report:getGeneratedReport($report, $breakdown)
};

    batch:initiate($report/hierarchies/hierarchy/xs:string(.), xdmp:function(xs:QName("local:generateReport")), $OPTIONS),
    fn:concat(fn:count($report/hierarchies/hierarchy), ' reports started.')
