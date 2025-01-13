xquery version "1.0-ml";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

let $login := okta:okta-login()
return
    core:template-apply(
        "Content Manager",
        '/content',
        <page>
            <controller>ContentManager</controller>
            <head>
                <link rel="stylesheet" href="{$settings:shared-prefix}/translation/resources/styles/translation.css" />
                <link rel="stylesheet" href="{$settings:shared-prefix}/translation/resources/styles/calendar.css" />
            </head>
            <content>
                <section id="summary" class="ldse-section ldse-summary ldse-clearfix" ng-cloak="">
                    <header class="ldse-section--header">
                        <h2><a href="#d" class="ldse-icon-ko-tri-down">Summary</a></h2>
                        <span class="subtext"></span>
                    </header>
                    <div class="ldse-section--body">
                        <section class="ldse-block" ng-repeat="status in items[0] | filter:statusFilter">
                            <header>
                                <h3>
                                    <a href="#d" ng-click="clickStatus(status)">{{{{status.title}}}}</a>
                                </h3>
                            </header>
                            <div class="ldse-block--body">
                                <dl class="ldse-clearfix">
                                    <dt>Docs</dt>
                                    <dd>{{{{status.docs}}}}</dd>
                                    <dt>Oldest</dt>
                                    <dd>{{{{status.oldest}}}}</dd>
                                </dl>
                            </div>
                        </section>
                    </div>
                </section>
                <section class="ldse-section ldse-filters ldse-clearfix">
                    <header class="ldse-section--header">
                        <h2><a href="#filter-body" class="ldse-icon-ko-tri-down">Filters</a></h2>
                        <span class="subtext"></span>
                    </header>
                    <div class="ldse-section--body" id="filter-body">
                        <form class="ldse-form ldse-search ldse-box ldse-tableize" action="" name="searchTextForm">
                            <span class="ldse-tableize--fill">
                                <input type="text" placeholder="Search Strings" ng-model="searchText" id="filter-search" class="ldse-square-right"/>
                            </span>
                            <span>
                                <input type="button" ng-click="search();" value="&#xe40a;" class="ldse-square-left" id="questionButton"/>
                            </span>
                        </form>
                        <form class="ldse-rowFix ldse-makeCols ldse-form" name="filterForm">
                            <div id="statusFilterBox" class="ldse-block filters" ng-cloak="">
                                <header ng-switch="" on="showStatus">
                                    <h3>Status</h3>
                                    <a href="#d" class="ldse-icon-ko-add ldse-icon" ng-click="changeStatus()" style="display:block;" ng-switch-when="false">Add Status</a>
                                    <a href="#d" class="ldse-icon-ko-x ldse-icon" ng-click="changeStatus()" style="display:block;" ng-switch-when="true">Remove Status</a>
                                </header>
                                <div class="ldse-angular-block--body" ng-show="showStatus">
                                     <select-box id="status-select" ng-change="clickStatus()" ng-model="jsonData.status" optexp="status.name as status.title for status in items[0]"></select-box>
                                </div>
                            </div>
                            <div class="ldse-block filters" id="languageFilterBox">
                                <header ng-switch="" on="showLocale">
                                    <h3>Locale</h3>
                                    <a href="#d" class="ldse-icon-ko-add ldse-icon" ng-click="changeLocale()" style="display:block;" ng-switch-when="false">Add Locale</a>
                                    <a href="#d" class="ldse-icon-ko-x ldse-icon" ng-click="changeLocale()" style="display:block;" ng-switch-when="true">Remove Locale</a>
                                </header>
                                <div class="ldse-angular-block--body" ng-show="showLocale">
                                    <div class="repeater table">
                                        <dt></dt>
                                        <dd>
                                            <multi-box name="locales" value="jsonData.locales" options="localeOptions"></multi-box>
                                        </dd>
                                    </div>
                                </div>
                            </div>
                            <div class="ldse-block filters" id="uriFilterBox">
                                <header ng-switch="" on="showUri">
                                    <h3>Root Context/URI</h3>
                                    <a href="#d" class="ldse-icon-ko-add ldse-icon" ng-click="changeUriFilter()" style="display:block;" ng-switch-when="false">Add URI</a>
                                    <a href="#d" class="ldse-icon-ko-x ldse-icon" ng-click="changeUriFilter()" style="display:block;" ng-switch-when="true">Remove URI</a>
                                </header>
                                <div class="ldse-angular-block--body" ng-show="showUri">
                                    <div class="repeater table">
                                        <dl>
                                            <dt></dt>
                                            <dd><multi-text name="uri" model="jsonData.uris"></multi-text></dd>
                                        </dl>
                                    </div>
                                </div>
                            </div>
                            <div class="ldse-block filters" id="userFilterBox" ng-show="jsonData.status != ''">
                                <header ng-switch="" on="showUser">
                                    <h3 class="userFilterTitle">User</h3>
                                    <a href="#d" class="ldse-icon-ko-add ldse-icon" ng-click="changeUserFilter()" style="display:block;" ng-switch-when="false">Add User</a>
                                    <a href="#d" class="ldse-icon-ko-x ldse-icon" ng-click="changeUserFilter()" style="display:block;" ng-switch-when="true">Remove User</a>
                                </header>
                                <div class="ldse-angular-block--body" ng-show="showUser">
                                    <div class="repeater table">
                                        <dl class="repeat-this">
                                            <dt></dt>
                                            <dd><multi-text name="uri" model="jsonData.users"></multi-text></dd>
                                        </dl>
                                    </div>
                                </div>
                            </div>
                            <div class="ldse-block filters ldse-last" id="dateAddedFilterBox" ng-show="jsonData.status != ''">
                                <header id="dateFilter" ng-switch="" on="showDate">
                                    <h3>Date Range</h3>
                                    <a href="#d" class="ldse-icon-ko-add ldse-icon" ng-click="changeDateFilter()" style="display:block;" ng-switch-when="false">Add Date Filter</a>
                                    <a href="#d" class="ldse-icon-ko-x ldse-icon" ng-click="changeDateFilter()" style="display:block;" ng-switch-when="true">Remove Date Filter</a>
                                </header>
                                <div class="ldse-angular-block--body" ng-show="showDate">
                                    <div class="table">
                                        <dl>
                                            <dt>
                                                <label for="startDate">Start</label>
                                            </dt>
                                            <dd>
                                                <input type="text" ng-datepicker="" ng-model="jsonData.startDate" name="startDate" value="" id="start" class="ldse-has-ldse-icon datepicker"/><b class="ldse-icon-calendar"></b>
                                            </dd>
                                        </dl>
                                        <dl>
                                            <dt>
                                                <label for="endDate">End</label>
                                            </dt>
                                            <dd>
                                                <input type="text" ng-datepicker="" ng-model="jsonData.endDate" name="endDate" value="" id="end" class="ldse-has-ldse-icon datepicker"/><b class="ldse-icon-calendar"></b>
                                            </dd>
                                        </dl>
                                    </div>
                                </div>
                            </div>
                            <div class="ldse-block filters" id="followingFilterBox" data-width="250">
                                <header ng-switch="" on="showFollowing">
                                    <h3 id="followingFilterTitle">Following</h3>
                                    <a href="#d" class="ldse-icon-ko-add ldse-icon" ng-click="changeFollowing()" style="display:block;" ng-switch-when="false">Add Following</a>
                                    <a href="#d" class="ldse-icon-ko-x ldse-icon" ng-click="changeFollowing()" style="display:block;" ng-switch-when="true">Remove Following</a>
                                </header>
                                <div class="ldse-angular-block--body" ng-show="showFollowing">
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
                        <div id="" >
                            <div class="ldse-form ldse-fullbleed ldse-section--body">
                                <hr/>
                                <div class="ldse-fullbleed ldse-section--body">
                                    <div class="ldse-table-buttons">
                                        <button id="applyFilterBtn" ng-click="applyFilters()" class="clearTable ldse-button primary ldse-icon-check2" ng-show="filterForm.$dirty">Apply</button>
                                        <button id="cancelFilterBtn" ng-click="cancelFilters()" class="clearTable ldse-button ldse-icon-ko-x" ng-show="filterForm.$dirty">Cancel</button>
                                        <button id="clearFilterBtn" ng-click="clearFilters()" class="ldse-button secondary ldse-icon-ko-x ldse-icon" ng-show="clearFiltersButton">Clear Filters</button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
                <section id="detailsItem" class="ldse-section ldse-clearfix">
                    <header class="ldse-section--header">
                        <h2>
                            <a href="#detail-bodyItem" class="ldse-icon-ko-tri-down">Details</a>
                        </h2>
                        <div class="ldse-pagination">
                            <span class="ldse-pagination--shownum">Show&nbsp;
                                {
                                    for $value as xs:int in (10, 25, 50, 100)
                                    return (
                                        <span>
                                            <a id="page-size-{$value}" class="saveWordCount change-page-size" ng-click="changePageSize({$value})">{if(fn:not($value = 25)) then attribute href {"#"} else ()}{$value}</a>
                                        </span>
                                    )
                                }
                            </span>
                            <a class="ldse-icon-ko-tri-left ldse-icon" ng-click="changePage(-1);" ng-show="currentPage > 1">&lt; </a>
                            <span>&nbsp; Page {{{{currentPage}}}} of {{{{pageInfo.pages}}}} &nbsp;</span>
                            <a class="ldse-icon-ko-tri-right ldse-icon" ng-click="changePage(1);" ng-show="pageInfo.pages > currentPage"> &gt;</a>
                        </div>
                    </header>
                    <div class="ldse-section--body ldse-fullbleed ldse-form">
                        <div class="ldse-clearfix">
                            <div class="ldse-tab-down hide-small-values">
                                <dl>
                                    <dt>Words:</dt> <dd>{{{{words}}}}</dd>
                                    <dt>TGP:</dt> <dd>{{{{tgp}}}}</dd>
                                </dl>
                            </div>
                            <div class="ldse-table-buttons">
                                {
                                    if ( ac:has-permission('ldse:publish-doc', (), ()) ) then (
                                        <button id="action-back" class="ldse-button primary ldse-icon-send" ng-show="showPublishButton()" ng-click="performAction('ldse:publish')">Publish</button>
                                    ) else ()
                                }
                                <button id="action-complete" class="ldse-button secondary ldse-icon-edit" ng-show="showEditButton()" ng-click="editContent()">Edit</button>
                                {
                                    if ( ac:has-permission('ldse:delete-doc', (), ()) ) then (
                                        <button id="action-block" class="ldse-button destructive ldse-icon-trash ldse-icon" ng-show="showDeleteButton()" ng-click="performAction('ldse:delete')" title="Delete">Delete</button>
                                    ) else ()
                                }
                                <button id="action-export" class="ldse-button secondary ldse-icon-download ldse-icon" title="Export" ng-show="showActionButton('export')" >Export</button>

                            </div>
                        </div>
                        <table id="detail-tableItem" class="ldse-table ldse-fullbleed">
                            <thead>
                                <tr ng-cloak="" ng-switch="" on="currentStatus">
                                    <th>
                                        <span class="ldse-option box-only">
                                            <input type="checkbox" class="styled checkall" id="details-checkall" ng-model="checkAll" ng-click="checkAllBoxes()" />
                                            <label for="details-checkall">Check</label>
                                        </span>
                                    </th>
                                    <th></th>
                                    <th class="hide-small sortable" ng-class="{{sort: jsonData.columnId == 'fileType', asc: jsonData.ascending, desc: !jsonData.ascending}}"><a ng-click="changeSort('fileType')">Type</a></th>
                                    <th class="hide-small sortable" ng-class="{{sort: jsonData.columnId == 'root', asc: jsonData.ascending, desc: !jsonData.ascending}}"><a ng-click="changeSort('root')">Root</a></th>
                                    <th class="sortable" ng-class="{{sort: jsonData.columnId == 'title', asc: jsonData.ascending, desc: !jsonData.ascending}}"><a ng-click="changeSort('title')">Title</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'locale', asc: jsonData.ascending, desc: !jsonData.ascending}}"><a ng-click="changeSort('locale')">Locale</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'creator', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="draft"><a ng-click="changeSort('creator')">Created By</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'date-created', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="draft"><a ng-click="changeSort('date-created')">Created Date</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'submissionSubmittedDate', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="submitted"><a ng-click="changeSort('submissionSubmittedDate')">Submitted Date</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'publisher', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="publish"><a ng-click="changeSort('publisher')">Published By</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'published', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="publish"><a ng-click="changeSort('published')">Published Date</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'unpublishDate', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="unpublished"><a ng-click="changeSort('root')">Unpublished By</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'unpublished-date', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="unpublished"><a ng-click="changeSort('unpublished-date')">Unpublished Date</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'modifier', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="modified"><a ng-click="changeSort('modifier')">Modified By</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'date-modified', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="modified"><a ng-click="changeSort('date-modified')">Modified Date</a></th>
                                    <th class="hide-med" ng-switch-when="comments">Comment</th>
                                    <th class="hide-med" ng-switch-when="comments">Comment By</th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'commentedDate', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="comments"><a ng-click="changeSort('commentedDate')">Comment Date</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'scheduledPublisher', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="scheduleUnpublish"><a ng-click="changeSort('scheduledPublisher')">Scheduled By</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'scheduledPublish', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="schedulePublish"><a ng-click="changeSort('scheduledPublish')">Scheduled Publish Date</a></th>
                                    <th class="hide-med sortable" ng-class="{{sort: jsonData.columnId == 'unpublishDate', asc: jsonData.ascending, desc: !jsonData.ascending}}" ng-switch-when="scheduleUnpublish"><a ng-click="changeSort('root')">Scheduled Unpublish Date</a></th>
                                    <th class="hide-med" ng-switch-when="">Status</th>
                                </tr>
                            </thead>
                            <tbody id="detail-table-bodyItem" ng-cloak="">
                                <tr ng-repeat="item in items[1] | setvisible:false | limitTo:startLimit | limitTo:endLimit | setvisible:true" ng-switch="" on="currentStatus">
                                    <td>
                                        <span class="ldse-option box-only">
                                            <input class="rowSelect" type="checkbox" id="box-1-{{{{$index}}}}" ng-model="item.checked" data-words="{{{{item.words}}}}"/>
                                            <label for="box-1-{{{{$index}}}}">Check</label>
                                        </span>
                                    </td>
                                    <td>
                                        <a href="{{{{item.previewUrl}}}}" onclick="ICE.linkToItem(this.href, 'item.id'); return false;" class="ldse-icon-preview ldse-icon big">Preview</a>
                                    </td>
                                    <td class="hide-small">{{{{item.fileType}}}}</td>
                                    <td class="hide-small">{{{{item.root}}}}</td>
                                    <td>
                                        <a ng-click="editContent(item)">{{{{item.title}}}}</a>
                                    </td>
                                    <td class="hide-med">{{{{item.locale}}}}</td>
                                    <td class="hide-med" ng-switch-when="">{{{{item.status}}}}</td>
                                    <td class="hide-med" ng-switch-when="draft">{{{{item.creator}}}}</td>
                                    <td class="hide-med" ng-switch-when="draft">{{{{item.dateCreated}}}}</td>
                                    <td class="hide-med" ng-switch-when="publish">{{{{item.publisher}}}}</td>
                                    <td class="hide-med" ng-switch-when="publish">{{{{item.datePublished}}}}</td>
                                    <td class="hide-med" ng-switch-when="unpublished">{{{{item.unpublisher}}}}</td>
                                    <td class="hide-med" ng-switch-when="unpublished">{{{{item.dateUnpublished}}}}</td>
                                    <td class="hide-med" ng-switch-when="modified">{{{{item.modifier}}}}</td>
                                    <td class="hide-med" ng-switch-when="modified">{{{{item.dateModified}}}}</td>
                                    <td class="hide-med" ng-switch-when="comments">{{{{item.comment}}}}</td>
                                    <td class="hide-med" ng-switch-when="comments">{{{{item.commenter}}}}</td>
                                    <td class="hide-med" ng-switch-when="comments">{{{{item.commentedDate}}}}</td>
                                    <td class="hide-med" ng-switch-when="scheduleUnpublish">{{{{item.scheduledUnpublisher}}}}</td>
                                    <td class="hide-med" ng-switch-when="scheduleUnpublish">{{{{item.dateScheduledUnpublished}}}}</td>
                                    <td class="hide-med" ng-switch-when="schedulePublish">{{{{item.scheduledPublisher}}}}</td>
                                    <td class="hide-med" ng-switch-when="schedulePublish">{{{{item.dateScheduledPublished}}}}</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </section>
                <dialog/>
                <messagebox/>
            </content>
            <scripts>
                 <script src="{$settings:shared-prefix}/ice/resources/script/ice.js" />
                 <script src="{$settings:shared-prefix}/resources/scripts/detail-table.js" type="text/javascript">&nbsp;</script>
                 <script type="text/javascript" src="{$settings:shared-prefix}/resources/scripts/angularjs/angular.min.js"></script>
                 <script type="text/javascript" src="{$settings:shared-prefix}/resources/scripts/angularjs/angular-sanitize.min.js"></script>
                 <script type="text/javascript" src="{$settings:shared-prefix}/resources/scripts/angularjs/ldsp-ui-directives.js"></script>
                 <script src="{$settings:shared-prefix}/new-content-manager/resources/scripts/content-service.js"/>
                 <script src="{$settings:shared-prefix}/new-content-manager/resources/scripts/new-content.js"/>
{(:                 <script type="text/javascript">
                     var isSubmitter = {ac:has-permission("ldse:edit-submission", "", "") and fn:not(ac:has-permission("ldse:edit-any-submission", "", ""))};
                 </script>:)}

{(:                 {content-workflow:get-config()}:)}
             </scripts>
            <options></options>
        </page>
    )
