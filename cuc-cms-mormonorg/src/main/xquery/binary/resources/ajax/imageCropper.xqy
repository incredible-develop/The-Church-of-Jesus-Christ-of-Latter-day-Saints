xquery version "1.0-ml";

import module namespace image = "http://lds.org/code/shared/lds-edit/imageFunctions" at "../../modules/imageFunctions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace burce = "http://lds.org/code/shared/lds-edit/burceFunctions" at "../../../ice/modules/burceFunctions.xqy";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace ldse = "http://lds.org/code/lds-edit"; 

declare boundary-space preserve;
declare option xdmp:mapping "true";

declare variable $title as xs:string := 'Image Manager';

declare variable $imageId as xs:string := xdmp:get-request-field("fileId");
declare variable $imageXml as element(binary-content)? := image:get-image-xml-by-id($imageId);
declare variable $imageName as xs:string := image:get-image-name($imageXml);
declare variable $allowed-height as xs:string? := xdmp:get-request-field("allowedHeight");
declare variable $allowed-width as xs:string? := xdmp:get-request-field("allowedWidth");

if (fn:exists($imageXml)) then (
    let $imageUrl as xs:string := core:get-display-uri($imageXml/path)
    let $aspectRatios as element()* := image:get-aspect-ratios($imageXml)
    return (
        xdmp:set-response-content-type( "text/html" ),
        <form id="imageCropperForm">
            <h2 id='cropImageTitle'>{$imageName}</h2>
            <div style="float: left">
                <div>
                    <img id="cropperMainImage" src="{$imageUrl}"/>
                    <div id="cropPositionLinks">
                        <span class="link" style="padding: 5px" onclick="imageCropper.jcropMaximize()">Maximize</span>
                        <span class="link" style="padding: 5px" onclick="imageCropper.jcropCenter()">Center</span>
                    </div>
                    <div id="cropperBtnHolder">
                        <a id="saveCropBtn" class="btn" >Save All Crops</a>
                        <a id="cancelCropBtn" class="btn">Cancel</a>
                    </div>
                    <div id="dimensionLegend">
                        Some crops may be poor quality because the image is too small.  Please upload a larger image for better quality.
                    </div>
                </div>
            </div>
            <div id="canvases" style="float: left">{burce:createThumbnail($aspectRatios, $imageXml)}</div>
            <input name="fileId" type="hidden" value="{$imageId}"/>
            {
                if ( fn:exists($allowed-height) and fn:exists($allowed-width) ) then (
                    <input name="allowedWidth" type="hidden" value="{$allowed-width}"/>,
                    <input name="allowedHeight" type="hidden" value="{$allowed-height}"/>
                ) else ()
            }
        </form>
    )
) else ()
