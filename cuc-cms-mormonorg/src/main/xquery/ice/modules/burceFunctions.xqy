xquery version "1.0-ml";

module namespace burce = "http://lds.org/code/shared/lds-edit/burceFunctions";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";
import module namespace fs = "http://lds.org/code/shared/common/document/filesystem-doc-functions" at "/shared/common/document/filesystemDocFunctions.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace function = "http://lds.org/code/shared/lds-edit/function-apply" at "/invoke/function-apply.xqy";
import module namespace image = "http://lds.org/code/shared/lds-edit/imageFunctions" at "/binary/modules/imageFunctions.xqy";
import module namespace rdrct = "http://lds.org/code/shared/ldse-edit/redirect-manager/functions" at "/redirect-manager/modules/functions.xqy";
import module namespace fast-json = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace mljson = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace xmpMM = "http://ns.adobe.com/xap/1.0/mm/";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace hldse = "http://lds.org/code/lds-edit/history";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace http = "xdmp:http";
declare namespace jsonify = "http://marklogic.com/xdmp/json";
declare namespace basic = "http://marklogic.com/xdmp/json/basic";

declare option xdmp:mapping "true";

declare variable $username as xs:string := image:get-image-crop-username();
declare variable $password as xs:string := image:get-image-crop-password();
declare variable $serviceUrl as xs:string := image:get-image-crop-service();

declare function getBcFolder($path as xs:string) as element(ldse:bc-folder)? {
    cts:search(/ldse:bc-folder,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('path'), $path, 'exact')
        ))
    )
};

declare function wildCardExtension($extension as xs:string) as xs:string {
    fn:concat('*.', $extension)
};

(:~
    Returns the folders and files for a particular directory
    @param vars all of the request variables sent in from the controller
    @return a JSON string
    TODO: need to define $images in a configuration file
~:)
declare function getDirectoryInfo($vars as node()?) as xs:string? {
    if ($vars/cpath eq 'first-buckets/') then (
        getFirstBuckets($vars)
    ) else (
        let $user as xs:string := ac:getUserName()
        let $path as xs:string? := $vars/cpath
        let $sort as xs:string? := $vars/sortBy
        let $images as xs:string* := ("jpg","gif","png")
        let $directories as xs:string* :=
             for $folder as element(ldse:bc-folder) in viewDirectory($path)
             let $name as xs:string? := $folder/ldse:name
             let $path as xs:string? := $folder/ldse:path
             order by $name
            return (
                fn:concat('{"path":"',$path,'","name":"',$name,'"}')
            )
        let $extensions as xs:string* :=
            if (fn:exists($vars/fileExt/item)) then (
                $vars/fileExt/item
            ) else if ($vars/fileExt ne '') then (
                $vars/fileExt
            ) else ()

        let $directories as xs:string? := fn:concat('"Folders":[',fn:string-join($directories,','),']')

        let $fileResults as element(search:response)? := getFiles($vars)
        let $files as xs:string? := fn:concat('"Files":[',fn:string-join( $fileResults/search:result/text() ,','),']')
        let $total as xs:string := fn:concat('"total":',$fileResults/@total)
        let $start as xs:string := fn:concat('"start":',$vars/start)
        let $end as xs:string := fn:concat('"end":',if ($vars/end > $fileResults/@total) then ($fileResults/@total) else ($vars/end))
        return fn:concat('{',fn:string-join( ($directories,$files,$total,$start,$end), ','),'}')
    )
};

declare function getFiles($vars as node()?) as element(search:response) {
    let $path as xs:string? := $vars/cpath
    let $extensions as xs:string* :=
        if (fn:exists($vars/fileExt/item)) then (
            $vars/fileExt/item
        ) else if ($vars/fileExt ne '') then (
            $vars/fileExt
        ) else ()
    let $start as xs:int := xs:int($vars/start)
    let $end as xs:int := xs:int($vars/end)
    let $options as element(search:options) :=
        <options xmlns="http://marklogic.com/appservices/search">
            <search-option>unfiltered</search-option>
            <searchable-expression>/binary-content</searchable-expression>
            <additional-query>{
                cts:and-query((
                 core:get-filter-query(),
                 if ($vars/articleUri ne '') then (
                     cts:element-value-query(xs:QName('article-uri'), $vars/articleUri, 'exact')
                 ) else (
                    cts:element-value-query(xs:QName('folder'), $path, 'exact')
                 ),
                 if (fn:exists($extensions)) then (
                     cts:element-value-query(xs:QName('file-name'), wildCardExtension($extensions), 'wildcarded')
                 ) else (),
                 if ($vars/fileType ne '' and $vars/fileType ne "all") then (
                     cts:element-value-query(xs:QName('type'), ($vars/fileType, 'all'), 'exact')
                 ) else ()
             ))
            }</additional-query>
            <transform-results apply="jsonFile" ns="http://lds.org/code/shared/lds-edit/burceFunctions" at="/ice/modules/burceFunctions.xqy" />
            <return-facets>false</return-facets>
            <return-results>true</return-results>
            <sort-order type="xs:string" direction="ascending">
                <element ns="" name="binary-title"/>
            </sort-order>
        </options>
    let $results as element(search:response) := search:search( "", $options, $start, $end - $start + 1)
    return (
        $results
    )
};

declare function jsonFile($file as node(), $ctsquery as schema-element(cts:query)?, $options as element(search:transform-results)?) as xs:string {
    fn:concat('{"path":"',$file/path,'","name":"',$file/title-block/binary-title,'","Id":"',$file/@id,'"}')
};

(:~
    Returns the top level directories/buckets
    @returns a JSON string
~:)
declare function getFirstBuckets($vars as node()?) as xs:string? {
    let $buckets as element(ldse:bc-folder)* :=
        for $folder as element(ldse:bc-folder) in viewDirectory("")
        order by $folder/ldse:name
        return (
            $folder
        )
    let $articleSpecific as element(bc-bucket)? :=
        if ($vars/articleUri ne '') then (
            <bc-folder xmlns="http://lds.org/code/lds-edit">
                <name>Content Specific</name>
                <path>{fn:concat($settings:binary-manager/ldse:root-path,$vars/contentType,'/',substring-after-last($vars/articleUri,'/'),'/')}</path>
                <permissions>
                    <users>
                        <user>
                            <name>all</name>
                            <access>rw</access>
                        </user>
                    </users>
                </permissions>
                <flag>{fn:true()}</flag>
            </bc-folder>
        ) else ()
    return fn:replace(json:serializeSet(fn:insert-before($buckets,1,$articleSpecific)),'bc-folder','Folders')

};

(:~
    Returns the file information in JSON format - should only be one file since we are using the ID
    @return a JSON string
    NOTE: this function takes the whole xml file for this piece of binary content and converts it to json
~:)
declare function getFileInfo($vars as node()) as xs:string? {
    let $content as element()? := getContentByID($vars/fileId)
    let $path as element(path)? := $content/path
    let $content as element()? :=
        if ( fn:exists($path) and $settings:use-image-prefix ) then (
            mem:node-replace($path, element path { fn:substring-after(core:get-display-uri($path), $settings:shared-prefix) })/*
        ) else if ( fn:exists($path) ) then (
            mem:node-replace($path, element path { core:get-display-uri($path) })/*
        ) else ( $content )
    return json:serialize($content,fn:true())
};

(:~
    Returns a boolean for success or failure of directory creation
    @return a boolean
~:)
declare function createFolder($vars as node()?) as xs:boolean? {
    let $dir as xs:string? := cleanupString($vars/name)
    let $parent as xs:string? := $vars/folderPath
    let $path as xs:string := fn:concat($parent,'/',$dir)
    let $modifyDirs as xs:boolean* :=
        if ($vars/action eq 'create') then (
            fn:true()
        ) else (
            (:deleteDirectory($path):)
        )
    let $existing as element(ldse:bc-folder)? := getBcFolder($path)
    let $updated as element(ldse:bc-folder) :=
            <bc-folder xmlns="http://lds.org/code/lds-edit">{
                attribute isPublic {fn:true()},
                element name {
                    if ($vars/name ne '') then (
                        xs:string($vars/name)
                    ) else (
                        $dir
                    )
                },
                element parent { $parent },
                element path { $path },
                if ( fn:exists($existing/permissions) ) then (
                    $existing/permissions
                ) else (
                    element permissions {
                        element users {
                            element user {
                                element name {'all'},
                                element access {'rw'}
                            }
                        }
                     }
                )
            }</bc-folder>

    let $dbPath as xs:string :=
        if ( fn:exists($existing) ) then (
            xdmp:node-uri($existing)
        ) else (
            core:build-db-path($path, "", "", $updated, ())
        )
    let $insert as empty-sequence() := core:save-file($dbPath, $updated, ())
    return $modifyDirs
};

(:~
    Returns the directory and file results of a search
    @return a JSON string
~:)
declare function search($vars as node()?) as xs:string? {
    let $wordOptions as xs:string* := (
        "case-insensitive","whitespace-insensitive","punctuation-insensitive",
        "diacritic-insensitive","wildcarded", fn:concat('lang=eng') )
    let $parse as element()? :=
        search:parse($vars/query,
                   <options xmlns="http://marklogic.com/appservices/search">
                       <term>{
                       for $option as xs:string in $wordOptions
                       return (
                           <term-option>{ $option }</term-option>
                       )
                       }</term>
                   </options>)
    let $wordQuery as cts:query := cts:query($parse)
    let $user as xs:string := fn:lower-case(ac:getUserName())
    let $extensions as xs:string* :=
        if (fn:exists($vars/fileExt/item)) then (
            $vars/fileExt/item
        ) else if ($vars/fileExt ne '') then (
            $vars/fileExt
        ) else ()
    let $fileResults as element()* :=
        cts:search(/binary-content,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('binary-content'), xs:QName('locale'), $vars/lang, 'exact'),
                (: cts:element-word-query(xs:QName('path'),$vars/currentPath), :)
                $wordQuery,
                if (fn:exists($extensions)) then (
                    cts:element-value-query(xs:QName('file-name'), wildCardExtension($extensions), $wordOptions)
                 ) else (),
                 if ($vars/fileType ne '' and $vars/fileType ne "all") then (
                     cts:element-value-query(xs:QName('type'), ($vars/fileType, 'all'), 'exact')
                 ) else ()
             ))
        )[ 1 to 1000]
    let $fileResults as element(binary-content)* :=
        for $i as element() in $fileResults
        return <binary-content>
                <Id>{fn:string($i/@id)}</Id>
                <path>{fn:string($i/path)}</path>
                <name>{ xs:string($i/title-block/binary-title)}</name>
               </binary-content>
    let $folderResults as element(ldse:bc-folder)* := () (:
        cts:search(/ldse:bc-folder,
            cts:and-query((
                core:core-get-filter-query(),
                cts:element-word-query(xs:QName('ldse:path'),fn:concat($vars/currentPath,'*'), 'wildcarded'),
                $wordQuery
            ))
        )[ldse:permissions/ldse:users/ldse:user/ldse:name eq ($user, 'all')] :)

    let $folderResults as element(Folders)* := () (:
        for $i as element(ldse:bc-folder) in $folderResults
        return (
            <Folders>
                <path>{ xs:string($i/ldse:path) }</path>
                <name>{ xs:string($i/ldse:name) }</name>
           </Folders>
        )       :)
    return
        if (fn:empty($fileResults)) then (
            '{"FILES":[]}'
        ) else (
             fn:replace(
                   (: fn:replace( :)
                       fn:replace(
                           fn:replace(
                               json:serializeSet(
                                           fn:insert-before($fileResults,1,$folderResults)
                                       )
                                   ,'"binary-content"','"Files"'
                           ),'"Files":\{','"Files":[{'
                    (:   ),'"Folders":\{','"Folders":[{' :)
                   ),'"\}\}','"}]}'
               )
       )
};

(:~
    Returns the known usage of the selected file
    @return a JSON string
    NOTE: this data is populated through a scheduled task that runs a script to
     store articles and their related binary content
~:)
declare function knownUsage($vars as node()?) as xs:string? {
    let $articles as element(article)* := cts:search(/known-usage/article[$vars/id eq bc-usage/content/@id], core:get-filter-query() )
    let $list as xs:string* :=
      for $i as element(article) in $articles
        let $name as xs:string? := $i/article-name
(:        let $link := layout:fixLink($i/article-uri):)
        let $link as xs:string? := $i/article-uri
        let $status as xs:string? := $i/article-status
        let $modDate as xs:string? := $i/mod-date
        let $modBy as xs:string? := $i/mod-by
        return (
            fn:concat('{"link":"',$link,'","title":"',$name,'","status":"',$status,'","modifiedDate":"',$modDate,'","modifiedBy":"',$modBy,'"}')
        )
    let $files as xs:string := fn:concat('{"Usage":[',fn:string-join($list,','),']}')

    return $files
};

declare function getDeepZoom() as xs:string?{
    let $deepZoom as element(ldse:deep-zoom)? := $settings:deep-zoom
    return(
        if(fn:exists($deepZoom)) then(
           let $zoomName as xs:string := $deepZoom/@name
           let $zoomNS as xs:string := $deepZoom/@ns
           let $zoomPath as xs:string := $deepZoom/@path
           return fn:concat('{"exists":"true"}')
        )else('{"exists":false}')
   )
};

(:~
    Saves XML for or Updates the XML for a file when either uploaded or an edit is made.
    @returns a JSON string with ID of newly uploaded file
~:)
declare function saveFileXml($vars as node()?) as xs:string? {
    let $lang as xs:string := $vars/lang
    let $fileId as xs:string := if ($vars/fileId ne '') then ($vars/fileId) else (util:generate-unique-id($lang))
    let $existing as element()? := getContentByID($fileId)
    let $existing as element()? := if ( fn:exists($existing) ) then ( $existing ) else( getContentByPath($vars/fpath) )
    let $new-title as xs:boolean := if ( fn:exists($vars/title) and fn:not(substring-before-last($existing/file-name, ".") = xs:string($vars/title))) then ( fn:true() ) else ( fn:false() )
    let $type as xs:string := fn:lower-case(fn:substring-after($existing/file-name, "."))
    let $isNew as xs:boolean := $vars/new = "true"
    let $path as xs:string :=
        if ( fn:exists($existing) and $vars/move = 'true' ) then (
            fn:string($vars/fpath),
            xdmp:trace('bcUpload','first')
        ) else if ( fn:exists($existing) and fn:not($new-title) ) then (
            fn:string($existing/path),
            xdmp:trace('bcUpload','second')
        ) else if ( fn:exists($existing) and $new-title and fn:not($isNew) ) then (
            fn:concat(substring-before-last(xs:string($existing/path), "/"), "/", xs:string($vars/title), ".", $type)
        ) else (
            fn:string($vars/fpath),
            xdmp:trace('bcUpload','third')
        )
    let $bcs as xs:string := $settings:bcs-path
    let $fsPath as xs:string := util:clean-db-uri(fn:concat($bcs,'/content/',$path))
    let $fs-exists as xs:boolean := is-image-used($path)
    return (
        if ( $fs-exists and $new-title ) then (
            fn:concat('{"error":"',"File Name Already Exists!",'"}')
        ) else (
            let $binary-title as xs:string :=
                if (fn:normalize-space($vars/title) ne '') then (
                    xs:string(util:escape-chars($vars/title))
                ) else if (fn:normalize-space($existing/title-block/binary-title) ne "") then (
                    xs:string($existing/title-block/binary-title)
                ) else (
                    substring-after-last($path,'/')
                )
            let $binary-title as xs:string :=
                if ( fn:contains($binary-title, ".") ) then (
                    $binary-title
                ) else (
                    fn:concat($binary-title, ".", $type)
                )
            let $fileId as xs:string :=
                if (fn:exists($existing)) then (
                    $existing/@id
                ) else ($fileId)
            let $image-processing as element()? := $existing/image-processing
            let $fileSystemPath as xs:string := fn:concat($settings:bcs-path,'/content',$vars/folder,"/", $binary-title)
            let $deepZoomXML as element(ldse:deep-zoom)? := $settings:deep-zoom
            let $deepZoom as xs:string? :=
                if($vars/deepZoom eq "true" and fn:exists($deepZoomXML)) then(
                    let $function as item() := xdmp:function(fn:QName(fn:string($deepZoomXML/@ns),fn:string($deepZoomXML/@name)),$deepZoomXML/@path)
                    return function:apply($function,$core:mode, $fileSystemPath, $vars/fileName, $vars/url, $vars/fileId)
                ) else()
            let $xmpMeta as element(xmpMeta)? := ()
(:                if ( fn:exists($existing) ) then (
                    $existing/xmpMeta
                ) else ( $vars/xmpMeta ):)
            let $dimensions as element(dimensions)? :=
                if ( fn:exists($existing/dimensions) ) then (
                    $existing/dimensions
                ) else ( $vars/xmpMeta/dimensions )
            let $fileSize as element(file-size)? :=
                if ( fn:exists($existing) ) then (
                    $existing/file-size
                ) else ( $vars/file-size )
            let $fileName as xs:string := $binary-title
            let $folder as xs:string := fn:substring-before($path, fn:concat('/',$fileName))
            let $articleUri as xs:string? :=
                if ($existing and $vars/move eq 'true') then (
                    $vars/articleUri
                ) else if ( fn:exists($existing) ) then (
                    $existing/article-uri
                ) else (
                    $vars/articleUri
                )
            let $uri as xs:string := fn:concat($settings:binary-manager-root-uri, substring-after-last($path, "/binary-content/"))
            let $public as xs:boolean := fn:empty($articleUri)
            let $fileType as xs:string := if (ends-with-any-of(fn:lower-case($uri),('gif','jpg','png','jpeg','bmp'))) then ('image') else ('other')
            let $finalPath as xs:string :=
                if ( fn:exists($existing) ) then (
                    xdmp:node-uri($existing)
                ) else (
                    core:build-db-path("", "", $fileId, <binary-content/>, <options><folder>{$folder}</folder></options>)
                )
            let $username as xs:string := ac:getUserName()
            let $userId as xs:string? := ac:getPersonId()
            let $content as element(binary-content) :=
                 element binary-content {
                    attribute id { $fileId },
                    attribute locale { "eng" },
                    attribute xml:lang { "eng" },
                    attribute public {$public},
                    attribute site {$core:site},
                    element meta {
                        element uri {
                            attribute its:translate {"no"},
                            $uri
                        },
                        element content-type {
                            attribute its:translate {"no"},
                            "binary-content"
                        },
                        element modifier {
                            attribute user-id {$userId},
                            attribute name {$username},
                            attribute date { fn:current-dateTime() }
                        },
                        element subjects {
                            if ($vars/tags ne '') then (
                                for $tag as xs:string in fn:tokenize($vars/tags,',')[fn:not(. eq ("''", ""))]
                                return element subject { util:escape-chars(fn:normalize-space($tag)) }
                            ) else if ( fn:exists($existing) ) then (
                                for $tag as xs:string in $existing/meta/subjects/subject[fn:not(. eq ("''", ""))]
                                return element subject { util:escape-chars(fn:normalize-space($tag)) }
                            ) else ()
                        }
                    },
                    element title-block {
                        element binary-title { $binary-title },
                        element description {
                            if ($vars/description ne "") then (
                                util:escape-chars($vars/description)
                            ) else if (fn:normalize-space($existing/title-block/description) ne "") then (
                                fn:string($existing/title-block/ldse:description)
                            ) else ()
                        },
                        element telescope {
                            if ($vars/telescope ne "") then (
                                util:escape-chars($vars/telescope)
                            ) else if ($existing/title-block/telescope ne "") then (
                                fn:string($existing/title-block/ldse:telescope)
                            ) else ()
                        },
                        element {"contract-id"} {
                            if ($vars/contractid ne "") then (
                                util:escape-chars($vars/contractid)
                            ) else if ($existing/title-block/contract-id ne "") then (
                                fn:string($existing/title-block/ldse:contract-id)
                            ) else ()
                        },
                        element {"contract-owner"} {
                            if ($vars/contractowner ne "") then (
                                util:escape-chars($vars/contractowner)
                            ) else if ($existing/title-block/contract-owner ne "") then (
                                fn:string($existing/title-block/ldse:contract-owner)
                            ) else ()
                        },
                        element type {$fileType}
                    },
                    element file-name { $fileName },
                    $fileSize,
                    $dimensions,
                    element folder { $folder },
                    element path {$path},
                    element final-path {$finalPath},
                    element article-uri {$articleUri},
                    element deepZoom {$deepZoom},
                    element thumbnail {
                        if ( fn:exists($existing) and $vars/move eq 'true') then (
                            fn:string($vars/thumbnail)
                        ) else if ( fn:exists($existing) ) then (
                            fn:string($existing/thumbnail)
                        ) else (
                            fn:string($vars/thumbnail)
                        )
                    },
                    if ( fn:not($isNew) ) then (
                        $image-processing
                    ) else (),
                    $xmpMeta
                }

            let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:get-meta($content, $fileId, "eng", $uri, "preview")
            let $content as element(binary-content) := mem:insert-child-first($content, $ldse-meta)
            let $clear-cache as item()* :=
                if ( fn:exists($existing) ) then (
                    image:clearBinaryCache($existing)
                ) else (
                    image:clearBinaryCache($content)
                )
            let $image-info as node()? :=
                if ( $vars/file ne '' ) then (
                    binary {
                        xs:hexBinary(
                            xs:base64Binary( fn:substring-after($vars/file, ',') )
                        )
                    }
                ) else (
                    try {
                        image:get-document-binary(util:clean-db-uri(fn:concat($bcs, '/content/', $existing/path)))
                    } catch ($e) {
                        xdmp:trace("saveBCerror", $e)
                    }
                )
            let $remove-old as item()* :=
                if ( $new-title and fn:exists($existing) ) then (
                    let $path as xs:string := ($vars/upath, $path)
(:                    let $rr-preview as element(redirectRules) := rdrct:get-redirect-rules($lang, "preview")
                    let $rr-published as element(redirectRules) := rdrct:get-redirect-rules($lang, "published"):)
                    let $new-display-url as xs:string := core:get-display-uri($path)
                    let $display-url as xs:string := core:get-display-uri($existing/path)
                    let $update as empty-sequence() := update-uses($existing/path, $path, $fsPath, $existing)

(:                    let $new-rr-preview as element() :=
                        rdrct:rebuild-redirect-rules(
                            <rule>
                                   <state>preview</state>
                                   <path>{$display-url}</path>
                                   <orig-path>{$display-url}</orig-path>
                                   <to>{$new-display-url}</to>
                                   <checked>true</checked>
                                   <published>true</published>
                            </rule>,
                            <redirectRules>{$rr-preview/(@*|node())}</redirectRules>,
                            "save",
                            xdmp:node-uri($rr-preview)
                        )
                    let $save-preview as empty-sequence() := core:document-replace($rr-preview, $new-rr-preview)
                    let $new-rr-published as element() :=
                        rdrct:rebuild-redirect-rules(
                            <rule>
                                   <state>publish</state>
                                   <path>{$display-url}</path>
                                   <orig-path>{$display-url}</orig-path>
                                   <to>{$new-display-url}</to>
                                   <checked>true</checked>
                                   <published>true</published>
                            </rule>,
                            <redirectRules>{$rr-published/(@*|node())}</redirectRules>,
                            "publish",
                            xdmp:node-uri($rr-published)
                        )
                    let $save-publish as empty-sequence() := core:document-replace($rr-published, $new-rr-published):)
                    return (
                        fs:delete(fn:concat($settings:bcs-path, '/content', xs:string($existing/path))),
                        fs:save($fsPath, $image-info)
                    )
                ) else ()

            let $crop as element(binary-content)? :=
                if ( fn:exists(xdmp:get-request-field('width')[. != ""]) and fn:exists(xdmp:get-request-field('height')[. != ""])  and $isNew and $settings:auto-crop = "true") then (
                    let $aspectRatios as element(ldse:aspect-ratio)* := image:get-aspect-ratios($image-processing)
                    return (
                        save-crops($content)
                    )
                ) else (
                    $content
                )
            return (
                try {
                   core:save-file($finalPath, $crop, ()),
                   fn:concat('{"id":"',$fileId,'","title":"',json:escape($content/title-block/binary-title),'","path":"',core:get-display-uri($path),'"}')
                } catch($e){
                   xdmp:trace("saveBCerror", $e)
                }
           )
       )
   )
};

(:~
    Uploads the file
    @returns as string the path of uploaded file
~:)
declare function uploadFile($vars as node()?) as xs:string? {
    let $bcs as xs:string := $settings:bcs-path
    let $path as xs:string := $vars/upath
    let $fsPath as xs:string := util:clean-db-uri(fn:concat($bcs,'/content/',$path))
    let $content as node()? :=
        if ($vars/file ne '') then (
            binary{
                xs:hexBinary(
                    xs:base64Binary( fn:substring-after($vars/file, ',') )
                )
            }
        ) else (
            xdmp:document-get(util:clean-db-uri(fn:concat($bcs,'/content/',$vars/filePath)),
                <options xmlns="xdmp:document-get">
                   <format>binary</format>
                </options>
            )
        )

    let $articleUri as xs:string? := $vars/articleUri
    let $name as xs:string := fn:concat(cleanupString(substring-before-last($vars/fileName,'.')),'.',substring-after-last($vars/fileName,'.'))
    let $fileExtension as xs:string := fs:getFileTypeFromFileExtension($name)
    let $height as xs:string? := $vars/height
    let $width as xs:string? := $vars/width
    let $fileAlreadyExists as xs:boolean := fn:false() (: xdmp:filesystem-file-length($fsPath) > 0 :)
    let $saveToBCS as xs:boolean :=
        if (fn:not($fileAlreadyExists)) then (
            try {
                fs:save($fsPath, $content),fn:true()
            } catch($e) { fn:false() }
        ) else ( fn:false() )
    let $finalPath as xs:string :=
        if ($settings:binary-manager/ldse:image-processing/@active eq 'true' and xs:integer($width) gt xs:integer($settings:binary-manager/ldse:image-processing/ldse:max-size)) then (
            let $response as element(response) := createThumb($name,$path,fn:true())
            let $saveImg as empty-sequence() := fs:save($fsPath,xdmp:document-get($response/outUrl))
            let $deleteJob as item()+ := deleteJob($response/jobKey,$response/callerCode)
            return $path
        ) else ($path)

    let $thumbPath as xs:string? :=
        if (
            $vars/thumbnail eq "" and
            fn:string($settings:binary-manager/ldse:image-processing/@active) eq 'true' and
            (xs:integer($width) gt xs:integer($settings:binary-manager/ldse:image-processing/ldse:create-thumb-size) or
             xs:integer($height) gt xs:integer($settings:binary-manager/ldse:image-processing/ldse:create-thumb-size))
        ) then (
            let $response as element(response) := createThumb($name,$finalPath,fn:false())
            let $finalThumbPath as xs:string := fn:concat($bcs, '/content', fn:replace($finalPath,"\.","_thumb."))
            let $saveThumb as empty-sequence() :=
                fs:save($finalThumbPath,
                    xdmp:document-get($response/outUrl,
                        <options xmlns="xdmp:http">
                            <verify-cert>false</verify-cert>
                            <headers>
                                <content-type>application/json</content-type>
                            </headers>
                        </options>
                    )
                )
            let $deleteJob as item()+ := deleteJob($response/jobKey,$response/callerCode)
            return $finalThumbPath
        ) else if ($vars/thumbnail ne '') then (
            let $finalThumbPath as xs:string := fn:concat($bcs, '/content', fn:replace($finalPath,"\.","_thumb."))
            let $saveThumb as empty-sequence() := fs:save($finalThumbPath,xdmp:document-get($vars/thumbnail))
            return $finalThumbPath
        ) else ()
    let $svars as element(vars) :=
        <vars>
            { $vars/lang }
            <fpath>{$finalPath}</fpath>
            <fileId>{ fn:string($vars/id) }</fileId>
            <file-size>{ xdmp:binary-size(binary{ $content}) }</file-size>
            <contentType>{ fn:string($vars/contentType) }</contentType>
            <articleUri>{$articleUri}</articleUri>
            <thumbnail>{$thumbPath}</thumbnail>
            <move>{ fn:string($vars/move) }</move>
            {
                if ( fn:not($vars/move = "true") ) then (
                    <new>true</new>
                ) else ()
            }
            {
                if ( settings:extract-meta($fileExtension) ) then (
                    getXmpInfo( $content )
                ) else ()
            }
        </vars>
    let $save as xs:string? :=
        if ($fileAlreadyExists) then (
            '{"error":"File Already Exists"}'
        ) else if ($saveToBCS) then (
            saveFileXml($svars)
        ) else ('{"error":"Save Failed"}')
    return
        $save
};

(:~
    Returns ....
    @return a string .....something
    TODO...this is preliminary, and not plugged into the front end yet.
~:)
declare function moveFile($vars as node()) as xs:string? {
    let $newPath as xs:string? := $vars/newPath
    let $newArticle as xs:string? := $vars/newArticleUri
    let $fileID as xs:string? := $vars/fileId
    let $content as element()? := getContentByID($vars/fileId)
    let $binPath as xs:string? := $content/path
    let $thumb as xs:string? := if ($content/thumbnail ne '') then ($content/thumbnail) else ()
    let $mvars as element(vars) :=
        <vars>
            { $vars/lang }
            <upath>{$newPath}</upath>
            <fileId>{ fn:string($vars/fileId) }</fileId>
            <filePath>{$binPath}</filePath>
            { if ($newArticle ne '') then (<articleUri>{$newArticle}</articleUri>) else () }
            <thumbnail>{$thumb}</thumbnail>
            <move>{fn:true()}</move>
            { $content/xmpMeta }
            { $content/file-size }
        </vars>

    let $move as xs:string := if ($newPath ne $binPath) then (uploadFile($mvars)) else ('false')

    let $deleteOld as xs:boolean? :=
        if ($newPath ne $binPath) then (
            deleteFile(<vars><fileId>{ fn:string($vars/fileId) }</fileId></vars>)
        ) else (fn:false())
    return fn:concat($move)
};

(:~
    Creates a thumbnail and/or resizes images based on dimensions of uploaded file.
    This uses the Image Cropping/Processing Service https://archipedia.ldschurch.org/wiki/index.php/Image_Cropping/Processing_Service
    @param name  name of the file to be resized
    @param path  path of the file to be resized
    @param maxWidth  boolean value of whether or not to resize to the maximum width allowed
    @return a node

    TODO: where should credentials be???
    There is concern about them being viewable by all
~:)
declare function createThumb($name as xs:string?, $path as xs:string?, $maxWidth as xs:boolean?) as element(response) {
    let $width as xs:string? :=
        if ($maxWidth) then (
            $settings:binary-manager/ldse:image-processing/ldse:max-size
        ) else (
            $settings:binary-manager/ldse:image-processing/ldse:thumb-size
        )
    let $src-img-data as xs:base64Binary? := xs:base64Binary(xdmp:document-get($path))
    let $out-filename as xs:string :=
        if ($maxWidth) then ( $name ) else ( fn:replace($name,"\.","_thumb.") )
    let $creds as element(image-processing) := cts:search(/image-processing, core:get-filter-query())
    let $user as xs:string := $creds/user
    let $pass as xs:string := $creds/pass
    let $server as xs:string := $creds/server

    let $payload as xs:string := fn:concat('{
                "callerCode": "', $settings:binary-manager/image-processing/caller-code, '",
                "jobKey": "', fn:substring-before($name,'.'), '",
                "srcFilename": "', $name, '",
                "srcImgData": "', $src-img-data, '",
                "transforms": [
                                {"commands": [
                                                {"command": "-resize", "options": "', xdmp:base64-encode(fn:concat($width,'x',$width)), '"},
                                                {"command": "+profile", "options": "', xdmp:base64-encode('*'), '"}
                                ],
                                "outFilename": "', $out-filename, '"}]}')

    let $response as item()+ := util:http-post($server,
        <options xmlns="xdmp:http">
            <data>{$payload}</data>
            <verify-cert>false</verify-cert>
            <authentication method="basic">
                <username>{$user}</username>
                <password>{$pass}</password>
            </authentication>
            <headers>
                <content-type>application/json</content-type>
            </headers>
        </options>)
    let $map as item()* := xdmp:from-json(xdmp:quote($response[2]/node()))
    let $debug as empty-sequence() :=
        xdmp:trace("BCAPI",
            <response>
               <jobKey>{map:get($map,'jobKey')}</jobKey>
               <callerCode>{map:get($map,'callerCode')}</callerCode>
               <outUrl>{map:get(map:get($map,'transforms'),'outUrl')}</outUrl>
            </response>
        )

    return <response>
               <jobKey>{map:get($map,'jobKey')}</jobKey>
               <callerCode>{map:get($map,'callerCode')}</callerCode>
               <outUrl>{map:get(map:get($map,'transforms'),'outUrl')}</outUrl>
           </response>
};

(:~
    Deletes the job created by createThumb for the Image Cropping/Processing Service.
    @param jobKey  job key for the file processed (based off of the filename)
    @param callerCode  caller code for the file processed (set up by the Image Cropping/Processing Service people)
    @return an optional response

    TODO: where should credentials be???
    There is concern about them being viewable by all
~:)
declare function deleteJob($jobKey as xs:string?, $callerCode as xs:string?)as item()+ {
    let $creds as element(image-processing) := cts:search(/image-processing, core:get-filter-query())
    let $user as xs:string := $creds/user
    let $pass as xs:string := $creds/pass
    return xdmp:http-delete(fn:concat('https://ws-stage.ldschurch.org/ws/imagetrans/v1.0/Services/rest/job/',$callerCode,'/',$jobKey),
        <options xmlns="xdmp:http">
            <verify-cert>false</verify-cert>
            <authentication method="basic">
                <username>{$user}</username>
                <password>{$pass}</password>
            </authentication>
        </options>)
};

(:~
    Deletes the file and thumbnail (actually just makes it file size zero, one shortcoming of Marklogic).
    XML related to the file is also deleted.
    @return an optional response
~:)
declare function deleteFile($vars as node()?) as xs:boolean? {
    let $id as xs:string := if ($vars/fileId ne '') then ($vars/fileId) else ($vars/uri)
    let $doc as element()? :=
        if ($vars/fileId ne '') then (
            getContentByID($id)
        ) else (
            cts:search(/binary-content[meta/uri eq $id], core:get-filter-query() )
        )
    let $clear-cache as item()* := image:clearBinaryCache($doc)
    let $delete as item() :=
        try {
           fs:delete(fn:concat($settings:bcs-path,'/content',$doc/path)),
           if ($doc/thumbnail ne '') then ( fn:concat($settings:bcs-path,'/content',$doc/thumbnail) ) else (),
           $doc/xdmp:document-delete(fn:base-uri(.)),
           fn:true()
           (:<result severity='INFO' timestamp='{ fn:current-dateTime() }'>
               <message>Successfully deleted.</message>
           </result>:)
        } catch ($e) {
          (:<result severity='ERROR' timestamp='{ fn:current-dateTime() }'>
               <message>{ fn:concat(fn:data($e/error:code), ': ', $e/error:message) }</message>
           </result>,:)
           fn:false()
        }
    return $delete
};

(:~
    Returns the valid extensions
    @return a JSON string
~:)
declare function getFileTypes($vars as node()?) as xs:string? {
    json:serializeSet($settings:binary-manager-extensions)
};

(:Functions brought in from Seminary Modules:)
(:
    Gets the second to last substring value
:)
declare function substring-before-last($arg as xs:string?, $delim as xs:string?) as xs:string {
   if (fn:matches($arg, escape-for-regex($delim)))
   then fn:replace($arg, fn:concat('^(.*)', escape-for-regex($delim),'.*'),'$1')
   else ''
};

(:  regex escape replacements  :)
declare function escape-for-regex($arg as xs:string?) as xs:string {
   fn:replace($arg,'(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
};

(:  Gets the final substring after final match  :)
declare function substring-after-last($arg as xs:string?, $delim as xs:string?) as xs:string {
   fn:replace($arg, fn:concat('^.*',escape-for-regex($delim)),'')
};

(:  returns true if any matching end of string  :)
declare function ends-with-any-of($arg as xs:string?, $searchStrings as xs:string*) as xs:boolean {
   some $searchString in $searchStrings
   satisfies fn:ends-with($arg,$searchString)
};

(:  general string cleanup  :)
declare function cleanupString($string as xs:string) as xs:string {
    let $newString as xs:string := fn:replace($string, "([`~!@#\$%\^\*\(\)\+={}\[\]:;'Ã¢â‚¬â„¢Ã¢â‚¬ï¿½Ã¢â‚¬Å“<>,\.\?&#34;])", "")
    let $newString as xs:string := fn:replace($newString, "(\.\.\.)|(&amp;)|([Ã¢â‚¬â€�Ã¢â‚¬Â¦Ã¢â‚¬â€œ:Ã‚Â¦/\\Ã¢â‚¬â€œ\|])", "-")
    let $debug as empty-sequence() := xdmp:trace("utilQuery", fn:concat("cleanupString:", xdmp:elapsed-time()))
    return $newString

};

(: searches all binary-content for matching id :)
declare function getContentByID($id as xs:string?) as node()* {
     cts:search(/binary-content,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('binary-content'), xs:QName('id'), $id, 'exact')
         ))
    )
};

(: searches all binary-content for matching path :)
declare function getContentByPath($path as xs:string?) as node()* {
     cts:search(/binary-content,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('path'), $path, 'exact')
         ))
    )
};


(:~
    Retrieves the contents of the filesystem directory
    depending on the type of content requested.

    @param $path The uri of the directory
    @param $type The type of content ("file" or "directory")

    @return xml of directory contents
~:)
declare function viewDirectory($path as xs:string?) as element(ldse:bc-folder)* {
    cts:search(/ldse:bc-folder,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('ldse:parent'), $path, 'exact')
        ))
    )
};

declare function stringToHex( $str as xs:string ) as xs:string {
    fn:upper-case( fn:string-join( for $c as xs:integer in fn:string-to-codepoints( $str ) return xdmp:integer-to-hex( $c ), "" ) )
};

declare function node-is-png(
    $img as node()?
) as xs:boolean {
    substring(xs:string( xs:hexBinary( $img ) ), 1, 16) = "89504E470D0A1A0A"
};

declare function get-png-dimensions(
    $img as node()?
) as element(dimensions)? {
    if (node-is-png($img)) then (
        (: IHDR chunk has a length (4 bytes), type (4 bytes), width (4 bytes), length (4 bytes)
         : double all starting points and character positions since it's hex :)
        let $width-height-hex := fn:substring(xs:string( xs:hexBinary( $img ) ), 33, 16),
            $width as xs:int := xdmp:hex-to-integer(substring($width-height-hex, 1, 8)),
            $height as xs:int := xdmp:hex-to-integer(substring($width-height-hex, 9, 8))
        return
            element dimensions {
                element width { $width },
                element height { $height }
            }
    ) else ()
};

declare function node-is-jpg(
    $img as node()?
) as xs:boolean {
    substring(xs:string( xs:hexBinary( $img ) ), 1, 4) = "FFD8"
};

declare function get-jpg-dimensions(
    $img as node()?
) as element(dimensions)? {
    if (node-is-jpg($img)) then (
        (: JPG FFC0 or FFC2 portion has a length (1 byte), width (4 bytes), length (4 bytes)
         : double all starting points and character positions since it's hex :)
        let $width-height-hex := fn:substring(fn:tokenize(xs:string( xs:hexBinary( $img ) ), "FFC[02]")[fn:last()], 7, 8),
            $width as xs:int := xdmp:hex-to-integer(substring($width-height-hex, 1, 4)),
            $height as xs:int := xdmp:hex-to-integer(substring($width-height-hex, 5, 4))
        return
            element dimensions {
                element width { $width },
                element height { $height }
            }
    ) else ()
};

declare function get-xmpmeta-name(
    $meta as element(xhtml:meta)
) as xs:string {
    (: replace extra '_' with one '_' :)
    fn:replace(
        (: remove some xmp stuff :)
        fn:replace(
            fn:lower-case(xdmp:diacritic-less($meta/@name)),
            '[^a-z0-9_]|xmp_dc_|xmp_',
            ''
        ),
        '_+',
        '_'
    )
};

declare function getXmpInfo( $img as node()? ) as element(xmpMeta) {
    if (fn:function-available("xdmp:document-filter")) then (
        let $xmpMeta as element(xhtml:meta)* := xdmp:document-filter($img)/xhtml:html/xhtml:head/xhtml:meta
        return (
            element xmpMeta {
                for $meta as element(xhtml:meta) in $xmpMeta
                let $name as xs:string? := get-xmpmeta-name($meta)

                let $name as xs:string :=
                    if (fn:matches($name, '^[0-9].*') or $name eq '') then (
                        fn:concat('meta_', $name)
                    ) else (
                        $name
                    )
                let $value as xs:string := $meta/@content
                (: don't use the dimensions from the meta :)
                where $name != 'dimensions'
                return (
                    element {$name} {$value}
                ),
                (: add the dimension element :)
                get-xmpmeta-dimensions($img, $xmpMeta/xhtml:meta[get-xmpmeta-name(.) = "dimensions"])
            }
        )
    ) else (
        let $start-tag-hex as xs:string := stringToHex( "<x:xmpmeta" )
        let $end-tag-hex as xs:string := stringToHex( "</x:xmpmeta>" )
        let $xmp as xs:string := fn:substring-after(fn:substring-before( xs:string( xs:hexBinary( $img ) ), $end-tag-hex ), $start-tag-hex )
        let $xmpData as element()? := if( $xmp = "" ) then () else ( xdmp:unquote( xdmp:quote( binary { xs:hexBinary( fn:concat( $start-tag-hex, $xmp, $end-tag-hex) ) } ) )/* )
        let $imageId as xs:string? := $xmpData/rdf:RDF/rdf:Description/@xmpMM:OriginalDocumentID
        let $imageId as xs:string? := fn:substring-after($imageId, "uuid:")
        let $title as xs:string? := $xmpData/rdf:RDF/rdf:Description/dc:title/rdf:Alt/rdf:li
        let $creator as xs:string? := $xmpData/rdf:RDF/rdf:Description/dc:creator/rdf:Seq/rdf:li
        let $rights as xs:string? := $xmpData/rdf:RDF/rdf:Description/dc:rights/rdf:Alt/rdf:li
        let $tags as element(rdf:Bag)* := $xmpData/rdf:RDF/rdf:Description/dc:subject/rdf:Bag
        return (
            element xmpMeta {
                attribute id {$imageId},
                element title {$title},
                element creator {$creator},
                element rights {$rights},
                element tags {
                   for $tag as xs:string in $tags/rdf:li
                   return element tag {$tag}
                },
                get-xmpmeta-dimensions($img)
            }
        )
    )
};

declare function update-uses($old-path as xs:string, $new-path as xs:string, $fsPath as xs:string, $existing as element()) as empty-sequence() {
    let $old-image-name as xs:string := substring-after-last($old-path, "/")
    let $new-image-name as xs:string := substring-after-last($new-path, "/")
    let $old-folders as xs:string := substring-before-last($old-path, "/")
    let $new-folders as xs:string := substring-before-last($new-path, "/")
    let $update-uses as empty-sequence() := update-crop-uses($old-image-name, $new-image-name, $old-folders, $new-folders, $fsPath, $existing)
    for $element as element() in cts:search(/*,
                                    cts:and-query((
                                        core:get-filter-query(),
                                        cts:not-query(cts:element-query(xs:QName("binary-content"), cts:and-query(( () )))),
                                        cts:not-query(cts:element-query(xs:QName("ldse:clear-cache-log-entry"), cts:and-query(( () )))),
                                        cts:not-query(cts:element-query(xs:QName("redirectRules"), cts:and-query(( () )))),
                                        cts:not-query(cts:element-query(xs:QName("rewriteRules"), cts:and-query(( () )))),
                                        cts:or-query((
                                            cts:element-attribute-value-query((xs:QName("img"), xs:QName("xhtml:img")), xs:QName("src"), $old-image-name, "exact"),
                                            cts:word-query($old-image-name, "exact")
                                        ))
                                    ))
                                )

    return (
        if ( fn:exists($existing/image-processing/crop) ) then (
            let $update as xs:string := xdmp:quote($element)
            let $update as xs:string := fn:replace($update, fn:concat($old-folders, "/", "([0-9]+)x([0-9]+)/", util:escape-for-regex($old-image-name)), fn:concat($new-folders, "/", "$1x$2/", $new-image-name))
            let $update as xs:string := fn:replace($update, util:escape-for-regex($old-path), $new-path)
            let $update as element() := xdmp:unquote($update)/*
            return (
                core:document-replace($element, $update)
            )
        ) else (
            let $update as xs:string := xdmp:quote($element)
            let $update as xs:string := fn:replace($update, util:escape-for-regex($old-path), $new-path)
            let $update as element() := xdmp:unquote($update)/*
            return (
                core:document-replace($element, $update)
            )
        )
    )
};

declare function update-crop-uses(
    $old-image-name as xs:string,
    $new-image-name as xs:string,
    $old-folders as xs:string,
    $new-folders as xs:string,
    $fsPath as xs:string,
    $existing as element()
) as empty-sequence() {
    for $crops as element() in $existing/image-processing/crop
    return (
        for $crop as element() in $crops/resize
        let $crop-size as xs:string := $crop/@options
        let $old-path as xs:string := fn:concat($settings:bcs-path, '/content', $old-folders, "/", $crop-size, "/", $old-image-name)
        let $new-path as xs:string := fn:concat($settings:bcs-path, '/content', $new-folders, "/", $crop-size, "/", $new-image-name)
        let $image-info as node()? :=
            try {
                image:get-document-binary(util:clean-db-uri($old-path))
            } catch ($e) {
                xdmp:trace("saveBCerror", $e)
            }
        let $save as empty-sequence() := fs:save(util:clean-db-uri($new-path), $image-info)
        return (
            fs:delete($old-path)
        )
    )
};

declare function is-image-used($path as xs:string) as xs:boolean {
    fn:exists(
        cts:search(/*,
            cts:and-query((
                core:get-filter-query(),
                cts:element-query(xs:QName("binary-content"), cts:and-query(( () ))),
                cts:element-value-query(xs:QName("path"), $path, "exact")
            ))
        )[1]
    )
};

declare function createThumbnail($ratio as element(), $imageXml as element(binary-content)?) as element(html:div) {
    let $rw as xs:double := image:get-aspect-ratio-w($ratio)
    let $rh as xs:double := image:get-aspect-ratio-h($ratio)
    let $name as xs:string := image:get-aspect-ratio-name($ratio)
    let $croppedImage as element(crop)? := image:get-cropped-image($imageXml, $name)
    let $x1 as xs:integer? := image:get-cropped-image-x1($croppedImage)
    let $y1 as xs:integer? := image:get-cropped-image-y1($croppedImage)
    let $x2 as xs:integer? := image:get-cropped-image-x2($croppedImage)
    let $y2 as xs:integer? := image:get-cropped-image-y2($croppedImage)
    let $options as element()* := $ratio/resize
    let $new-ratio as element()* := if ( fn:exists($options) ) then ( $options ) else ( $ratio/ldse:size )
    return (
        <div class="thumbnail" xmlns="http://www.w3.org/1999/xhtml">
            <div>{$name}</div>
            <div>
                <canvas
                    data-aspect-ratio-name="{$name}"
                    data-aspect-ratio="{$rw div $rh}"
                    data-selection-x1="{$x1}"
                    data-selection-x2="{$x2}"
                    data-selection-y1="{$y1}"
                    data-selection-y2="{$y2}"
                    width="150"
                    height="{xs:integer(fn:round(150 * $rh div $rw))}"
                />
                <div class="dimensionList">
                    <div><u>Saved Sizes</u></div>
                    <ul>

                    {
                    for $dimensions as xs:string in $new-ratio/@options
                     return <li>{$dimensions}</li>
                    }
                    </ul>
                </div>
            </div>
        </div>
    )
};

declare function get-xmpmeta-dimensions(
    $img as node()?
) as element(dimensions) { get-xmpmeta-dimensions($img, ()) };

declare function get-xmpmeta-dimensions(
    $img as node()?,
    $dimensions as xs:string?
) as element(dimensions) {
    let $jpg-dimensions as element(dimensions)? := get-jpg-dimensions($img)
    let $png-dimensions as element(dimensions)? := get-png-dimensions($img)

    let $width-height := fn:tokenize($dimensions, '[^0-9]')[. ne '']
    return
        element dimensions {
            element width { ($width-height[1], $jpg-dimensions/width/fn:string(), $png-dimensions/width/fn:string(), 0)[1] },
            element height { ($width-height[2], $jpg-dimensions/height/fn:string(), $png-dimensions/height/fn:string(), 0)[1] }
        }
};

declare function extract-job-key($outputImageUrl as xs:string) as xs:integer {
    xs:integer(fn:tokenize($outputImageUrl, "/")[fn:last() - 1])
};

declare function save-image-to-filesystem($outputImageUrl as xs:string, $newImageFilename as xs:string) as empty-sequence() {
    fs:save($newImageFilename, image:get-document-binary($outputImageUrl))
};

(:
    See http://www.graphicsmagick.org/GraphicsMagick.html#details-resize for details on the flags for resize
:)
declare function save-crops($imageXml as element(binary-content)?) as element()? {
    if ( fn:exists($imageXml) ) then (
        let $imageName as xs:string := image:get-image-name($imageXml)
        let $imageFilename as xs:string := image:get-image-filesystem-path($imageXml)
        let $imageData as item()* := xs:base64Binary(image:get-document-binary($imageFilename))
        let $imageDirectory as xs:string := image:get-image-filesystem-directory($imageXml)
        let $currentKey as xs:integer := -1
        let $outputUrl as xs:string := image:get-image-crop-output()
        let $extension as xs:string := util:get-file-extension($imageName)


        let $crops-and-resizes as element(crop)* :=
            let $aspectRatios as element()* := image:get-aspect-ratios($imageXml)
            for $aspectRatio as element() at $ci in $aspectRatios
            let $aspectRatioName as xs:string? := image:get-aspect-ratio-name($aspectRatio)
            let $cropOptions as xs:string :=
                (if ( xdmp:get-request-field('fn') = "upload") then (
                    let $ratio as xs:double := xs:double( $aspectRatio/@w ) div xs:int( $aspectRatio/@h )
                    let $image-width as xs:int := xs:int( xdmp:get-request-field('width') )
                    let $image-height as xs:int := xs:int( xdmp:get-request-field('height') )

                    let $largest-width as xs:int := xs:int( fn:floor( $ratio * $image-height) )
                    let $largest-height as xs:int := xs:int( fn:floor( $image-width div $ratio) )
                    let $option :=
                        if ( $largest-width > $image-width ) then (
                            let $new-height as xs:int := xs:int( fn:floor( $image-width div $ratio) )
                            return (
                                fn:concat($image-width, "x", $new-height, "+0+0")
                            )
                        ) else if ($largest-height > $image-height) then (
                            let $new-width as xs:int := xs:int( fn:floor( $ratio * $image-height) )
                            let $new-x as xs:int := fn:floor( ( $image-width - $new-width ) div 2 )
                            return (
                                fn:concat($new-width, "x", $image-height, "+", $new-x, "+0")
                            )
                        ) else (
                            (: use largest :)
                            fn:concat($largest-width, "x", $largest-height, "+0+0")
                        )
                    return $option
                ) else (
                    xdmp:get-request-field($aspectRatioName)
                ))[1]
            let $resize as element()* := $aspectRatio/resize
            let $sizes as element()* := if ( fn:exists($resize) ) then ( $resize ) else ( $aspectRatio/ldse:size )

            return (
                 <crop aspect-ratio-name="{$aspectRatioName}" key="{$currentKey}">
                   {$aspectRatio}
                   <options>{$cropOptions}</options>{
                        for $aspectRatioSize as element() at $ai in $sizes
                        let $resize-dimensions as xs:string? := image:get-aspect-ratio-size-options($aspectRatioSize)
                        let $resize-flags as xs:string? := image:get-aspect-ratio-size-flags($aspectRatioSize)
                        let $randomId as xs:string := xdmp:hmac-sha1("", fn:concat(xdmp:request(), fn:current-dateTime(), xdmp:elapsed-time(), fn:generate-id(text {()}) ) )
                        let $outputImageName as xs:string := fn:concat($resize-dimensions, "-", $randomId, ".", $extension)
                        let $currentKey as xs:int := $ci * $ai
                        return (
                           <resize>
                               {$aspectRatioSize}
                               <url>{fn:concat($outputUrl, "/", $username, "/", $currentKey, "/", $outputImageName)}</url>
                               <json>{
                                    fast-json:obj((
                                        fast-json:keyObject("commands",
                                            fast-json:arr((
                                                fast-json:obj((
                                                    fast-json:keyValue("command", "-crop"),
                                                    fast-json:keyValue("options", xdmp:base64-encode($cropOptions))
                                                )),
                                                fast-json:obj((
                                                    fast-json:keyValue("command", "-resize"),
                                                    fast-json:keyValue("options", xdmp:base64-encode($resize-dimensions || $resize-flags))
                                                )),
                                                fast-json:obj((
                                                    fast-json:keyValue("command", "+profile"),
                                                    fast-json:keyValue("options", fn:concat("'", xdmp:base64-encode('*'), "'"))
                                                ))
                                            ))
                                        ),
                                        fast-json:keyValue("outFilename", $outputImageName)
                                    ))
                                }</json>
                           </resize>
                       )
                   }</crop>
           )

        let $crops as element(crop)* := $crops-and-resizes

        let $payload as item()* :=
            fast-json:obj((
                fast-json:keyValue("callerCode", $username),
                fast-json:keyValue("jobKey", xs:string($crops[fn:last()]/@key)),
                fast-json:keyValue("srcFilename", $imageName),
                fast-json:keyValue("srcImgData", xs:string($imageData)),
                fast-json:keyObject("transforms", fast-json:arr(($crops/resize/json/fn:string(.))))
            ))

        let $post as item()* :=
            util:http-post(
                $serviceUrl,
                <options xmlns="xdmp:http">
                    <data>{$payload}</data>
                    <verify-cert>false</verify-cert>
                    <authentication method="basic">
                        <username>{$username}</username>
                        <password>{$password}</password>
                    </authentication>
                    <headers>
                        <content-type>application/json</content-type>
                    </headers>
                    <format xmlns="xdmp:document-get">text</format>
                </options>
            )

        let $response-header as item()* := $post[1]
        let $response as item() := $post[2]
        let $response-xml as item()* :=
            if ( fn:not($response-header/code = "200") ) then (
                try {
                    util:map-xml(mljson:transform-from-json($response, mljson:config('basic')), "response")
                } catch ( $e ) {
                    xdmp:trace("ldsedit-ImageCropper", ("Post to Image Cropper Service Failed", $post))
                }
            ) else ()

        let $trace as empty-sequence() :=
            if ( fn:not($response-header/http:code/fn:string(.) = "200") ) then (
                xdmp:trace("ldsedit-ImageCropper", ("Post to Image Cropper Service Failed", $post)),
                xdmp:trace("ldsedit-ImageCropper", ("Payload sent to Image Cropper Service", fn:replace($payload, 'srcImgData":?".*?"', 'srcImgData": "BINARY REMOVED FOR BREVITY, TO INSPECT BINARY, ENABLE TRACE EVENT FOR ldsedit-ImageCropper-Binary"'))),
                xdmp:trace("ldsedit-ImageCropper-Binary", ("Binary sent to Image Cropper Service", fn:replace($payload, '^.*srcImgData":?"(.*?)".*$', "$1")))
            ) else ()
        let $save-images as empty-sequence() :=
            for $outputImageUrl as xs:string in $response-xml//((jsonify:entry|map:entry)[@key eq "outUrl"]|basic:outUrl)/node()/fn:string(.)
            let $outputImageName as xs:string := fn:replace($outputImageUrl, ".*[\\/]", "")
            let $options as xs:string := fn:substring-before($outputImageName, "-")
            let $resizedImageFilename as xs:string := fn:concat($imageDirectory, "/", $options, "/", $imageName)
            return save-image-to-filesystem($outputImageUrl, $resizedImageFilename)

        let $imageXmlCropping as element(crop)* :=
            for $crop as element(crop) in $crops
            let $aspectRatioName as xs:string := ($crop/ldse:aspect-ratio/@name, $crop/@aspect-ratio-name)[1]
            let $options as xs:string := $crop/options
            let $temp as xs:string* := fn:tokenize($options, "[^0-9]")
            let $width as xs:integer := xs:integer($temp[1])
            let $height as xs:integer := xs:integer($temp[2])
            let $x as xs:integer := xs:integer($temp[3])
            let $y as xs:integer := xs:integer($temp[4])
            return (
                <crop aspect-ratio-name="{$aspectRatioName}" width="{$width}" height="{$height}" x="{$x}" y="{$y}">{
                    for $resize as element(resize) in $crop/resize
                    let $size as element() := ($resize/ldse:size, $resize/resize)[1]
                    let $options as xs:string := $size/@options
                    let $size-width as xs:string := $size/@width
                    let $size-height as xs:string := $size/@height
                    let $flags as xs:string? := $size/@flags
                    return (
                        <resize options="{$options}" width="{$size-width}" height="{$size-height}" flags="{$flags}"/>
                    )
                }</crop>
            )
        let $newImageProcessing as element(image-processing)? := <image-processing>{$imageXmlCropping}</image-processing>
        let $oldImageProcessing as element(image-processing)? := image:get-image-processing($imageXml)
        let $newImageXml as element(binary-content)? :=
            if ( fn:exists($oldImageProcessing) ) then (
                util:get-root(mem:node-replace($oldImageProcessing, $newImageProcessing))
            ) else (
                util:get-root(mem:node-insert-child($imageXml, $newImageProcessing))
            )
        let $clear-cache as item()* := image:clearBinaryCache($newImageXml)
        let $uri as xs:string? := xdmp:node-uri($imageXml)

        let $outputImageUrls as xs:string* := $crops//url
        let $jobKeys as xs:integer* := extract-job-key($outputImageUrls)
        let $delete as item()* := ()(:local:delete-image-from-service($jobKeys):)
        return (
            $newImageXml
        )

    ) else ()
};

declare function delete-image-from-service($jobKey as xs:integer) as item()* {
    xdmp:http-delete(
        fn:concat($serviceUrl, "/", $username, "/", $jobKey),
        <options xmlns="xdmp:http">
            <verify-cert>false</verify-cert>
            <authentication method="basic">
                <username>{$username}</username>
                <password>{$password}</password>
            </authentication>
        </options>
    )
};
