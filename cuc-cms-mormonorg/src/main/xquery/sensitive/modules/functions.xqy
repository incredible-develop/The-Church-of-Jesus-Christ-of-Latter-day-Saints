xquery version "1.0-ml";

module namespace sens-functs = "http://lds.org/code/shared/lds-edit/sensitive/functions";

import module namespace tw = "http://lds.org/code/shared/lds-edit/translation-workflow" at "/translation/modules/translation-workflow.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace to = "http://lds.org/code/shared/lds-edit/translation/to" at "/translation/modules/to-functions.xqy";
import module namespace tranSettings = "http://lds.org/code/shared/lds-edit/translation-settings" at "/translation/modules/translation-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare variable $username as xs:string := ac:getUserName();

declare function sens-functs:needing-approval() as element()* {
    cts:search(/*,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("ldse:sensitive"), xs:QName("stakeholder"), fn:lower-case($username), "exact"),
            cts:element-attribute-value-query(xs:QName("ldse:sensitive"), xs:QName("approval-sent"), "yes", "exact"),
            cts:element-attribute-value-query(xs:QName("ldse:sensitive"), xs:QName("needs-approval"), "yes", "exact")
        ))
    )
};

declare function sens-functs:sensitive-files() as element()* {
    cts:search(/*,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("ldse:sensitive"), xs:QName("status"), "yes", "exact")
        ))
    )
};

declare function sens-functs:approval-table() as element(tr)* {
    let $need-approval as element()* := sens-functs:needing-approval()
    for $file as element() at $index in $need-approval
    let $id as xs:string? := ldsemeta:get-document-id($file)
    let $url as xs:string := core:build-url(ldsemeta:get-document-uri($file), (ldsemeta:get-document-locale($file), "eng")[1], ())
    return (
        <tr data-uri="">
			<td>
				<span class="ldse-option box-only">
					<input class="rowSelect" type="checkbox" value="{$id}" id="ldse-sensitive-item-{$index}" data-words="" />
					<label for="ldse-sensitive-item-{$index}">Check</label>
				</span>
			</td>
			<td><a onclick="openItem('{$url}'); return false;" class="ldse-icon-preview ldse-icon big" /></td>
            <td class="">{ldsemeta:get-document-type($file)}</td>
            <td class="hide-small"></td>
            <td  class="">{ldsemeta:get-document-title($file)}</td>
            <td class="hide-small">{ldsemeta:get-document-locale($file)}</td>
            <td class="hide-med">{ldsemeta:get-document-status($file)}</td>
        </tr>
    )
};

declare function sens-functs:sensitive-table() as element(tr)* {
    let $sensitive-files as element()* := sens-functs:sensitive-files()
    for $file as element() at $index in $sensitive-files
    let $id as xs:string? := ldsemeta:get-document-id($file)
    let $url as xs:string := core:build-url(ldsemeta:get-document-uri($file), (ldsemeta:get-document-locale($file), "eng")[1], ())
    return (
        <tr data-uri="">
			<td>
				<span class="ldse-option box-only">
					<input class="rowSelect" type="checkbox" value="{$id}" id="ldse-sensitive-item-{$index}" data-words="" />
					<label for="ldse-sensitive-item-{$index}">Check</label>
				</span>
			</td>
			<td><a onclick="openItem('{$url}'); return false;" class="ldse-icon-preview ldse-icon big" /></td>
            <td class="">{ldsemeta:get-document-type($file)}</td>
            <td class="hide-small"></td>
            <td  class="">{ldsemeta:get-document-title($file)}</td>
            <td class="hide-small">{ldsemeta:get-document-locale($file)}</td>
            <td class="hide-med">{ldsemeta:get-document-status($file)}</td>
        </tr>
    )
};

declare function sens-functs:approve-item($id as xs:string) as item()* {
    let $file as element() := ldsemeta:get-file-by($id, (), (), ())
    let $new-file as element() := ldsemeta:update-sensitive-file($file, (), (), "no", "yes", (), ())
    return (
        core:document-replace($file, $new-file)
    )
};

declare function sens-functs:unpublish-item($id as xs:string) as item()* {
    let $file as element() := ldsemeta:get-file-by($id, (), (), ())
    return (
        core:update-file("ldse:unpublish", xdmp:node-uri($file), core:action-transform("ldse:unpublish", $file))
    )
};
