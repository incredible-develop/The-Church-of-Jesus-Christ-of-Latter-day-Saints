xquery version "1.0-ml";

module namespace components = "http://lds.org/code/shared/lds-edit/component-functions";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare function components:get-components($file as element()) as xs:string* {
    cts:search(/component, 
        cts:and-query((
            core:get-filter-query(), 
            cts:or-query((
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $file/@compId, 'exact'),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $file/@parent, 'exact')
            ))
        )) 
    )[1]
};
