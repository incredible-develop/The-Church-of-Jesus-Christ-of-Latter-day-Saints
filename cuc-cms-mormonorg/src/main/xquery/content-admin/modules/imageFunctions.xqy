xquery version "1.0-ml";

module namespace images = "http://lds.org/code/seminary-and-institute/imageFunctions";
import module namespace g = "http://lds.org/code/lds-edit/content-admin/globalVariables" at "globalVariables.xqy";
import module namespace c = "http://lds.org/code/shared/common/common-functions" at "/shared/common/commonFunctions.xqy";
import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "content-functions.xqy";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace jb = "http://marklogic.com/xdmp/json/basic";

declare variable $images:SQUARE as xs:string := 'square';
declare variable $images:POSTER as xs:string := 'poster';
declare variable $images:CLASSIC as xs:string := 'classic';
declare variable $images:STANDARD as xs:string := 'standard';
declare variable $images:WIDE as xs:string := 'wide';

declare variable $placeholderImg as xs:string :=
    let $imgUrl := $core:siteProperties/admin-pages/images/placeholder[@lang = $g:lang]/xs:string(.)
    let $defaultImgUrl := $core:siteProperties/admin-pages/images/default-placeholder/xs:string(.)

    return (
        core:get-display-uri(( $imgUrl, $defaultImgUrl, '' )[1])
    );

declare function getImagesByType(
    $name as xs:string,
    $imagePath as xs:string?,
    $altText as xs:string?
) as element(jb:json)* {
    let $image-xml-crops as element(resize)* := cf:get-image-xml($imagePath)/image-processing/crop/resize
(:    let $ratio as element(ldse:aspect-ratio)? := $g:ldse-settings/ldse:image-crop-settings/ldse:aspect-ratio[@name eq $name]
    let $sizes as element()* :=
        for $size in $ratio/ldse:size
        order by xs:integer($size/@width), xs:integer($size/@height)
        return (
            $size
        )
:)
    let $imagePathBefore as xs:string := functx:substring-before-last($imagePath, '/') || '/'
    let $imagePathAfter as xs:string := '/' || functx:substring-after-last($imagePath, '/')
    where c:stringNotEmpty($imagePath)
    return (
        for $size as element(resize) in $image-xml-crops
        let $width as xs:string? := $size/@width
        let $height as xs:string? := $size/@height
        let $name as xs:string? := $image-xml-crops/@name
        let $url as xs:string := $imagePathBefore || $width || 'x' || $height || $imagePathAfter
        return (
            <jb:json type="object" jb:xmlns="http://marklogic.com/xdmp/json/basic">
                <jb:title type="string">{$altText}</jb:title>
                <jb:url type="string">{$url}</jb:url>
                <jb:width type="number">{$width}</jb:width>
                <jb:height type="number">{$height}</jb:height>
                <jb:tags type="array">
                    <jb:item type="string">{$name}</jb:item>
                </jb:tags>
            </jb:json>
        )
    )
};
