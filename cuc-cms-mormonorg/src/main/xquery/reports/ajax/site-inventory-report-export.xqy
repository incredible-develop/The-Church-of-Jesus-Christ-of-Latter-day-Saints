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
let $attachment := fn:concat("attachment;filename=siteInventoryReport-", $currentDate, ".zip")
let $siteProperties := /siteProperties
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
                                         cts:directory-query(('/preview/'), 'infinity'),
                                         cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), $site-language/@lang, 'exact'),
                                         cts:element-value-query(xs:QName('ldse:site-context'), $site-language/@site, 'exact')
                                     ))
                                     )
             return
                          if ($custom-pages) then
                                   let $title := fn:concat($site-language/@site, ': ', $site-language/@lang, $nl)
                                   let $headings := fn:concat('Page URL; Folder; Page Name; Top Level Domain; Page Status', $nl)
                                   let $content := for $custom-page in $custom-pages
                                                   let $put := map:put($params-in, 'lang', fn:string($custom-page/@locale))
                                                   let $put := map:put($params-in, 'site', fn:string($custom-page/ldse:form-options/ldse:site-context)[1])
                                                   let $put := map:put($params-in, 'status', 'preview')
                                                   let $folder := $custom-page/@uri/fn:string()
                                                   let $pageName := $custom-page/meta/title/fn:string()
                                                   let $lastPublishedDate := fn:format-dateTime(xs:dateTime($custom-page/ldse:ldse-meta/ldse:publish-date/@date/fn:string()), $dateformat)
                                                   let $lastModifiedDate := fn:format-dateTime(xs:dateTime($custom-page/ldse:ldse-meta/ldse:last-modified/@date/fn:string()), $dateformat)
                                                   let $pageStatus := if ($lastModifiedDate > $lastPublishedDate) then
                                                                          'Modified'
                                                                      else if (fn:exists($lastPublishedDate)) then
                                                                          'Published'
                                                                      else 'Draft'
                                                   let $topLevelDomain := fn:concat('https://',$siteProperties[@site eq $site-language/@site]/urls/url[@env eq 'published']/fn:string())
                                                   let $pageUrl := fn:concat($topLevelDomain,$custom-page/@uri/fn:string())
                                   order by $pageUrl
                                   return fn:concat($pageUrl,";",$folder,";",$pageName,";",$topLevelDomain,";",$pageStatus, $nl)
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
                    let $fileName as xs:string := fn:concat($siteLang/@site, '-', $siteLang/@lang, '-siteInventoryReport')
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
