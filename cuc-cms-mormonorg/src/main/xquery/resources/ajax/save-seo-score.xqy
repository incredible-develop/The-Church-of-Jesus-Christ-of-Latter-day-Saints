xquery version "1.0-ml";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

let $url as xs:string := xdmp:get-request-field("url")

let $score as element(ldse:score) :=
	<score xmlns="http://lds.org/code/lds-edit">
		<validTitle>{xdmp:get-request-field("score[validTitle]")}</validTitle>
		<validDesc>{xdmp:get-request-field("score[validDesc]")}</validDesc>
		<validImgs>{xdmp:get-request-field("score[validImgs]")}</validImgs>
		<imgs>{xdmp:get-request-field("score[imgs]")}</imgs>
		<validAltCount>{xdmp:get-request-field("score[validAltCount]")}</validAltCount>
		<score>{xdmp:get-request-field("score[score]")}</score>
	</score>

let $locale as xs:string := xdmp:get-request-field("locale")
let $file as element() := 
    cts:search(/custom-page,
        cts:and-query((
             core:get-filter-query(),
             cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('uri'), '=', $url, "collation=http://marklogic.com/collation/"),
             cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/")
        ))
    )[1]
let $new-file as element() := util:clone($file)
let $new-file as element() := ldsemeta:update-seo-score($new-file, $score)
let $_ as empty-sequence() := core:document-replace($file, $new-file)

return ()










