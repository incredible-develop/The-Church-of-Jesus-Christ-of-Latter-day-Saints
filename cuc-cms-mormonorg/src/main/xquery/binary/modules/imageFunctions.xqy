xquery version "1.0-ml";

module namespace image = "http://lds.org/code/shared/lds-edit/imageFunctions";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace cc = "http://lds.org/code/shared/lds-edit/clear-cache-functions" at "/clear-cache/modules/clear-cache-functions.xqy";
import module namespace function = "http://lds.org/code/shared/lds-edit/function-apply" at "/invoke/function-apply.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare function get-aspect-ratio-h($ratio as element()) as xs:double? {
    xs:double(($ratio/@h, $ratio/@height)[1])
};

declare function get-aspect-ratio-name($ratio as element()) as xs:string? {
    ($ratio/@name, $ratio/@aspect-ratio-name)[1]
};

declare function get-aspect-ratio-size-height($size as element()) as xs:integer? {
    xs:integer($size/@height)
};

declare function get-aspect-ratio-size-options($size as element()) as xs:string? {
    $size/@options
};

declare function get-aspect-ratio-size-flags($size as element()) as xs:string? {
    $size/@flags
};

declare function get-aspect-ratio-size-width($size as element()) as xs:integer? {
    xs:integer($size/@width)
};

declare function get-aspect-ratio-sizes($ratio as element()) as element()* {
    $ratio/ldse:size
};

declare function get-aspect-ratio-sizes($ratio as element(), $maxWidth as xs:integer, $maxHeight as xs:integer) as element(ldse:size)* {
    $ratio/ldse:size[./@width le $maxWidth and ./@height le $maxHeight]
};

declare function get-aspect-ratio-w($ratio as element()) as xs:double? {
    xs:double(($ratio/@w, $ratio/@width)[1])
};
(:		<aspect-ratio name="Square" w="1" h="1">
			<size options="512x512" width="512" height="512"/>
			<size options="256x256" width="256" height="256"/>
			<size options="150x150" width="150" height="150"/>
		</aspect-ratio>
		<aspect-ratio name="Wide" w="2" h="1">
			<size options="512x256" width="512" height="256"/>
			<size options="300x150" width="300" height="150"/>
		</aspect-ratio>

		<crop aspect-ratio-name="Square" width="768" height="768" x="139" y="0">
            <resize options="512x512" width="512" height="512"/>
            <resize options="256x256" width="256" height="256"/>
            <resize options="150x150" width="150" height="150"/>
        </crop>
        <crop aspect-ratio-name="Wide" width="1024" height="512" x="0" y="155">
            <resize options="512x256" width="512" height="256"/>
            <resize options="300x150" width="300" height="150"/>
        </crop>:)
declare function get-greatest-cmd($width as xs:string, $height as xs:string) as xs:int {
    let $height as map:map := get-divisibles(xs:int($height))
    let $width as  map:map := get-divisibles(xs:int($width))
    let $inner as map:map := $width * $height
    return (
        fn:max(xs:int(map:keys($inner)))
    )
};

declare function get-divisibles($num as xs:int) as map:map {
    let $map as map:map := map:map()
    let $values as empty-sequence() :=
        for $i as xs:int in (1 to fn:floor($num div 2), $num)
        where $num mod $i = 0
        return (
            map:put($map, xs:string($i), $i)
        )
    return (
        $map
    )
};

declare function add-ratio($map as map:map, $ratio as element()) as empty-sequence() {
    let $size as element() := ($ratio/(*:resize|*:size)[1], $ratio)[1]
    let $w as xs:string := $size/(@w|@width)
    let $h as xs:string := $size/(@h|@height)
    let $d as xs:int := get-greatest-cmd($w, $h)
    let $r as xs:string := fn:concat(xs:int($w) div $d, ":", xs:int($h) div $d)
    let $rmap as map:map? := (map:get($map, $r), map:map() )[1]
    let $sizes-map as map:map := (map:get($rmap, 'sizes'), map:map())[1]
    let $puts as empty-sequence() := (
        for $size as element() in $ratio/(*:size|*:resize)
        let $options as xs:string? := xs:string($size/@options)
        let $size-map as map:map? := map:get($sizes-map, $options)
        where fn:empty($size-map)
        return (
            let $map as map:map := map:map()
            let $puts as item()* := (
               map:put($map, "options", xs:string($size/@options) ),
               map:put($map, "width", xs:string($size/@width) ),
               map:put($map, "height", xs:string($size/@height) ),
               map:put($map, "flags", xs:string($size/@flags) )
            )
            return (
                map:put($sizes-map, xs:string($size/@options), $map)
            )
        )
    )
    let $puts as empty-sequence() := (
        map:put($rmap, "name", xs:string($ratio/(@name|@aspect-ratio-name))),
        map:put($rmap, "width", xs:string($ratio/(@w|@width))),
        map:put($rmap, "height", xs:string($ratio/(@h|@height))),
        map:put($rmap, "sizes", $sizes-map),
        typeswitch ($ratio)
        case element(crop) return (
            map:put($rmap, "crop-w", xs:string($ratio/@width)),
            map:put($rmap, "crop-h", xs:string($ratio/@height)),
            map:put($rmap, "crop-x", xs:string($ratio/@x)),
            map:put($rmap, "crop-y", xs:string($ratio/@y))
        )
        default return ()
    )
    return (
        map:put($map, $r, $rmap)
    )
};

(:
    See http://www.graphicsmagick.org/GraphicsMagick.html#details-resize for details on the flags for resize
:)
declare function merge-ratios($aspect-ratios as element(ldse:aspect-ratio)*, $crops as element(crop)*, $width as xs:string?, $height as xs:string?) as element(ldse:aspect-ratio)* {
    let $RATIOS as map:map := map:map()
    let $add-custom as empty-sequence() :=
        if ( fn:exists($width) and fn:exists($height) and fn:not($width = "") and fn:not($height = "") ) then (
            let $ratio as xs:int := get-greatest-cmd($width, $height)
            let $name as xs:string := fn:concat("Custom ", xs:int($width) div $ratio, ":", xs:int($height) div $ratio)
            return (
                add-ratio($RATIOS,
                    <aspect-ratio name="{$name}" width="{$width}" height="{$height}">
                        <size options="{$width}x{$height}" width="{$width}" height="{$height}"/>
                    </aspect-ratio>
                )
            )
        ) else ()

    return (
        let $add-crops as empty-sequence() := add-ratio($RATIOS, $crops)
        return (
            let $add-aspects as empty-sequence() := add-ratio($RATIOS, $aspect-ratios)
            return (
                for $r-key as xs:string in map:keys($RATIOS)
                let $ratio as map:map := map:get($RATIOS, $r-key)
                return (
                    <aspect-ratio xmlns="http://lds.org/code/lds-edit">{
                        attribute name { map:get($ratio, 'name') },
                        attribute w { map:get($ratio, 'width') },
                        attribute h { map:get($ratio, 'height') },
                        attribute width { map:get($ratio, 'crop-w') },
                        attribute height { map:get($ratio, 'crop-h') },
                        attribute x { map:get($ratio, 'crop-x') },
                        attribute y { map:get($ratio, 'crop-y') },
                        let $sizes-map as map:map := map:get($ratio, 'sizes')
                        for $size-key as xs:string in map:keys($sizes-map)
                        let $size as map:map := map:get($sizes-map, $size-key)
                        let $width as xs:int := xs:int(map:get($size, 'width'))
                        order by $width descending
                        return (
                            <size xmlns="http://lds.org/code/lds-edit">{
                                attribute options { map:get($size, 'options') },
                                attribute width { $width },
                                attribute height { map:get($size, 'height') },
                                attribute flags { map:get($size, 'flags') }
                            }</size>
                        )
                    }</aspect-ratio>
                )
            )
        )
    )

};

declare function get-aspect-ratios($image-xml as element()) as element()* {
    merge-ratios($settings:aspect-ratios, $image-xml/image-processing/crop, xdmp:get-request-field("allowedWidth"), xdmp:get-request-field("allowedHeight"))
};

declare function get-cropped-image($xml as element(binary-content), $aspect-ratio-name as xs:string) as element(crop)? {
    get-image-processing($xml)/crop[./@aspect-ratio-name eq $aspect-ratio-name][1]
};

declare function get-cropped-image-height($cropped-image as element(crop)) as xs:integer? {
    xs:integer($cropped-image/@height)
};

declare function get-cropped-image-width($cropped-image as element(crop)) as xs:integer? {
    xs:integer($cropped-image/@width)
};

declare function get-cropped-image-x1($cropped-image as element(crop)) as xs:integer? {
    xs:integer($cropped-image/@x)
};

declare function get-cropped-image-x2($cropped-image as element(crop)) as xs:integer? {
    get-cropped-image-x1($cropped-image) + get-cropped-image-width($cropped-image)
};

declare function get-cropped-image-y1($cropped-image as element(crop)) as xs:integer? {
    xs:integer($cropped-image/@y)
};

declare function get-cropped-image-y2($cropped-image as element(crop)) as xs:integer? {
    get-cropped-image-y1($cropped-image) + get-cropped-image-height($cropped-image)
};


declare function get-image-crop-output() as xs:string? {
    get-service-for-environment()/ldse:output[1]
};

declare function get-image-crop-password() as xs:string? {
    get-service-for-environment()/ldse:password[1]
};

declare function get-image-crop-service() as xs:string? {
   get-service-for-environment()/ldse:service
};

declare function get-image-crop-username() as xs:string? {
    get-service-for-environment()/ldse:username[1]
};

declare function get-service-for-environment() as element(ldse:service-settings){
     let $service-settings as element()* := image-crop-settings()/ldse:service-settings
     return
     if ( $settings:environment eq "prod" ) then (
          $service-settings[@environment = "prod"]
     ) else(
         $service-settings[@environment = "stage"]
     )
};

declare function get-image-filesystem-directory($xml as element(binary-content)) as xs:string? {
    let $directory as xs:string? := $xml/folder
    return if (fn:exists($directory)) then (
        fn:concat($settings:bcs-path, "/content", $directory)
    ) else ()
};

declare function get-image-filesystem-path($xml as element(binary-content)) as xs:string? {
    let $path as xs:string? := $xml/path
    return if (fn:exists($path)) then (
        fn:concat($settings:bcs-path, "/content", $path)
    ) else ()
};

declare function get-image-filesystem-path-by-id($id as xs:string) as xs:string {
    get-image-filesystem-path(get-image-xml-by-id($id))
};

declare function get-image-processing($xml as element(binary-content)) as element(image-processing)? {
    $xml/image-processing[1]
};

declare function get-image-name($xml as element(binary-content)) as xs:string? {
    $xml/file-name[1]
};

declare function get-image-url($xml as element(binary-content)) as xs:string? {
    let $path as xs:string? := $xml/path
    return if (fn:exists($path)) then (
        fn:concat($settings:shared-prefix, "/bc/content", $path)
    ) else ()
};

declare function get-image-url-by-id($id as xs:string) as xs:string {
    get-image-url(get-image-xml-by-id($id))
};

declare function get-image-xml-by-id($id as xs:string) as element(binary-content)? {
    cts:search(
        /binary-content,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("binary-content"), xs:QName("id"), $id, "exact"),
            cts:element-value-query(xs:QName("type"), "image", "exact")
        ))
    )[1]
};

declare function get-document-binary($fileName as xs:string) as item()*{
    xdmp:document-get($fileName,
        <options xmlns="xdmp:document-get">
           <format>binary</format>
       </options>)
};

declare function image-crop-settings() as element(ldse:image-crop-settings)? {
    $settings:crop-settings
};

declare function clearBinaryCache($xml as element(binary-content)) as item()* {
    let $image-urls as xs:string? := $xml/path
    let $crops-urls as xs:string* :=
        let $folder as xs:string? := $xml/folder
        let $file-name as xs:string? := $xml/file-name
        for $size as element(resize) in $xml/image-processing/crop/resize
        return (
            fn:concat($folder, $size/@options, '/', $file-name)
        )

    let $uris as element(uris) :=
        element uris {
            for $url as xs:string in ($image-urls, $crops-urls)
            return (
                element uri { core:get-display-uri($url) }
            )
        }
    let $function as xdmp:function := xdmp:function(xs:QName('cc:clearCache'))
    return (
        function:spawn($function, $core:mode, $uris, $core:site, 'eng', cc:getCacheConfig()/ldse:clear-service/@value, ac:getUserName())
        (: cc:clearCache( $uris, $core:site, 'eng') :)
    )
};

declare function image-file-exists($path as xs:string) as xs:boolean {
    xdmp:filesystem-file-exists($path)
};
