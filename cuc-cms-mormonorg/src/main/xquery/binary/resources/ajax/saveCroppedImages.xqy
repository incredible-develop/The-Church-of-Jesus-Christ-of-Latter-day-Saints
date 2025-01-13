xquery version "1.0-ml";

import module namespace image = "http://lds.org/code/shared/lds-edit/imageFunctions" at "../../modules/imageFunctions.xqy";
import module namespace burce = "http://lds.org/code/shared/lds-edit/burceFunctions" at "../../../ice/modules/burceFunctions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "../../../modules/document-functions.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";

let $imageXml as element(binary-content)? := image:get-image-xml-by-id(xdmp:get-request-field("fileId"))
let $new-image-xml as element(binary-content)? := burce:save-crops($imageXml) 
return (
    document:document-replace($imageXml, $new-image-xml)
)
