xquery version "1.0-ml";

module namespace tf = 'http://lds.org/code/modules/titan-functions';

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace df = 'http://lds.org/code/shared/lds-edit/dynamicForms' at '/ice/modules/dynamicForms.xqy';
import module namespace sp = "http://lds.org/code/modules/site-properties" at '/modules/site-properties.xqy';
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $site as xs:string := xdmp:get-request-field('site');
declare variable $non-cuc-sites as xs:string* := sp:non-cuc-sites();

declare function tf:get-search-result(
    $term as xs:string?,
    $page as xs:int?,
    $selected as xs:int?,
    $type as xs:string?,
    $rows as xs:int?
) {
    switch ( $type )
    case 'collection' return tf:get-collection-search-url($term, $page, $selected, $type, $rows)
    default return tf:get-default-search-url($term, $page, $selected, $type, $rows, ())
};

declare function tf:get-collection-search-url(
    $term as xs:string?,
    $page as xs:int?,
    $selected as xs:int?,
    $type as xs:string?,
    $rows as xs:int?
) {
    let $url-type as xs:string := '&amp;stype=' || $type
    let $url as xs:string := '/collection/search'
    return tf:search($term, $page, $selected, $url-type, $rows, $url, ())
};

declare function tf:get-default-search-url(
    $term as xs:string?,
    $page as xs:int?,
    $selected as xs:int?,
    $type as xs:string?,
    $rows as xs:int?,
    $path as xs:string?
) {
    let $url-type as xs:string? := '&amp;type=' || $type
    let $path as xs:string? :=
        if ( fn:exists($path) ) then (
            '&amp;collection=' || $path
        ) else ()
    let $url as xs:string := '/asset/search'
    return tf:search($term, $page, $selected, $url-type, $rows, $url, $path)
};

declare function tf:search(
    $term as xs:string?,
    $page as xs:int?,
    $selected as xs:int?,
    $url-type as xs:string?,
    $rows as xs:int?,
    $url as xs:string,
    $path as xs:string?
) {
    util:http-get($settings:content-api-url || $url || '?q=' || xdmp:url-encode($term) || '&amp;start=' || $page || '&amp;rows=' || $rows || $url-type || $path,
        <options xmlns="xdmp:http">
            <headers>
                <content-type>application/xml</content-type>
            </headers>
        </options>
    )
};

declare function tf:search(
    $url as xs:string,
    $path as xs:string?
) {
    xdmp:http-get($settings:content-api-url || $url || $path,
        <options xmlns="xdmp:http">
            <headers>
                <content-type>application/xml</content-type>
            </headers>
        </options>
    )
};

declare function tf:get-search-results(
    $term as xs:string?,
    $page as xs:int?,
    $selected as xs:int?,
    $type as xs:string?,
    $rows as xs:int?
) {
    let $result := tf:get-search-result($term, $page, $selected, $type, $rows)
    let $xml as element()* := util:map-xml($result[2])
    let $rows as xs:int := ( $xml/rows/xs:int(.), 20 )[1]
    let $total as xs:int? := ( $xml/total/xs:int(.), 0 )[1]
    let $json :=
        object-node {
            'pages': array-node {
                tf:get-pages-json($page, $selected, $total, $rows)
            },
            'results': array-node {
                tf:get-results($xml, $type)
            }
        }
    return (
        xdmp:from-json($json)
    )
};

declare function tf:get-results(
    $xml as element()*,
    $type as xs:string?
) {
    for $result in $xml/hits/hit
    return (
        switch ( $type )
        case 'collection' return tf:get-collection-json($result)
        default return tf:get-default-json($result)
    )
};

declare function tf:get-rendition-thumb(
    $xml as element()
) as element()* {
    for $rendition in $xml/renditions/rendition
    order by $rendition/size ascending
    return $rendition
};

declare function tf:get-pages-json(
    $page as xs:int?,
    $selected as xs:int?,
    $total as xs:int?,
    $rows as xs:int
) {
    object-node {
        'total': $total,
        'rows': $rows,
        'page': $page,
        'selected': $selected
    }
};

declare function tf:get-collection-json(
    $result as element()
) {
    let $rendition as element()? := tf:get-rendition-thumb($result/coverimages/coverimage/asset)[1]
    return (
        object-node {
            'result': object-node {
                'id': fn:string($result/collectionid),
                'title': fn:string($result/coverimages/coverimage/asset/metadata/metadata[key = 'publicTitle']/value),
                'path': fn:string($result/path),
                'image': fn:string($rendition/links/link[rel = 'resource']/href),
                'selected' : fn:false()
            }
        }
    )
};

declare function tf:get-default-json(
    $result as element()
) {
    let $rendition as element()? := tf:get-rendition-thumb($result)[1]
    let $title as xs:string := fn:string(( $result/metadata/metadata[key = 'title']/value[. != ''], $result/metadata/metadata[key = 'publicTitle']/value )[1])
    let $description as xs:string := fn:string(( $result/metadata/metadata[key = 'title']/value[. != ''], $result/metadata/metadata[key = 'publicDescription']/value )[1])
    let $account-id as xs:string := ( fn:string($result/metadata/metadata[key = 'accountId']/value)[. != ''], ' ' )[1]
    let $video-id as xs:string := ( fn:string($result/metadata/metadata[key = 'videoId']/value)[. != ''], ' ' )[1]
    let $duration as xs:string := ( fn:string($result/durationmilliseconds)[. != ''], ' ' )[1]
    let $download-url as xs:string := ( fn:string($result/distributionuri)[. != ''], ' ' )[1]
    let $stream-url as xs:string := ( fn:string($result/hlsdistributionuri)[. != ''], ' ' )[1]
    let $release-date as xs:string := ( fn:string(( $result/metadata/metadata[key = 'releaseDate']/value[. != ''], $result/metadata/metadata[key = 'xmpDM:releaseDate']/value )[1])[. != ''], ' ' )[1]
    let $track-number as xs:string := ( fn:string($result/metadata/metadata[key = 'xmpDM:trackNumber']/value)[. != ''], ' ' )[1]
    let $album as xs:string := ( fn:string($result/metadata/metadata[key = 'xmpDM:album']/value)[. != ''], ' ' )[1]
    let $artist as xs:string := ( fn:string($result/metadata/metadata[key = 'xmpDM:artist']/value)[. != ''], ' ' )[1]
    return (
        object-node {
            'result': object-node {
                'id': fn:string($result/assetid),
                'title': $title,
                'description': $description,
                'duration': $duration,
                'accountId': $account-id,
                'videoId': $video-id,
                'streamingUrl': $stream-url,
                'downloadUrl': $download-url,
                'albumReleaseDate': $release-date,
                'trackNumber': $track-number,
                'artistName': $artist,
                'albumName': $album,
                'uri': fn:string($result/metadata/metadata[key = 'uri' and language = $result/language]/value),
                'url': fn:string($result/links/link[rel = 'resource']/href),
                'lang': fn:string($result/language),
                'image': fn:string($rendition/links/link[rel = 'resource']/href),
                'type': fn:string($result/type),
                'selected': fn:false()
            }
        }
    )
};

declare function tf:get-children-results(
    $path as xs:string?
) {
    let $json := tf:get-all-children-results($path, (), (), ())
    return (
        array-node {
            $json
        }
    )
};

declare function tf:get-all-children-results(
    $path as xs:string?,
    $start as xs:int?,
    $rows as xs:int?,
    $pages as xs:int?
) {
    let $rows-param as xs:string? :=
        if ( fn:exists($rows) ) then (
            '&amp;rows=' || $rows
        ) else ()
    let $start-param as xs:string? :=
        if ( fn:exists($rows) ) then (
            '&amp;start=' || $start + $rows
        ) else ()
    let $result := tf:search('/asset/search', '?collection=' || fn:encode-for-uri($path) || $rows-param || $start-param)
    let $xml as element()* := util:map-xml($result[2])
    let $rows as xs:int := $xml/rows/xs:int(.)
    let $total as xs:int? := ( $xml/total/xs:int(.), 0 )[1]
    let $pages as xs:int? := fn:ceiling($total div $rows)
    let $json := tf:get-results($xml, '')
    return (
        $json,
        if ( $start < $total ) then (
            tf:get-all-children-results($path, $start + ( $rows, 20 )[1], 20, $pages)
        ) else ()
    )
};

declare function tf:update-collection(
    $new-xml as element()
) {
    let $site-properties as element(siteProperties) := sp:get-site-properties($site)
    let $collection-data :=
        object-node {
            'path': $site-properties/@display-name || ':' || ( $site-properties/titan-folder, $site-properties/@display-name, $site-properties/@name )[1] || '/' || $new-xml/@locale || '/' || $new-xml/title,
            'language': fn:string($new-xml/@locale),
            'metadata': array-node {
                object-node {
                    'key': 'publicTitle',
                    'language': fn:string($new-xml/@locale),
                    'value': fn:string($new-xml/title)
                },
                object-node {
                    'key': 'publicDescription',
                    'language': fn:string($new-xml/@locale),
                    'value': fn:string($new-xml/title)
                }
            },
            'coverImages': array-node {
(:                add asset here :)
            },
            'ownership': array-node {
                tf:get-user-access((), ()) (: $users :)
            },
            'readAccess': array-node {
                object-node {
                    'type': 'PUBLIC'
                }
            }
        }
    return (
        tf:post-to-asset-crawler('/collections/collection', xdmp:quote(xdmp:from-json($collection-data)))
    )
};

declare function tf:get-user-access(
    $username as xs:string?,
    $type as xs:string?
) {
    object-node {
         'value': ( $username, df:getVariable('user') )[1],
         'type': ( $type, 'LDS_ACCOUNT_USERNAME' )[1]
    }
};

declare function tf:post-collection-to-titan(
    $orig-file as element()?,
    $new-xml as element(),
    $form as element(ldse:formTemplate)?
) as element() {
    tf:post-collection-to-titan($orig-file, $new-xml, $form, ())
};

declare function tf:post-collection-to-titan(
    $orig-file as element()?,
    $new-xml as element(),
    $form as element(ldse:formTemplate)?,
    $status as xs:string?
) as element() {
    if ( ( df:getVariable('status') = 'ldse:publish' or $status = 'ldse:publish' ) and fn:exists($new-xml/collection) ) then (
        let $update-collection := tf:update-collection($new-xml)
        let $collection-result as element(result) := <result>{util:map-xml(xdmp:from-json($update-collection[2]))}</result>
        let $update-collection-assets := tf:add-asset-to-collection($collection-result/collectionid, $new-xml/items/element())
        return $new-xml
    ) else ( $new-xml )
};

declare function tf:add-asset-to-collection(
    $collection-id as xs:string,
    $item-ids as xs:string*
) {
    for $item-id as xs:string in $item-ids
    return (
        tf:put-to-asset-crawler('/collections/collection/' || $collection-id || '/asset/' || $item-id, ())
    )
};

declare function tf:post-to-asset-crawler(
    $url as xs:string,
    $data as item()?
) {
(:    try {:)
        util:http-post($settings:asset-crawler-url || $url,
            <options xmlns="xdmp:http">
                <data>{ $data }</data>
                <headers>
                    <content-type>application/json</content-type>
                </headers>
            </options>
        )
    (:} catch ( $e ) {
        xdmp:log(( 'Error posting to Asset Crawler:', $e ))
    }:)
};

declare function tf:put-to-asset-crawler(
    $url as xs:string,
    $data as item()?
) {
(:    try {:)
        util:http-put($settings:asset-crawler-url || $url,
            <options xmlns="xdmp:http">
            </options>
        )
    (:} catch ( $e ) {
        xdmp:log(( 'Error posting to Asset Crawler:', $e ))
    }:)
};

declare function tf:get-titan-asset-details(
    $titanId as xs:string,
    $type as xs:string
) as object-node()? {
    let $results:= util:http-get($settings:media-api-url || xdmp:url-encode($titanId),
        <options xmlns="xdmp:http">
            <headers>
                <content-type>application/json</content-type>
            </headers>
        </options>
    )
    return
    let $result :=
        if (fn:not(fn:exists($results//error))) then (
            $results
        ) else (
            if(fn:not($type eq "image")) then (
                let $next-results := util:http-get($settings:details-api-url || xdmp:url-encode($titanId),
                        <options xmlns="xdmp:http">
                            <headers>
                                <content-type>application/json</content-type>
                            </headers>
                        </options>
                    )
                return
                    if(fn:exists($next-results/result)) then (
                        $next-results/result
                    ) else( )
            ) else ( )
        )
    return
        if (fn:not(fn:exists($result//error)) and fn:exists($result)) then (
            let $metadata := if ($result/metadata) then ( $result/metadata ) else ( $result/metaData )
            let $id := if ($result/assetID) then ( $result/assetID ) else ( $result/assetId )
            let $title := ($metadata[key/data() eq "publicTitle"])[1]/value || ''
            let $type := fn:lower-case($result/type)
            let $thumbnailObject := tf:find-thumbnail-object($result)
            let $thumbnail := $thumbnailObject/id
            let $renditions :=
                for $image in $result/renditions[width le 1280 and height le 1280]
                order by $image/width
                return $image
            let $normalSizeRendition := $renditions[last()]
            let $fileSize := $normalSizeRendition/fileSize
            let $mime := $normalSizeRendition/mime
            return
                object-node {
                    'id': $id,
                    'title': $title,
                    'type': $type,
                    'thumbnail': $thumbnail,
                    'thumbnailInfo': $thumbnailObject,
                    'fileSize': $fileSize,
                    'dimensions': object-node {
                            'width': $normalSizeRendition/width,
                            'height': $normalSizeRendition/height
                        },
                    'mimeType': $mime,
                    'renditions': array-node{$renditions}
                }
        ) else ( )
};

declare function tf:find-titan-id-in-cuc-data($titan-id as xs:string?) as object-node()
{
   let $image := tf:get-titan-asset-details($titan-id, 'image')
   let $count :=
      if ($image) then
        count(
            for $i in
                cts:search(fn:collection(),
                    cts:and-query((
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('site'), 'mw', 'exact'),
                         cts:word-query($titan-id, 'exact'),
                         cts:not-query((
                            cts:element-value-query(xs:QName('ldse:site-context'), $non-cuc-sites, 'exact')
                                ))
                            ))
                    )/node()
            where ac:has-permission("ldse:publish-doc", $i/@locale, (), ($i/ldse:ldse-meta/ldse:form-options/ldse:site-context)[1])
            return $i)
      else 0
   let $_result := if ($image) then $count else 'Invalid ID.'
   let $matchFile := if ($count > 0) then 'true' else 'false'
   let $text-result := xs:string($_result)
   let $result := if ($text-result eq '0' or $text-result eq '1') then $_result||' file.'
                  else if (contains($text-result, 'Invalid')) then $text-result
                  else $text-result||' files.'
   return if ($image) then
              object-node {
                'type': 'titan image',
                'titanId': $titan-id,
                'fileCount': $count,
                'result': $result,
                'thumbnail': $image/thumbnailInfo
            }
            else
              object-node {
                'type': 'invalid titan image',
                'titanId': $titan-id,
                'fileCount': $count,
                'result': $result,
                'thumbnail': object-node {
                    'height': 78,
                    'width': 112,
                    'contentAPIUrl': $settings:shared-prefix||'/titan-id-update/noimage.png'
                    }
                }
};

declare function tf:find-thumbnail-object($titan-info as item()*) as object-node()?
{
(: There are `rendition` nodes both at the root, and in a `related` node (only sometimes there), so make sure to only grab `rendition` in the root using `/` not `//` which would look anywhere :)
    for $i in (
        ($titan-info/renditions[width eq 200])[1],
        ($titan-info/renditions[width eq max($titan-info/renditions/width[. lt 200])])[1],
        ($titan-info/renditions[width eq min($titan-info/renditions/width)])[1]
    )[1]
    return object-node {
        'id': $i/id,
        'mime': $i/mime,
        'height': $i/height,
        'width': $i/width,
        'distributionUrl': $i/distributionUrl,
        'contentAPIUrl': $settings:content-api-asset||'/'||$i/id,
        'fileSize': $i/fileSize
      }
};

