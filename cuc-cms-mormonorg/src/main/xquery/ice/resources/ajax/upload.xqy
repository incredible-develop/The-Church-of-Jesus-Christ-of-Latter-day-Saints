xquery version "1.0-ml";

import module namespace saveImage = "http://lds.org/code/shared/lds-edit/save-image" at "saveImage.xqy";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare boundary-space preserve;
declare option xdmp:mapping "true";

xdmp:set-response-content-type( "text/html" ),

let $fileName as xs:string := xdmp:get-request-field-filename("upload")
let $fileContents as item()* := xdmp:get-request-field("upload")
let $imagePath as xs:string := saveImage:saveImage($fileName, $fileContents)
return 
<script type='text/javascript'>window.parent.CKEDITOR.tools.callFunction({xdmp:get-request-field("CKEditorFuncNum")}, '{core:get-display-uri($imagePath)}');</script>

