module namespace tzip = 'http://lds.org/code/lds-edit-services/translation-functions';
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace zip="xdmp:zip";
declare option xdmp:mapping "true";

declare function tzip:getSiteFromZip($zip as item()) as item()* {
    let $manifest := xdmp:zip-manifest($zip)
    let $options as element() := <options xmlns="xdmp:zip-get"><format>xml</format></options>
    let $files as item()* :=
        for $file in $manifest/zip:part
        let $name as xs:string := $file/text()
        where fn:ends-with($name, '.xml')
        return xdmp:zip-get($zip, $name, $options)/node()
    let $site as xs:string? := 
        (
            ($files/ldse:ldse-meta/ldse:document/@site)[1],
            ($files/@site)[1]
        )[1]
    return (
        if ($site) then (
            $site
        ) else (
            fn:error(xs:QName("ERROR"), "Zip contained no site.")
        )
    )
};

