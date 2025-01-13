xquery version "1.0-ml";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../ice/modules/dynamicForms.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

xdmp:set-response-content-type("text/html"),
let $has-permission as xs:boolean := ac:has-any-permissions('ldse:edit-doc', (), ())

return (
    if ( $has-permission ) then (
        <dd>
            {
                element select {
                    attribute name {"form"},
                    attribute id {"formSelector1"},
                    attribute type {"select"},
                    form:getFormNames()
                }
            }
        </dd>
    ) else ()
)