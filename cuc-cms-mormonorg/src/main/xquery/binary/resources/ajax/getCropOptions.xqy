xquery version "1.0-ml";

import module namespace image = "http://lds.org/code/shared/lds-edit/imageFunctions" at "../../modules/imageFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare boundary-space preserve;
declare option xdmp:mapping "true";


declare variable $username as xs:string := image:get-image-crop-username();
declare variable $password as xs:string := image:get-image-crop-password();
declare variable $serviceUrl as xs:string := image:get-image-crop-service();
declare variable $outputUrl as xs:string := image:get-image-crop-output();

declare variable $currentKey as xs:integer := 0;

declare variable $imageId as xs:string := xdmp:get-request-field("fileId");

declare variable $imageXml as element(binary-content)? := image:get-image-xml-by-id($imageId);

declare variable $aspectRatios as element(ldse:aspect-ratio)* := image:get-aspect-ratios($imageXml);

xdmp:set-response-content-type( "text/html" ),

for $aspectRatio as element(ldse:aspect-ratio) in $aspectRatios
return
    (
        <optgroup label="{$aspectRatio/@name}">
            {
                for $size as element(ldse:size) in $aspectRatio/ldse:size
                return <option value="{$size/@options}">{fn:string($size/@options)}</option>
            }
        </optgroup>
    )
