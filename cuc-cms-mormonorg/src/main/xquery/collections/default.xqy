xquery version "1.0-ml";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "/ice/modules/dynamicForms.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace search = "http://lds.org/code/shared/lds-edit/collections" at "/collections/modules/search-results.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace fjson = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace cf = "http://lds.org/code/shared/lds-edit/collections/functions" at "/collections/modules/collections-functions.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

(: MAIN PARAMS :)
declare variable $file-id as xs:string* := form:getVariable("id");
declare variable $formName as xs:string := form:getVariable("formName");
declare variable $uri as xs:string? := form:getVariable("uri");
declare variable $page as xs:string := form:getVariable("page");
declare variable $options as xs:string := form:getVariable("option");
declare variable $publishType as xs:string := xdmp:get-request-field("publishType");
declare variable $locale as xs:string := form:getVariable('locale');
declare variable $country as xs:string? := form:getVariable('country');

let $login := okta:okta-login()
let $file as element() := ldsemeta:get-file-by($file-id, $locale, $uri, ())
let $location as xs:string := ($file/@location, $file//ldse:location)[1]
let $compId as xs:string? := $file/@compId
let $allTeasers as node()* := ice:findSiblingTeasersComponent(fn:local-name($file), $locale, $uri, $location, $compId)
let $allTeasers as node()* := if ( fn:exists($allTeasers) ) then ( $allTeasers ) else ( ice:findSiblingTeasers(fn:local-name($file), $locale, $uri, $location) )
let $displayNodes as xs:string* := fn:tokenize(xdmp:url-decode(form:getVariable('teaser-manager')), "\|")
let $displayNodes as xs:string* := if(fn:count($displayNodes) > 0)then($displayNodes)else(("title", "body"))
let $buttonOptions as xs:string* := fn:tokenize(xdmp:url-decode(form:getVariable('manager-options')), "\|")
let $buttonOptions as xs:string* := if(fn:count($buttonOptions) > 0)then($buttonOptions)else(("edit","remove","delete"))
let $referer as xs:string := (xdmp:get-request-field("referer"), xdmp:get-request-header('Referer',''))[1]
let $pageUrl as xs:string := "/collections"
let $preview-url as xs:string? := core:build-url($uri, $locale, ())
let $post-data as element(post-data) :=
    <post-data>{
        for $post as xs:string in xdmp:get-request-field-names()
        where fn:not($post = ("lang", "country"))
        return (
            element data {
                attribute name { $post },
                for $value as xs:string? in xdmp:get-request-field($post)
                return ( element value { $value } )
            }
        )
    }</post-data>
let $preview-url as xs:string? := core:build-url($uri, $locale, ())
let $current-page as xs:string := fn:concat($settings:shared-prefix, $pageUrl, util:split-locale-param($locale))
let $thisPage as xs:string :=
    fn:concat(
        $current-page,
        fn:string-join((
            "",
            for $data as element(data) in $post-data/data
            return (
                for $value as xs:string in $data/value
                return (
                    fn:concat($data/@name, '=', fn:encode-for-uri($value) )
                )
            )
        ),"&amp;")
    )
let $title as xs:string? := "Collection Manager"
let $collectionReferer as xs:string := ""
let $sensitive-items as xs:string* :=
    for $file as element() in $allTeasers
    let $sensitive-element as element(ldse:sensitive)? := ldsemeta:get-sensitive($file)
    where xs:string($sensitive-element/@status) = "yes"
    return (
        ldsemeta:get-document-id($file)
    )
return (
    core:template-apply(
        $title,
        $pageUrl,
        <page>
            <head>
                <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/resources/css/collection-manager.css"/>
            </head>
            <content>
                {
                    if ( fn:exists($sensitive-items) ) then (
                        <section id="sensitive-content-warning">
                        <section class="ldse-section ldse-summary ldse-info-banner warning">
                          <div class="ldse-section--body">
                            <span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span>
                                    <div class="ldse-warning-messages-div">
                                        <div class="ldse-warning-message-div">
                                            <h3 class="ldse-warning-message-title">Sensitive Content</h3>
                                            <div>There are sensitive items on this page. They are outlined below and may not be approved for publishing.</div>
                                        </div>
                                    </div>
                            </div>
                          </section>
                        </section>
                    ) else ()
                }
                <h2>teaser manager</h2>
                <script type="text/javascript">
                    function missingImage(img) {{
                        $(img).replaceWith('<span class="ldse-logo-image ldse-icon-logo ldse-icon ">&nbsp;</span>');
                        return false;
                    }}
                </script>
                <section class="ldse-section ldse-clearfix ldse-collection-page">
                    <header class="ldse-section--header with-button ldse-clearfix">
                        <span class="ldse-button-list">
                            <ul>
                                <li>
                                    <button href="{$settings:shared-prefix}/form?lang={$locale}&amp;country=" onclick="ICE.postLink(this); return false;" data-post.status="add" data-post.action="add" data-post.uri="{$uri}" data-post.page="{$page}" data-post.option="{$options}" data-post.referer="{$thisPage}" class="ldse-button ldse-responsive-button header-left primary ldse-icon-ko-add" i18n="ldse.add.teaser">Add New Item</button>
                                </li>
                            </ul>
                        </span>
                        {(:<button class="ldse-button ldse-responsive-button header-left primary ldse-icon-ko-add">Add Teaser</button>:)}
                        <button class="ldse-button header-right ldse-icon-ko-tri-down" id="toggle-btn">Expand All</button>
                    </header>
              <div class="ldse-section--body">
                    <section id="search" class="ldse-section ldse-clearfix">
                        <header id="search-header" class="ldse-section--header">
                            <h2><a href="#search-body" class="ldse-icon-ko-tri-down">Search</a></h2>
                            <div class="ldse-pagination">
                                <span class="ldse-pagination--shownum">
                                    Show {
                                        for $value as xs:int in  (12, 24, 48, 96)
                                        let $pageIndex as xs:int := 1
                                        let $pageSize as xs:int := 24
                                        return(
                                            if ( $pageSize eq $value ) then (
                                                <span><a data-count="{$value}" onclick="SR.changePageSize({$value})">{$value}</a></span>
                                            ) else(
                                                <span><a data-count="{$value}" href="#d" onclick="SR.changePageSize({$value})">{$value}</a></span>
                                            )
                                        )
                                    }
                                </span>
                                <a id="searchPrevious" href="#d" class="ldse-icon-ko-tri-left ldse-icon faded disabled" onclick="SR.previousPage()">&lt;</a>
                                <span class="ldse-pagination--pages" id="pageTotal">&nbsp; Page <span id="searchCurrentPage">0</span> of <span id="searchMaxPage">0</span> &nbsp;</span>
                                <a id="searchNext" href="#d" class="ldse-icon-ko-tri-right ldse-icon" onclick="SR.nextPage()">&gt;</a>
                            </div>
                        </header>
                    <div id="search-body" class="ldse-section--body">
                    <form class="ldse-form ldse-search ldse-box ldse-tableize" action="">
                      <span class="ldse-tableize--fill">
                                     <input type="text" placeholder="Search Teasers" id="filter-search" class="ldse-square-right search-input"/>
                                 </span>
                                 <span>
                                     <input type="button" id="searchButton" value="" class="ldse-square-left ldse-toggle-content" onclick="searchTeasers('{$locale}'); return false;"/>
                                 </span>
                               <button class="ldse-button secondary ldse-icon ldse-icon-ko-x clear-search"></button>
                    </form>
                     <div class="search-results">
                        {search:build-search-result-table()}
                            </div>
                        </div>
                    </section>

                <section id="collection" class="ldse-section ldse-clearfix">
                    <header id="current-header" class="ldse-section--header">
                        <h2><a href="#collection-body" class="ldse-icon-ko-tri-down">Current Collection</a></h2>
                    </header>
                    <input type="hidden" name="newOrder" id="manageTeaser-newOrder"/>
                    <input type="hidden" name="newItems" id="manageTeaser-newItems"/>
                    <section class="ldse-section--body">
                        <ul id="collection-list" class="sortable ldse-rowFix ldse-makeCols teaserManager">
                            {for $file as element() at $index in $allTeasers
                             let $approved as xs:boolean := (ldsemeta:collection-manager-correlation-can-publish($file))
                             let $image as xs:string? := core:get-display-uri(($file//thumbnail, $file//img/@src, $file//image, $file//archive-image, $file//@img)[1])
                             let $file-ID as xs:string? := $file/@id
                             let $type as xs:string := $file/@type
                             let $displayText as xs:string* := $file/node()[local-name(.) = $displayNodes]
                             let $displayText as xs:string? := fn:string-join($displayText, " ")
                             let $isPublished as xs:boolean? := ldsemeta:is-published($file)
                             let $teaserUri as xs:string? := ldsemeta:get-document-uri($file, fn:true())
                             let $options-xml as element()? := ldsemeta:get-form-options($file)
                             let $teaserOptions as xs:string? := ice:csv-variables($options-xml)
                             let $hasForm as xs:boolean := ($options-xml/form !="")
                             let $source as xs:string? := ldsemeta:get-document-source($file)
                             let $chq-protected as xs:boolean := ($source eq "chq" and fn:contains($locale, "-"))
                             let $status as xs:string := cf:status($file)
                             let $status-icons as xs:string* := cf:status-icon($status)
                             let $is-sensitive as xs:boolean? :=
                                for $item as xs:string in $sensitive-items
                                where $file-ID = $item
                                return fn:true()
                            return (

                                <li class="ldse-clearfix collection-item ldse-info-banner {if ( $is-sensitive ) then ( "sensitive-content-warning" ) else ()}" index="{$index}" data-id="{$file-ID}" data-type="{$type}">
                                    <section class="ldse-block">
                                        <header class="ldse-clearfix">
                                            <a href="#d" class="ldse-icon-ko-tri-right ldse-icon ldse-block-toggle">Toggle Full View</a>
                                            <h3>{fn:string($file/title)}</h3>
                                            <button class="ldse-collection-button remove ldse-icon-x ldse-icon" data-uri="{$uri}" data-locale="{$locale}" data-fileid="{$file-ID}" id="remove-{$file-ID}">Remove</button>
                                        </header>
                                        <div class="ldse-block--body">
                                            {
                                                if ($image = "") then (
                                                    <span class="ldse-logo-image ldse-icon-logo ldse-icon ">&nbsp;</span>
                                                ) else (
                                                    <img src="{$image}" onerror="missingImage(this); return false;"/>
                                                )
                                            }
                                            <div class="ldse-teaser-buttons">
                                            {if(fn:not($chq-protected) and ac:has-permission("ldse:edit-doc", $locale, $uri) and $hasForm) then(
                                                <a href="{fn:concat($settings:shared-prefix,"/form", util:split-locale-param($locale), '&amp;id=',$file-ID)}" class="ldse-button secondary ldse-icon-edit ldse-icon" onclick="return editFile(this);" data-post.status="edit" data-post.uri="{$teaserUri}" data-post.page="{$teaserUri}" data-post.option="{$teaserOptions}" data-post.referer="{$thisPage}" title="Edit">Edit</a>
                                            ) else ()
                                            }
                                            {if (ac:has-permission('ldse:publish-doc', $locale, $uri)) then (
                                                if(fn:not($approved)) then (
                                                    <a class="ldse-button secondary ldse-icon-send ldse-icon publish-item disabled" disabled="disabled" title="Publish" data-file="{$file}" data-locale="{$locale}" data-fileid="{$file-ID}" data-uri="{$uri}">Publish</a>
                                                ) else (
                                                    <a class="ldse-button secondary ldse-icon-send ldse-icon publish-item" title="Publish" data-file="{$file}" data-locale="{$locale}" data-fileid="{$file-ID}" data-uri="{$uri}">Publish</a>
                                                )
                                            ) else (),
                                            if(fn:not($approved)) then (
                                                <div class="needCor">
                                                    <span class="approval-flag ldse-icon-ko-warning ldse-icon" title="Needs Approval">Pending Approval</span>
                                                    <span class="approval-text">Not Cor-IP / Cor-Eval approved</span>
                                                </div>

                                            ) else ()
                                            }
                                            </div>
                                        </div>
                                        {
                                            (:
                                                To change the status of items you will need to do 2 things:
                                                1. Change the class on the div.ldse-collection-status
                                                2. change class on the span inside of the div mentioned in #1

                                                SCHEDULED
                                                    1. class needs to be "collection-scheduled"
                                                    2. span needs to have class of "ldse-icon-clock"
                                                MODIFIED
                                                    1. "collection-modified"
                                                    2. "ldse-icon-ko-warning"
                                                DRAFT
                                                    1. "collection-draft"
                                                    2. "ldse-icon-edit"
                                                PUBLISHED
                                                    1. "collection-published"
                                                    2. "ldse-icon-send"
                                                CREATED
                                                    1. "collection-created"
                                                    2. "ldse-icon-paper"
                                                SUBMITTED
                                                    1. "collection-submitted"
                                                    2. "ldse-icon-check2"
                                                SCEDULED UNPUBLISH
                                                    Same as Scheduled!
                                                UNPUBLISHED
                                                    1. "collection-unpublished"
                                                    2. "ldse-icon-unpublish"
                                            :)
                                        }
                                        <div class="ldse-collection-status {$status-icons[1]}">
                                            <span class="{$status-icons[2]}">{$status}</span>
                                        </div>
                                    </section>
                                  </li>
                                )
                            }
                        </ul>
                    </section>
                </section>
        </div>
      </section>
        </content>
        <scripts>
            <script type="text/javascript">
                var referer = {xdmp:to-json-string($referer)};
                var uri = {xdmp:to-json-string($uri)};
                var locale = {xdmp:to-json-string($locale)};
                var page = {xdmp:to-json-string($page)};
                var teaserLocation = {xdmp:to-json-string($location)};
                var option = {xdmp:to-json-string($options)};
                var thisPageReferer = {xdmp:to-json-string($thisPage)};
                var curPage = {xdmp:to-json-string($current-page)};
                var originalOrder = {fjson:arrq(for $t as node() in $allTeasers return $t/@id)};

                var postData = {
                    fjson:obj((
                        for $data as element(data) in $post-data/data
                        let $values as xs:string* := $data/value
                        return (
                            if (fn:count($values) > 1) then (
                                fjson:keyObject($data/@name, fjson:arrq($values))
                            ) else (
                                fjson:escapedKeyValue($data/@name, $values)
                            )
                        )
                    ))
                };
            </script>
            <script src="{$settings:cdn-path}/scripts/ui/1.8.24/jquery-ui.min.js"></script>
            <script src="{$settings:shared-prefix}/ice/resources/script/ice.js"></script>
            <script src="{$settings:shared-prefix}/collections/resources/scripts/collection.js"></script>
            {search:build-list-item()}
            { form:jsVariableMap() }
        </scripts>
        <button-groups>
            <button-group>
                <button onclick="buttonClicked(this); return false;" status="ldse:publish" class="ldse-button secondary ldse-icon-send">Publish Collection</button>
            </button-group>
            <button-group>
                <button onclick="buttonClicked(this); return false;" status="ldse:unpublish" class="ldse-button destructive ldse-icon-unpublish">Unpublish All</button>
               {(: <button onclick="buttonClicked(this); return false;" status="ldse:remove" class="ldse-button destructive ldse-icon-ko-remove">Remove All</button>
                <button onclick="buttonClicked(this); return false;" status="ldse:delete" class="ldse-button destructive ldse-icon-trash">Delete All</button>:)}
            </button-group>
            <button-group>
                <button onclick="buttonClicked(this); return false;" status="ldse:preview" class="ldse-button primary ldse-icon-save">Save Order</button>
            </button-group>
            <button-group>
                <button onclick="cancelChanges('{$uri}', '{$locale}'); return false;" id="action-cancel" class="ldse-icon-x">Done</button>
            </button-group>
        </button-groups>
        <preview-eye>{$preview-url}</preview-eye>
        <options>
        </options>
    </page>
    )
)
