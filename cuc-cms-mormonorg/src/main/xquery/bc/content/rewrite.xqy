xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

let $requestPath := xdmp:get-request-url()
(:let $debug := xdmp:log(("****************bcRewrite requestPath",$requestPath)):)
let $returnPath :=
    if (fn:starts-with($requestPath, '/bc/content/')) then (
        functx:substring-after-if-contains($requestPath, '/bc/content/')
    ) else (
        functx:substring-after-if-contains($requestPath, '/bc/')
    )
(:let $debug := xdmp:log(("********bcRewrite returnPath",$returnPath)):)
return
    if ($returnPath) then (
        xdmp:add-response-header("Cache-Control", "max-age=21600"),
        $returnPath
    ) else ("Bad URI")
