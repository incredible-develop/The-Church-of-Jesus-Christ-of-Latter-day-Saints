xquery version "1.0-ml";

module namespace ff = "http://lds.org/code/shared/lds-edit/file-functions";

import module namespace fq = "http://lds.org/code/shared/lds-edit/file-queries" at "file-queries.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
import module namespace batch = "http://lds.org/code/shared/common/process/batch-processing" at "/shared/common/process/batch/batchFunctions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "../../modules/document-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace pretty = "http://lds.org/code/shared/common/pretty-print" at "/shared/common/util/pretty-print.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $directory as xs:string := xdmp:get-request-field('directory');
declare variable $dup-map as map:map := map:map();

(: *****************  SETTINGS ********************* :)
declare variable $OPTIONS as element(batch:options)? :=
    <options xmlns="http://lds.org/code/shared/common/process/batch-processing">
        <chunk-size>1000</chunk-size>
    </options>;
    
declare function ff:get-duplicate-files($id as xs:string?, $uri as xs:string?, $locale as xs:string?) as element(tr)* {
    for $file in fq:find-file-by($id, $uri, $locale)
    let $file-path as xs:string := $file/xdmp:node-uri(.)
    return (
        <tr>
            <td class="file-id"><a onclick="viewXml('{$file-path}'); return false;">{ldsemeta:get-document-id($file)}</a></td>
            <td class="locale">{ldsemeta:get-document-locale($file)}</td>
            <td class="title">{ldsemeta:get-document-title($file)}</td>
            <td class="uri">{ldsemeta:get-document-uri($file)}</td>
            <td class="file-path">{$file-path}</td>
        </tr>
    )
};

declare function ff:find-duplicate-files($uris as xs:string*) as item()* {
    for $uri as xs:string at $index in $uris
    let $file as element()? := fn:doc($uri)/*
    let $id as xs:string? := ( ldsemeta:get-document-id($file), $file/@id )[1]
    let $dup-files as element()* := if ( fn:exists($id) ) then ( fq:find-file-by($id, (), ()) ) else ()
    where fn:count($dup-files) > 1 and fn:empty(map:get($dup-map, $id)) and fn:exists($id)
    return (
        let $put as empty-sequence() := map:put($dup-map, $id, $id)
        let $dup-file as element() := 
            element { fn:QName('http://lds.org/code/lds-edit', 'dup-files') } {
                attribute dupId { $id },
                attribute filePath { $uri },
                for $dup as element() in $dup-files
                return (
                    element { fn:QName('http://lds.org/code/lds-edit', 'dup-file') } { xdmp:node-uri($dup) }
                )
            }
        let $doc-path as xs:string := util:clean-db-uri( fn:concat(core:get-site-root(), "/content/lds-edit/duplicate-files/dup-file-", $id, "-", $index, ".xml") )
        
        return (
            document:document-insert($doc-path, $dup-file)
        )
    )
};

declare function ff:get-saved-duplicates() as element(tr)* {
    for $dup-file as element() at $i in fq:get-saved-duplicates()
    return (
        <tr>{$dup-file/@filePath}</tr>,
        for $dup as element() in $dup-file/ldse:dup-file
        return (
            if ( ($i mod 2) = 1 ) then (
                <tr style="background-color:#f1f1f1;">
                    <td><a href="#d" onclick="viewXml('{$dup}'); return false;">{$dup}</a></td>
                </tr>
            ) else (
                <tr>
                    <td><a href="#d" onclick="viewXml('{$dup}'); return false;">{$dup}</a></td>
                </tr>
            )
        )
    )
};

declare function ff:view-edit-xml($uri as xs:string) {
    xdmp:quote(fn:doc($uri)/*)
};

declare function ff:save-xml($path as xs:string, $new-xml as xs:string, $mode as xs:string?) {
    let $file as element()? := fn:doc($path)/*
    let $new-xml as element() := xdmp:unquote($new-xml)/*
    let $id as xs:string := ldsemeta:get-document-id($new-xml)
    let $locale as xs:string := ldsemeta:get-document-locale($new-xml)
    let $check-file as element() := 
        ff:check-file( $id, $locale, 
            (ldsemeta:get-document-uri($new-xml), $new-xml/@uri, $new-xml/@page)[1],
            util:substring-before-last($path, '/'),
            (),
            fn:local-name($new-xml),
            "",
            $mode
        )
    let $file as element()? := if ( fn:empty($file) ) then ( ldsemeta:get-file-by($id, $locale, (), ()) ) else ( $file ) 
	return (
        if ( $check-file/code/fn:string() = "201" ) then (
            core:update-file("ldse:preview", $path, $new-xml)
        ) else ()
	)
};

declare function ff:check-file(
    $id as xs:string,
    $locale as xs:string,
    $uri as xs:string?,
    $directory as xs:string?,
    $root-element as xs:string?,
    $id-qname as xs:string?,
    $path as xs:string
) as element() {
    ff:check-file($id, $locale, $uri, $directory, $root-element, $id-qname, $path, ())
};

declare function ff:check-file(
    $id as xs:string,
    $locale as xs:string,
    $uri as xs:string?,
    $directory as xs:string?,
    $root-element as xs:string?,
    $id-qname as xs:string?,
    $path as xs:string,
    $mode as xs:string?
) as element() {
    let $files as element()* := fq:query-for-file($id, $locale, $uri, $directory, $root-element, $id-qname, $mode)
    return (
        if ( fn:empty($files) ) then (
            let $db-path as xs:string := util:clean-db-uri( fn:concat(core:get-site-root(), "/content/lds-edit/file-result/result-", $id, "-", $locale, ".xml") )
            let $xml as element() := 
                <query-file file="{$id}">
                    <file-location>{$directory}</file-location>
                    <db-path>{$path}</db-path>
                </query-file>
            let $save as item()* := document:document-insert($db-path, $xml)
            
            return (
                <result>
                    <file-locations>
                        {
                            for $file in $files
                            return (
                                <file-location>{xdmp:node-uri($file)}</file-location>
                            )
                        }
                    </file-locations>
                    <message>File does not exist in database</message>
                    <code>201</code>
                </result>
            )
        ) else if ( fn:count($files) > 1 ) then (
            <result>
                <file-locations>
                    {
                        for $file in $files
                        return (
                            <file-location>{xdmp:node-uri($file)}</file-location>
                        )
                    }
                </file-locations>
                <message>Multiple files exist in database</message>
                <code>500</code>
            </result>
        ) else (
            let $db-path as xs:string := util:clean-db-uri( fn:concat(core:get-site-root(), "/content/lds-edit/file-result/result-", $id, "-", $locale, ".xml") )
            let $xml as element() := 
                <query-file file="{$id}">
                    <file-location>{(xdmp:node-uri($files), $directory)[1]}</file-location>
                    <db-path>{$path}</db-path>
                </query-file>
            let $save as item()* := document:document-insert($db-path, $xml)
            
            return (
                <result>
                    <file-locations>
                        {
                            for $file in $files
                            return (
                                <file-location>{xdmp:node-uri($file)}</file-location>
                            )
                        }
                    </file-locations>
                    <message>File exists in database and will be overwritten</message>
                    <code>200</code>
                </result>
            )
        )
    )
};

declare function ff:get-structure() as xs:string* {
    fq:get-structure()
};

declare function ff:get-child-directories($directory as xs:string) as xs:string* {
    fq:get-child-directories($directory)
};

declare function ff:get-content-item($file-path as xs:string) as element() {
    fn:doc($file-path)/*
};

declare function ff:get-roles($mode as xs:string, $port as xs:integer, $username as xs:string?) as element()? {
    let $mode := core:set-mode($mode)
    let $port := core:set-port($port)
    return ( 
        if ( fn:exists($username) ) then (
            core:get-contributor()
        ) else ()
    )
};

declare function ff:delete-content($directory as xs:string) as item()* {
    if ( fn:ends-with($directory, '.xml') or fn:ends-with($directory, '.xhtml') ) then (
        core:delete-file($directory, fn:doc($directory)/*, ())
    ) else (
        xdmp:directory-delete($directory)
    )
};
