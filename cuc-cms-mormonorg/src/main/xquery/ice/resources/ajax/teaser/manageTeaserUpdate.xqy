xquery version "1.0-ml";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../../modules/dynamicForms.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../../modules/ldse-meta.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";

declare boundary-space preserve;
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";
declare option xdmp:update "true";

let $teasers as xs:string* := fn:tokenize(xdmp:get-request-field("newOrder"), ",")
let $saveOrder as xs:boolean := xdmp:get-request-field("save") = 'true'
let $publishedRoot as xs:string* := core:get-mode-root("published")
let $location as xs:string := xdmp:get-request-field("location")
let $pageUri as xs:string := xdmp:get-request-field("uri")

return (
    if (ac:has-permission('ldse:teaser-manager', "", "")) then (
        for $t as xs:string at $c in $teasers
        let $tokens as xs:string* := fn:tokenize($t, "Teaser")
        
        let $curT as element(teaser) := 
        if(fn:count($tokens)>1) then(
       
        
        cts:search(/teaser,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('teaser'), xs:QName('id'), $tokens[2], 'exact')
                ))
            )
        ) else(
            cts:search(/teaser,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('teaser'), xs:QName('id'), $t, 'exact')
                ))
            )
            )
       let $isNew as xs:boolean := (fn:count($tokens)>1)
       let $newSequence as attribute() := attribute sequence {fn:concat($c, "00")}
       let $newMeta as element(ldse:ldse-meta) := ldsemeta:get-meta($curT) 
       let $newID as xs:string := util:generate-unique-id($curT/@locale) 
       (: don't update the meta information, otherwise the ice marker will always show up as orange. We are only changing sequence and don't want to ruin workflow for any other updates :)
       let $newTeaser as element(teaser) := 
            if($isNew) then(
               
               let $newMeta as element(ldse:ldse-meta) := ldsemeta:get-meta($curT, $newID, $curT/@locale, $pageUri, "preview")
               return(
               element teaser {
                $curT/@*[fn:not(fn:node-name(.) eq xs:QName('sequence'))][fn:not(fn:node-name(.) eq xs:QName('location'))][fn:not(fn:node-name(.) eq xs:QName('id'))][fn:not(fn:node-name(.) eq xs:QName('page'))],
                attribute location {$location},
                attribute id {$newID},
                attribute page {$pageUri},
                $newSequence,
                $newMeta,
                $curT/*[fn:not(fn:node-name(.) eq xs:QName('ldse:ldse-meta'))]
               })
       ) else(
            element teaser {
                $curT/@*[fn:not(fn:node-name(.) eq xs:QName('sequence'))],
                $newSequence,
                $curT/*
            }
        )
        let $dbPath as xs:string :=
            if($isNew) then(
                core:build-db-path($pageUri, $curT/@locale, $newTeaser/@id, $curT)
            ) else (
            xdmp:node-uri($curT)
           )

        return(
            if($publishedRoot)then(
                let $pubT as element(teaser)? :=
                if ($isNew) then (
                    cts:search(/teaser,
                        cts:and-query((
                            cts:directory-query($publishedRoot, 'infinity'),
                            cts:element-attribute-value-query(xs:QName('teaser'), xs:QName('id'), $tokens[2], 'exact')
                        ))
                    )
                ) else (
                    cts:search(/teaser,
                        cts:and-query((
                            cts:directory-query($publishedRoot, 'infinity'),
                            cts:element-attribute-value-query(xs:QName('teaser'), xs:QName('id'), $t, 'exact')
                        ))
                    )
                )
                return(
                    if(fn:exists($pubT))then(
                        let $newPubMeta as element(ldse:ldse-meta)? := ldsemeta:get-meta($pubT) 
                        (: don't update the meta information, otherwise the ice marker will always show up as orange. We are only changing sequence and don't want to ruin workflow for any other updates :)
                        let $newPubTeaser as element(teaser)? := 
                        if ($isNew) then(
                            element teaser {
                                $pubT/@*[fn:not(fn:node-name(.) eq xs:QName('sequence'))][fn:not(fn:node-name(.) eq xs:QName('location'))][fn:not(fn:node-name(.) eq xs:QName('id'))][fn:not(fn:node-name(.) eq xs:QName('page'))],
                                attribute location {$location},
                                attribute id {$newID},
                                attribute page {$pageUri},
                                $newSequence,
                                $newPubMeta,
                                $pubT/*[fn:not(fn:node-name(.) eq xs:QName('ldse:ldse-meta'))]
                               }
                        ) else (
                            element teaser {
                                $pubT/@*[fn:not(fn:node-name(.) eq xs:QName('sequence'))],
                                $newSequence,
                                $pubT/*
                            }
                        )
                        let $dbPubPath as xs:string :=  if($isNew) then(
                                core:build-db-path($pageUri, $pubT/@locale, $newPubTeaser/@id, $pubT)
                            ) else (
                        xdmp:node-uri($pubT)
                           )
                        return (
                            core:save-file($dbPubPath, $newPubTeaser, $pubT)
                        )
                    )else()
                )
            )else(),
            core:save-file($dbPath, $newTeaser, $curT)
        )
    ) else (
         let $errorMsg as xs:string:="Sorry, You don't have permission" 
         let $errorTitle as xs:string:= "Access Denied!"
         return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
)
