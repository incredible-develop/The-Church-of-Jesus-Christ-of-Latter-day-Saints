xquery version "1.0-ml";
import module namespace content-search = "http://lds.org/code/shared/lds-edit/content/content-search" at "../../content/modules/content-search.xqy";
import module namespace json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
declare option xdmp:mapping "true";
xdmp:set-response-content-type("application/json"),
(:Calls the additional function and returns a serialized JSON object:)
content-search:jsonAdditional()

