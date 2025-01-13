xquery version "1.0-ml";

import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "../../modules/template.xqy";
import module namespace library = "http://lds.org/code/shared/lds-edit/supported-languages" at "../../supported-languages/modules/library.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '../../modules/site-properties.xqy';
import module namespace tf = "http://lds.org/code/transforms/modules/transform-functions" at '../../transforms/modules/transform-functions.xqy';
import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace jsonb = 'http://marklogic.com/xdmp/json/basic';

declare boundary-space preserve;
declare option xdmp:mapping "true";
declare variable $siteLangs as xs:string* := xdmp:get-request-field("siteLangs[]");
declare variable $dateformat as xs:string := "[Y0001]-[M01]-[D01] [H01]:[m01]:[s01]";
declare variable $params-in as map:map := map:map();

let $nl := "&#10;"
let $currentDate := fn:format-dateTime(fn:current-dateTime(), $dateformat)
let $attachment := fn:concat("attachment;filename=pageStatusReport-", $currentDate, ".zip")
let $_site-languages :=  for $i in $siteLangs
                           let $site := fn:substring-before($i, ' |')
                           let $lang := fn:substring-after($i, '| ')
                           return if ($site eq 'all' and $lang eq 'all') then
                                      for $allSite in sp:get-site-properties(())
                                      for $supported-lang in library:get-supported-languages-by-site($allSite/@site/fn:string())/language/@key/fn:string()
                                      return fn:concat($allSite/@site/fn:string(),'|', $supported-lang)
                                  else if ($lang eq 'all') then
                                      for $supported-lang in library:get-supported-languages-by-site($site)/language/@key/fn:string()
                                      return fn:concat($site,'|', $supported-lang)
                                  else fn:concat($site,'|', $lang)
let $site-languages := for $i in fn:distinct-values($_site-languages)
                       let $siteName := fn:substring-before($i, '|')
                       let $siteLang := fn:substring-after($i, '|')
                       return element siteLang {attribute site {$siteName}, attribute lang {$siteLang}}
let $data := for $site-language in $site-languages
             let $custom-pages := cts:search(/custom-page, cts:and-query((
                                         cts:directory-query('/preview/', 'infinity'),
                                         cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), $site-language/@lang, 'exact'),
                                         cts:element-value-query(xs:QName('ldse:site-context'), $site-language/@site, 'exact')
                                     ))
                                     )
             return
                 if ($custom-pages) then
                         let $title := fn:concat($site-language/@site, ': ', $site-language/@lang, $nl)
                         let $headings := fn:concat('Page URI,Previous URIs,Canonical URI,Status,Page ID,Last Published Date,Last Published By,Last Modified Date,Last Modified By,Created Date,Created By,Translation Stutus,Page Title,Page Level 1,Page Level 2', $nl)
                         let $content := for $custom-page in $custom-pages
                                         let $put := map:put($params-in, 'lang', fn:string($custom-page/@locale))
                                         let $put := map:put($params-in, 'site', fn:string($custom-page/ldse:form-options/ldse:site-context)[1])
                                         let $put := map:put($params-in, 'status', 'preview')
                                         let $uri := $custom-page/@uri/fn:string()
                                         let $pageId := $custom-page/@id/fn:string()
                                         let $lastPublishedDate := fn:format-dateTime(xs:dateTime($custom-page/ldse:ldse-meta/ldse:publish-date/@date/fn:string()), $dateformat)
                                         let $lastPublishedBy := $custom-page/ldse:ldse-meta/ldse:publish-date/@username/fn:string()
                                         let $createdDate := fn:format-dateTime(xs:dateTime($custom-page/ldse:ldse-meta/ldse:created/@date/fn:string()), $dateformat)
                                         let $createdBy := $custom-page/ldse:ldse-meta/ldse:created/@username/fn:string()
                                         let $lastModifiedDate := fn:format-dateTime(xs:dateTime($custom-page/ldse:ldse-meta/ldse:last-modified/@date/fn:string()), $dateformat)
                                         let $lastModifiedBy := $custom-page/ldse:ldse-meta/ldse:last-modified/@username/fn:string()
                                         let $translationSentDate := fn:format-dateTime(xs:dateTime($custom-page/ldse:ldse-meta/ldse:translation-event/ldse:translation-sent/@date/fn:string()), $dateformat)
                                         let $translationReturnedDate := fn:format-dateTime(xs:dateTime($custom-page/ldse:ldse-meta/ldse:translation-event/ldse:translation-returned/@date/fn:string()), $dateformat)
                                         let $status := if ($lastModifiedDate > $lastPublishedDate) then
                                                            'modified'
                                                        else if (fn:exists($lastPublishedDate)) then
                                                            'published'
                                                        else 'draft'
                                         let $translationStatus := if ($translationSentDate) then
                                                      let $component-translation-status :=
                                                              fn:distinct-values(
                                                                   for $i in $custom-page/content/*
                                                                   let $componentId := $i/fn:string()
                                                                   let $file := cts:search(fn:collection(),
                                                                                        cts:and-query((
                                                                                        cts:directory-query('/preview/', 'infinity'),
                                                                                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $componentId, 'exact')
                                                                                        ))
                                                                                    )
                                                                   let $translation-returned := $file/node()/ldse:ldse-meta/ldse:translation-event/ldse:translation-returned/@date
                                                                   return if ( fn:not(fn:exists($translation-returned))) then
                                                                                'pending'
                                                                          else ())
                                                      return if ($component-translation-status) then
                                                                $component-translation-status
                                                             else if ($translationReturnedDate) then
                                                                'all files returned'
                                                             else ()
                                                    else 'not sent'
                                         let $previousUris := fn:string-join(
                                                    for $i in $custom-page/uri-history/page-uri[. ne $custom-page/@uri]
                                                    order by $i/@timestamp
                                                    return $i,
                                                '  ')
                                         let $pageTitle := $custom-page/meta/title/fn:string()
                                         let $pageSublevel1 := $custom-page/meta/pageSubLevel1/value/fn:string()
                                         let $pageSublevel2 := $custom-page/meta/pageSubLevel2/value/fn:string()
                                         let $_canonical-uri := tf:determinExternalorInternalLink(fn:string($custom-page/mo-reference-page), fn:string($custom-page/link-URL), (), (), $params-in)
                                         let $canonical-uri := if ($_canonical-uri) then
                                                                 let $xml as node() := json:transform-from-json($_canonical-uri)
                                                                 return
                                                                     if (fn:contains($xml/jsonb:URL/fn:string(), '?lang')) then
                                                                        fn:substring-before($xml/jsonb:URL/fn:string(), '?lang')
                                                                    else   $xml/jsonb:URL/fn:string()
                                                               else ()
                         order by $uri
                         return fn:concat($uri,",",$previousUris,",",$canonical-uri,",", $status,",",$pageId,",",$lastPublishedDate,",",$lastPublishedBy,",",$lastModifiedDate,",",$lastModifiedBy,",",
                                            $createdDate,",",$createdBy,",",$translationStatus,",",$pageTitle,",",$pageSublevel1,",",$pageSublevel2, $nl)
                      return element sitelang {
                                attribute site {$site-language/@site},
                                attribute lang {$site-language/@lang},
                                element content {$title,$headings,$content}
                                }
             else ()
return
    if (fn:exists($data)) then (
        let $zip as binary() :=
            xdmp:zip-create(
                <parts xmlns="xdmp:zip">{
                    for $siteLang in $data
                    let $fileName as xs:string := fn:concat($siteLang/@site, '-', $siteLang/@lang, '-pageStatusReport')
                    return
                            <part>{ fn:concat($fileName, ".csv") }</part>
                }</parts>,
                for $siteData in $data
                let $file := $siteData/content/fn:string()
                return document { $file }
            )
        return (
            xdmp:set-response-content-type('application/octet-stream'),
            xdmp:add-response-header('Content-Disposition', $attachment),
            $zip
        )
    ) else (
        template:error()
    )
