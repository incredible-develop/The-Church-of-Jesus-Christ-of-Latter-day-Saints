xquery version "1.0-ml";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace content-module = "http://lds.org/code/shared/lds-edit/content/content-module" at "/content/modules/content-module.xqy";
import module namespace content-search = "http://lds.org/code/shared/lds-edit/content/content-search" at "/content/modules/content-search.xqy";
import module namespace content-workflow = "http://lds.org/code/shared/lds-edit/content/content-workflow" at "/content/modules/content-workflow.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

let $login := okta:okta-login()
let $thisPage as xs:string := '/content'
let $pageIndex as xs:int := 1
let $pageSize as xs:int := 25
let $scripts as element(scripts) :=
    <scripts>
        <script src="{$settings:cdn-path}/lds-edit/scripts/jquery.form.js" async="async"/>
        <script src="{$settings:shared-prefix}/ice/resources/script/ice.js" />
        <script src="{$settings:shared-prefix}/content/resources/scripts/content.js"/>
        <script type="text/javascript">
            var isSubmitter = {ac:has-permission("ldse:edit-submission", "", "") and fn:not(ac:has-permission("ldse:edit-any-submission", "", ""))};
        </script>
        <script class="handlebars-template" id="confirmTemplate" type="text/x-handlebars-template">
            <header class="ldse-section--header">
             <h2>{{{{this.title}}}}</h2>
            </header>
            <form class="ldse-section--body ldse-form">
             <dl>
                 <dt><label for="reason">{{{{this.text}}}}</label></dt>
             </dl>
             <div class="ldse-form-buttons">
                 <input type="submit" class="ldse-button primary" value="OK" />
                 {{{{#unless this.noCancel}}}}
                     <input type="button" class="ldse-button ldse-modal-close" value="Cancel" />
                 {{{{/unless}}}}
             </div>
            </form>
        </script>
        <script class="handlebars-template" id="summaryTemplate" type="text/x-handlebars-template">
            <div class="ldse-rowFix ldse-makeCols">
                {{{{#each 0.this}}}}
                <section class="ldse-block">
                    <header>
                        <h3><a href="#d" data-name="{{{{name}}}}" onclick="C.clickStatus(this)">{{{{title}}}}</a></h3>
                     </header>
                     <div class="ldse-block--body">
                         <dl class="ldse-clearfix">
                             {{{{#isCommentStatus}}}}
                             {{{{/isCommentStatus}}}}
                        </dl>
                      </div>
                </section>
                {{{{/each}}}}
            </div>
        </script>
        <script class="handlebars-template" id="reasonTemplate" type="text/x-handlebars-template">
            <header class="ldse-section--header">
                <h2>Publish {{{{checkedCount}}}} Documents?</h2>
            </header>
            <form class="ldse-section--body ldse-form">
                <div class="ldse-form-buttons">
                    <button class="ldse-button primary ldse-icon-check2">OK</button>
                    <button class="ldse-button ldse-icon-x ldse-modal-close">Cancel</button>
                </div>
            </form>
        </script>
        <script class="handlebars-template" id="deleteTemplate" type="text/x-handlebars-template">
            <header class="ldse-section--header">
                <h2>Delete {{{{checkedCount}}}} Documents?</h2>
            </header>
            <form class="ldse-section--body ldse-form">
                <p>Are you sure you want to delete the selected documents?</p>
                <div class="ldse-form-buttons">
                    <button class="ldse-button destructive ldse-icon-trash">Delete</button>
                    <button class="ldse-button ldse-icon-x ldse-modal-close">Cancel</button>
                </div>
            </form>
        </script>
        <script class="handlebars-template" id="detailsHeadTemplate" type="text/x-handlbars-template">
      <tr>
        <th>
          <span class="ldse-option box-only">
            <input type="checkbox" class="styled checkall" id="details-checkall"/>
            <label for="details-checkall">Check</label>
          </span>
        </th>
        <th></th>
        {
          for $column as element(ldse:column) at $i in $content-search:columnXML/ldse:column
          return(
            content-module:generate-conditional-column(fn:concat("1.0.", $column/@id),
            content-module:get-head-cell($column, $i))
          )
        }
      </tr>
        </script>
        <script class="handlebars-template" id="sensitiveItemTemplate" type="text/x-handlbars-template">
            {{{{#sensitiveCount 1.this}}}}
            {{{{/sensitiveCount}}}}
        </script>
        <script class="handlebars-template" id="detailsBodyTemplate" type="text/x-handlbars-template">
    {{{{#loop 1.this}}}}
    <tr class="page{{{{this.pageNum}}}} {{{{#isSensitive}}}}{{{{/isSensitive}}}}" data-file="{{{{json this}}}}">
      <td>
        <span class="ldse-option box-only">
          <input class="rowSelect"  type="checkbox" value="{{{{this.id}}}}" id="box-{{{{this.pageNum}}}}-{{{{i}}}}" data-words="{{{{this.words}}}}" />
          <label for="box-{{{{this.pageNum}}}}-{{{{i}}}}">Check</label>
        </span>
      </td>
      <td class="preview-eye"><a href="{{{{previewUrl}}}}" onclick="ICE.linkToItem(this.href, '{{{{this.id}}}}'); return false;" class="ldse-icon-preview ldse-icon big">Preview</a></td>
      {
        for $column as element(ldse:column) in $content-search:columnXML/ldse:column
        return(
          content-module:generate-conditional-column(fn:concat("this.",$column/@id),content-module:get-cell($column))
        )
      }
    </tr>
    {{{{/loop}}}}
        </script>

        {content-workflow:get-config()}
      <script src="{$settings:shared-prefix}/resources/scripts/detail-table.js" type="text/javascript">&nbsp;</script>
    </scripts>

let $title as xs:string := "Content Manager"

let $head as element(head) :=
    <head>
        <link rel="stylesheet" href="{$settings:shared-prefix}/translation/resources/styles/translation.css" />
        <link rel="stylesheet" href="{$settings:shared-prefix}/translation/resources/styles/calendar.css" />
    </head>

let $content as element(content) :=
    <content>
        <section id="summary" class="ldse-section ldse-summary ldse-clearfix">
            <header class="ldse-section--header">
                <h2><a href="#d" class="ldse-icon-ko-tri-down">Summary</a></h2>
                <span class="subtext"></span>
            </header>
            <div class="ldse-section--body"></div>
        </section>
        <section id="filters" class="ldse-section ldse-filters ldse-clearfix">
            <header class="ldse-section--header">
                <h2><a href="#filter-body" class="ldse-icon-ko-tri-down">Filters</a></h2>
                <span class="subtext"></span>
            </header>
            <div class="ldse-section--body" id="filter-body">
                <form class="ldse-form ldse-search ldse-box ldse-tableize" action="" onsubmit="return(false)">
                   <span class="ldse-tableize--fill"><input type="text" placeholder="Search Content" id="filter-search" class="ldse-square-right" /></span><span><input type="button" id="searchBtn" value="&#xe40a;" class="clearTable ldse-square-left" onclick="C.clickSearch(event)" /></span>
                </form>
                <form class="ldse-rowFix ldse-makeCols ldse-form" data-cols="5">
                    <div id="statusFilterBox" class="ldse-block filters">
                        <header>
                            <h3>Status</h3>
                            <a href="#d" class="ldse-icon-ko-add ldse-icon">Add Status</a>
                        </header>
                        <div class="ldse-block--body">
                            { content-search:buildStatusSelect() }
                        </div>
                    </div>
                    <div id="siteFilterBox" class="ldse-block filters">
                        <header>
                            <h3>Site</h3>
                        </header>
                        <div class="ldse-block--body" style="display:block;">
                            { content-search:buildSiteSelect() }
                        </div>
                    </div>
                    <div class="ldse-block filters" id="languageFilterBox">
                        <header>
                            <h3>Locale</h3>
                            <a href="#d" class="ldse-icon-ko-add ldse-icon">+Add Locale</a>
                        </header>
                        <div class="ldse-block--body">
                            <select name="" id="" multiple="multiple" class="multiselect" >
                                <option value="">Please Select</option>
                                {
                                    for $locale as xs:string in content-search:pageSearch()/search:facet-value/@name
                                    order by $locale
                                    return <option value="{$locale}">{$locale}</option>
                                }
                            </select>
                        </div>
                    </div>
                    <div class="ldse-block filters" id="uriFilterBox">
                        <header>
                            <h3>Root Context/URI</h3>
                            <a href="#d" class="ldse-icon-ko-add ldse-icon">Add Filter</a>
                        </header>
                        <div class="ldse-block--body">
                            <div class="repeater table">
                                <dl class="repeat-this">
                                    <dt><a href="#d" class="remover ldse-icon-ko-remove ldse-icon">Remove</a></dt>
                                    <dd><input type="text" name="Root Context/URI" /></dd>
                                </dl>
                            </div>
                            <a href="#d" class="adder ldse-adder" style="">
                                <span class="ldse-icon-ko-add">Add Filter</span>
                            </a>
                        </div>
                    </div>
                    <div class="ldse-block filters" id="userFilterBox">
                        <header>
                            <h3 class="userFilterTitle">User</h3>
                            <a href="#d" class="ldse-icon-ko-add ldse-icon">Add User</a>
                        </header>
                        <div class="ldse-block--body">
                            <div class="repeater table">
                                <dl class="repeat-this">
                                    <dt><a href="#d" class="remover ldse-icon-ko-remove ldse-icon">Remove</a></dt>
                                    <dd><input type="text" name="User" /></dd> <!-- onblur="T.changeFilter()" onkeydown="T.reloadOnEnter()" removed these-->
                                </dl>
                            </div>
                            <a href="#d" class="adder ldse-adder" style="">
                                <span class="ldse-icon-ko-add">Add Filter</span>
                            </a>
                        </div>
                    </div>
                    {(:
                    <div class="ldse-block filters" id="categoryFilterBox">
                        <header>
                            <h3>Category</h3>
                            <a href="#d" class="ldse-icon-ko-add ldse-icon">Add Category</a>
                        </header>
                        <div class="ldse-block--body">
                            <div class="repeater table">
                                <dl class="repeat-this">
                                    <dt><a href="#d" class="remover ldse-icon-ko-remove ldse-icon">Remove</a></dt>
                                    <dd><input type="text" name="Catgegory" /></dd> <!-- onblur="T.changeFilter()" onkeydown="T.reloadOnEnter()" removed these-->
                                </dl>
                            </div>
                            <a href="#d" class="adder ldse-adder" style="">
                                <span class="ldse-icon-ko-add">Add Filter</span>
                            </a>
                        </div>
                    </div>:)}
                    <div class="ldse-block filters" id="dateFilterBox" data-width="250">
                        <header>
                            <h3 id="dateFilterTitle">Date Range</h3>
                            <a href="#d" class="ldse-icon-ko-add ldse-icon">Add Date Range</a>
                        </header>
                        <div class="ldse-block--body">
                             <div class="table">
                                <dl>
                                    <dt><label for="start">Start</label></dt>
                                    <dd>
                                        <input type="hidden" name="startHidden" value="" id="startHidden" class="ldse-has-ldse-icon" />
                                        <input type="text" name="start" value="" id="start" class="ldse-has-ldse-icon" />
                                        <b class="ldse-icon-calendar"></b>
                                    </dd>
                                </dl>
                                <dl>
                                    <dt><label for="end">End</label></dt>
                                    <dd>
                                        <input type="hidden" name="endHidden" value="" id="endHidden" />
                                        <input type="text" name="end" value="" id="end" class="ldse-has-ldse-icon" />
                                        <b class="ldse-icon-calendar"></b>
                                    </dd>
                                </dl>
                            </div>
                        </div>
                    </div>
                    <div class="ldse-block filters" id="followingFilterBox" data-width="250">
                        <header>
                            <h3 id="followingFilterTitle">Following</h3>
                            <a href="#d" class="ldse-icon-ko-add ldse-icon">Add Following</a>
                        </header>
                        <div class="ldse-block--body">
                             <div class="table">
                                <dl>
                                    <dt></dt>
                                    <dd>
                                        <input type="checkbox" name="following" value="true" id="following"/>
                                        <label for="following">I Am Following</label>
                                    </dd>
                                </dl>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
            <div id="filterButtons">
                <div class="ldse-form ldse-fullbleed ldse-section--body">
                    <hr/>
                    <div class="ldse-fullbleed ldse-section--body">
                        <div class="ldse-table-buttons">
                            <button id="applyFilterBtn" class="clearTable ldse-button primary ldse-icon-check2">Apply</button>
                            <button id="cancelFilterBtn" class="ldse-button ldse-icon-x">Cancel</button>
                            <button id="clearFilterBtn" class="clearTable ldse-button secondary ldse-icon-ko-x ldse-icon" title="Clear">Clear</button>
                        </div>
                    </div>
                </div>
            </div>
        </section>
        <section id="sensitive-content-warning">
        </section>
        <section id="details" class="ldse-section ldse-clearfix closed">
      <header class="ldse-section--header">
        <h2>
          <a href="#detail-body" class="ldse-icon-ko-tri-down">Details</a>
        </h2>
        <div class="ldse-pagination">
          <span class="ldse-pagination--shownum">Show&nbsp;
            {
              for $value as xs:int in (10, 25, 50, 100)
              return
                <span>
                  <a id="pageSize{$value}" class="saveWordCount" data-count="{$value}" href="#" onclick="DetailTable.Pagination.changePageSize({$value}, function(){{C.displayTContent(false);}});">{$value}</a>
                </span>
            }
          </span>
          <a id="prevPage" href="#" class="saveWordCount ldse-icon-ko-tri-left ldse-icon" onclick="DetailTable.Pagination.changePage(-1, function(){{C.displayTContent(false);}}); return false;">&lt; </a>
          <span id="pageTotal">&nbsp; Page <span id="currentPage">1</span> of <span id="totalPages">0</span> &nbsp;</span>
          <a id="nextPage" href="#" class="saveWordCount ldse-icon-ko-tri-right ldse-icon" onclick="DetailTable.Pagination.changePage(1, function(){{C.displayTContent(false);}}); return false;"> &gt;</a>
        </div>
      </header>
            <div class="ldse-section--body ldse-fullbleed ldse-form">
                <div class="ldse-clearfix">
                    <div class="ldse-tab-down hide-small-values">
                        <dl>
                            <dt>Words:</dt> <dd>0</dd>
                            <dt>TGP:</dt> <dd>0</dd>
                        </dl>
                    </div>
                    <div class="ldse-table-buttons">
                        <button id="action-back" class="ldse-button primary ldse-icon-send">Publish</button>
                        <button id="action-complete" class="ldse-button secondary ldse-icon-edit" onclick="editContent(); return false;">Edit</button>
                        <button id="action-block" class="ldse-button destructive ldse-icon-trash ldse-icon" title="Delete">Delete</button>
                        <button id="action-export" class="ldse-button secondary ldse-icon-download ldse-icon" title="Export">Export</button>
                    </div>
                </div>
        <table id="detail-table" class="ldse-table ldse-fullbleed">
          <thead/>
          <tbody id="detail-table-body"/>
        </table>
            </div>
        </section>
    </content>

return (
    core:template-apply(
        $title,
        $thisPage,
        <page>
            {$head}
            {$content}
            {$scripts}
            <options></options>
        </page>
    )
)
