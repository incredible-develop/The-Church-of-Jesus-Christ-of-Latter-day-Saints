xquery version "1.0-ml";

import module namespace bcapi = "http://lds.org/code/shared/lds-edit/burceFunctions" at "modules/burceFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../modules/utility-functions.xqy";
declare option xdmp:mapping "true";

declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field('lang', 'eng'));
declare variable $function as xs:string? := util:escape-chars(xdmp:get-request-field('fn'));

(:TODO: cleanup work here to make sure we are properly cleaning up all request field values :)
declare variable $vars as element(post-vars) := <post-vars>
      {for $field as xs:string in xdmp:get-request-field-names()
        let $value as xs:string* := xdmp:get-request-field($field)
        let $fieldName as xs:string := if(fn:contains($field, "[")) then (fn:substring-before($field, "[")) else ($field)
        return element {$fieldName} {
            if($fieldName eq 'file') then (
                 xdmp:get-request-field("file")
            ) else if($value instance of xs:string) then (
                $value
            ) else (
                for $item as xs:string in $value return <item>{$item}</item>
            )
        }
      }
      </post-vars>;     
(:TODO: can we clean this up? 
Process: the js that requests this file (burce.js) passes a param1 field that determines
which function in bcapi gets called.  Vars are all bundled in one <post-vars> element and passed along

***Do not use this yet...I had to commit so I would not lose work...there is still cleanup to be done***
:)
xdmp:set-response-content-type('application/json'),
    if($function eq 'directory') then (
        bcapi:getDirectoryInfo($vars)
    ) else if($function eq 'deepZoom') then (
        bcapi:getDeepZoom()
    ) else if($function eq 'file') then (
        bcapi:getFileInfo($vars)
    ) else if($function eq 'buckets') then (
        bcapi:getFirstBuckets($vars)
    ) else if($function eq 'create') then (
        bcapi:createFolder($vars)
    ) else if($function eq 'search') then (
        bcapi:search($vars)
    ) else if($function eq 'usage') then (
        bcapi:knownUsage($vars)
    ) else if($function eq 'upload') then (
        bcapi:uploadFile($vars)
    ) else if($function eq 'save') then (
        bcapi:saveFileXml($vars)
    ) else if($function eq 'delete') then (
        bcapi:deleteFile($vars)
    ) else if($function eq 'move') then (
        bcapi:moveFile($vars)
    ) else if($function eq 'types') then (
        bcapi:getFileTypes($vars)
    )else ("No match found")
