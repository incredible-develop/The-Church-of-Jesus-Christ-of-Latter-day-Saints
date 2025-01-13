 xquery version "1.0-ml";

 module namespace saveImage = "http://lds.org/code/shared/lds-edit/save-image";

import module namespace cpfCommon = "http://lds.org/code/shared/cpf/common-functions" at "/shared/common/cpf/commonFunctions.xqy";
import module namespace fs = "http://lds.org/code/shared/common/document/filesystem-doc-functions" at "/shared/common/document/filesystemDocFunctions.xqy";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare boundary-space preserve;
declare option xdmp:mapping "true";

 (:
    Saves an Image into any database

    $img-name is path to the file and the file name
    $img is the image or the content of the image
 :)

 declare function saveImage($fileName as xs:string, $doc as item()*) as xs:string {
    let $tokens  as xs:string+ := fn:tokenize($fileName, "/")
    let $docDropUri  as xs:string := fn:concat("/", fn:string-join($tokens[2 to fn:last()], "/"))
    
    let $bc as xs:string := $settings:shared-prefix
    let $base as xs:string := $settings:bcs-path
    
    let $ckUpPath  as xs:string? := $settings:ldse-settings/ldse:ckeditor/ldse:image-upload-path
    let $debug as item()* := xdmp:trace("ckSaveImage", fn:concat("docDropUri=",$docDropUri))
    
    let $savePath as xs:string := fn:concat($base, "/content", $ckUpPath, $fileName)
    let $uriPath as xs:string := fn:concat($ckUpPath, $fileName)
    
    let $xmpData as element()? := cpfCommon:getXmpInfo($doc)
    let $imageXml as element() := cpfCommon:buildImageXml($xmpData, fn:concat('/content',$uriPath))
    let $fileName as xs:string := $tokens[fn:last()]
    let $xmlPath as xs:string := fn:concat(core:get-mode-root(), $ckUpPath, "xml/", $fileName, ".xml")

    let $xmlDoc as item()? := fn:doc($xmlPath)
    let $docRoot as element()? := $xmlDoc/element()

    (: create xml meta file for the image :)
    let $debug as item()* := xdmp:trace("ckSaveImage", fn:concat("insertingXMLinDelivery=",$xmlPath))
    let $insertXml as item()* :=
        if ( fn:exists($xmlDoc) ) then (
            cpfCommon:updateXmpData($xmpData, $docRoot)
        ) else (
            let $debug as item()* := xdmp:trace("ckSaveImage", fn:concat("insertingXMLinDelivery2=",$xmlPath))
            return core:save-file($xmlPath, $imageXml, () )
        )


    (: save to BC :)
    let $debug as item()* := xdmp:trace("ckSaveImage", fn:concat("insertingIntoBC=",$base))
    let $debug as item()* := xdmp:trace("ckSaveImage", fn:concat("bcPath=",$savePath))
    let $saveToBCS as item()* := fs:save($savePath, $doc)

    return $uriPath
 };
