xquery version "1.0-ml";

module namespace errorHandling = "http://lds.org/code/modules/errorHandling";

import module namespace rest = "http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";

declare function errorHandling:handleErrors(
    $rule as element(),
    $error as map:map
) as map:map? {
    try {
        rest:process-request($rule)
    } catch ( $err ) {
        map:put($error, "type", 'error'),
        map:put($error, "name", $err/error:name/fn:string(.)),
        map:put($error, "message", $err/error:format-string/fn:string(.))
    }
};
