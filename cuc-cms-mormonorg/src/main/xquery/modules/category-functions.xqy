xquery version "1.0-ml";
(: File should be saved at "/custom/lds-edit/ldse-core.xqy" :)

module namespace category = "http://lds.org/code/shared/lds-edit/category-functions";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "ldse-meta.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $update-map as map:map := map:map();

declare function category:updateCategory(
    $categoryName as xs:string*, 
    $ids as xs:string*, 
    $site as xs:string,
    $locale as xs:string
) as item()* {
    let $category as element(category)? := category:getCategory($categoryName, $site, $locale)
    return (
        if ( fn:exists($category) ) then (
            let $contents as empty-sequence() := 
                for $item as xs:string in $category/content/item/fn:string()
                return (
                    map:put($update-map, $item, $item)
                )
            let $new-items as element(item)* := 
                for $id as xs:string in $ids
                let $mapId as xs:string? := map:get($update-map, $id)
                return (
                    if ( fn:exists($mapId) ) then () else (<item>{$id}</item>)
                )
            let $new-category as element() := mem:node-insert-child($category/content, $new-items)/*
            return (
                core:document-replace($category, $new-category)
            )
        ) else (
            let $id as xs:string := fn:concat($categoryName, "-", $locale)
            let $category as element(category) := 
                element category {
                    attribute name { $categoryName },
                    attribute id { $id },
                    attribute locale { $locale },
                    element content {
                        for $id as xs:string in $ids
                        return (
                            <item>{$id}</item>
                        )
                    }
                }
            let $meta as element(ldse:ldse-meta) := ldsemeta:get-meta($category, $id, $locale, (), "preview")
            let $db-path as xs:string := core:build-db-path($categoryName, $locale, $id, $category)
            let $new-category as element(category) := mem:node-insert-child($category, $meta)
            return (
                core:update-file('ldse:preview', $db-path, $new-category)
            )
        )
    )
};

declare function category:getCategory($categoryName as xs:string, $site as xs:string, $locale as xs:string) as element(category)? {
    cts:search(/category,
        cts:and-query((
            cts:directory-query(fn:concat('/preview/', $site, '/'),  'infinity'),
            cts:element-attribute-value-query(xs:QName('category'), xs:QName('name'), $categoryName, 'exact'),
            cts:element-attribute-value-query(xs:QName('category'), xs:QName('locale'), $locale, 'exact')
        )),
        "unfiltered"
    )
};

declare function category:getCategories() as element(category)* {
    cts:search(/category,
        cts:and-query((
            core:get-filter-query()
        ))
    )
};

declare function category:buildCategories($values as item()*) as element(option)* {
    for $category as element(category) in cts:search(/category, cts:and-query(( core:get-filter-query(), cts:element-attribute-value-query(xs:QName('category'), xs:QName('locale'), (xdmp:get-request-field('lang'), xdmp:get-request-field('locale'))[1], 'exact'))) )
    let $categoryName as xs:string := fn:lower-case($category/@name/fn:string())
    let $subCategories as xs:string* := $category/sub-categories/sub-category/@name
    let $values as xs:string* := fn:tokenize($values, ' ')
    order by $categoryName
    return (
        if ( $categoryName eq $values ) then (
            <option val="{$categoryName}" selected="selected">{$categoryName}</option>
        ) else (
            <option val="{$categoryName}">{$categoryName}</option>
        ), category:buildSubCategories($subCategories, $values)
    )
};

declare function category:buildSubCategories($subCategories as xs:string*, $values as item()*) {
    for $subCategory as xs:string in $subCategories
    order by $subCategory
    return (
        if ( $subCategory eq $values ) then (
            <option val="{$subCategory}" style="padding-left: 25px;" selected="selected">{$subCategory}</option>
        ) else (
            <option val="{$subCategory}" style="padding-left: 25px;">{$subCategory}</option>
        )
    )
};

declare function category:getTags() as element(tag)* {
    cts:search(/tag,
        cts:and-query((
            core:get-filter-query()
        ))
    )
};