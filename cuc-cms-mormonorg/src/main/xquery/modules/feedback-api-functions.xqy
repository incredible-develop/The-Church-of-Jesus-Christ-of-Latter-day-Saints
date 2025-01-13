xquery version "1.0-ml";

module namespace faf = 'http://lds.org/code/modules/feedback-api-functions';

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace cache-control = "http://lds.org/code/modules/cache-control-functions" at "../../modules/cacheControlFunctions.xqy";


declare function faf:getFeedbackItemsMap(
    $returnMap as map:map,
    $feedbackItem as element()
) {
    let $currentProcessDate := $feedbackItem/@processDate
    let $importRequestId := $feedbackItem/@importRequestId
    let $importRequestStatus := $feedbackItem/@importRequestStatus
    let $_putMap := map:put($returnMap, $feedbackItem/@id/xs:string(.), map:map())
    let $feedbackMap := map:get($returnMap, $feedbackItem/@id/xs:string(.))
    let $_feedbackMapPut := (
        map:put($feedbackMap, "feedbackItemId", $feedbackItem/@id/xs:string(.)),
        if(fn:exists($currentProcessDate)) then (
            map:put($feedbackMap, "processDate", $currentProcessDate)
        ) else (),
        if(fn:exists($importRequestId)) then (
            map:put($feedbackMap, "importRequestId", $importRequestId)
        ) else (),
        if(fn:exists($importRequestStatus)) then (
            map:put($feedbackMap, "importRequestStatus", $importRequestStatus)
        ) else (),
        map:put($feedbackMap, "data", $feedbackItem/text()/xdmp:from-json-string(.))
    )
    return $feedbackMap
};


declare function faf:updateFeedbackItem(
    $feedbackItemObj as object-node()
) {
    let $feedbackItemId as xs:string := $feedbackItemObj/feedbackItemId/xs:string(.)
    let $feedbackItemDB :=
        cts:search(/feedbackItem, cts:and-query((
            cts:element-attribute-value-query(xs:QName("feedbackItem"), xs:QName("id"), $feedbackItemId, "exact")
        )))
    let $processDateAttribute :=
        if ( fn:exists($feedbackItemObj/processDate) ) then (
            attribute processDate { $feedbackItemObj/processDate }
        ) else ()
    let $importRequestIdAttribute :=
        if( fn:exists($feedbackItemObj/importRequestId) ) then (
            attribute importRequestId { $feedbackItemObj/importRequestId }
        ) else ()
    let $importRequestStatusAttribute :=
        if( fn:exists($feedbackItemObj/importRequestStatus) ) then (
            attribute importRequestStatus { $feedbackItemObj/importRequestStatus }
        ) else ()

    let $_update := (
        if( fn:exists($feedbackItemObj/data) ) then (
            let $updatedItem :=
                element feedbackItem {
                    $feedbackItemDB/@* except ($feedbackItemDB/@processDate,  $feedbackItemDB/@importRequestId, $feedbackItemDB/@importRequestStatus),
                    $processDateAttribute,
                    $importRequestIdAttribute,
                    $importRequestStatusAttribute,
                    xdmp:to-json-string($feedbackItemObj/data)
                }
            return (
                xdmp:node-replace($feedbackItemDB, $updatedItem)
            )
        ) else(
            if ( fn:exists($feedbackItemObj/processDate) ) then (
                if ( $feedbackItemDB/@processDate ) then (
                    xdmp:node-replace($feedbackItemDB/@processDate, $processDateAttribute)
                ) else ( xdmp:node-insert-child($feedbackItemDB, $processDateAttribute) )
            ) else (
                xdmp:node-delete($feedbackItemDB/@processDate)
            ),
            if ( fn:exists($feedbackItemObj/importRequestId) ) then (
                if ( $feedbackItemDB/@importRequestId ) then (
                    xdmp:node-replace($feedbackItemDB/@importRequestId, $importRequestIdAttribute)
                ) else ( xdmp:node-insert-child($feedbackItemDB, $importRequestIdAttribute) )
            ) else (
                xdmp:node-delete($feedbackItemDB/@importRequestId)
            ),
            if ( fn:exists($feedbackItemObj/importRequestStatus) ) then (
                if ( $feedbackItemDB/@importRequestStatus ) then (
                    xdmp:node-replace($feedbackItemDB/@importRequestStatus, $importRequestStatusAttribute)
                ) else ( xdmp:node-insert-child($feedbackItemDB, $importRequestStatusAttribute) )
            ) else (
                xdmp:node-delete($feedbackItemDB/@importRequestStatus)
            )
        )
    )
    return $feedbackItemObj
};

declare function faf:recordFeedbackItem(
    $feedbackItemObj as object-node()
) {
    let $requestData := xdmp:to-json-string($feedbackItemObj/data)
    let $feedbackItemId as xs:string := $feedbackItemObj/feedbackItemId/xs:string(.)
    let $processDate := $feedbackItemObj/processDate
    let $_savedFeedbackItem := xdmp:document-insert("/preview/cms/content/feedback-queue/" || $feedbackItemId || ".xml",
        <feedbackItem id="{ $feedbackItemId }">{ if(fn:exists($processDate)) then(
            attribute processDate { $processDate }) else(),
        $requestData }
        </feedbackItem>)
    return $feedbackItemObj
};

declare function faf:getFeedback() {
    let $tempMap := map:map()
    let $retrieveInProcessItems := xdmp:get-request-field("inProcess")
    let $hasImportRequestId := xdmp:get-request-field("hasImportRequestId")
    let $resultLimit := xs:integer(xdmp:get-request-field("limit", "500"))
    let $feedbackItems := cts:search(/feedbackItem, ())
    return (
        let $_feedbackMap :=
            if($retrieveInProcessItems = "true" and (fn:not($hasImportRequestId) or fn:not($hasImportRequestId = "true"))) then (
                let $inProcessNodes := $feedbackItems[fn:exists(@processDate)][1 to $resultLimit]
                return faf:getFeedbackItemsMap($tempMap, $inProcessNodes)
            ) else if ($hasImportRequestId = "true" and (fn:not($retrieveInProcessItems) or fn:not($retrieveInProcessItems = "true"))) then (
                let $hasImportRequestIdNodes := $feedbackItems[fn:exists(@importRequestId)][1 to $resultLimit]
                return faf:getFeedbackItemsMap($tempMap, $hasImportRequestIdNodes)
            ) else if ($retrieveInProcessItems = "true" and $hasImportRequestId = "true") then (
                let $inProcessNodesWithRequestImport := $feedbackItems[fn:exists(@processDate)][fn:exists(@importRequestId)][1 to $resultLimit]
                return faf:getFeedbackItemsMap($tempMap, $inProcessNodesWithRequestImport)
            )else (
                let $notProcessedNodes := $feedbackItems[fn:empty(@processDate)][fn:empty(@importRequestId)][1 to $resultLimit]
                return faf:getFeedbackItemsMap($tempMap, $notProcessedNodes)
            )
        return (
            array-node {
                for $key in map:keys($tempMap)
                return map:get($tempMap, $key)
            }
        )
    )
};
