xquery version "1.0-ml";
 
module namespace content-settings = "http://lds.org/code/shared/lds-edit/new-content-manager/content-settings";
 
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace content-workflow = "http://lds.org/code/shared/lds-edit/new-content-manager/content-workflow" at "content-workflow.xqy";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace ldse = "http://lds.org/code/lds-edit";
 
declare option xdmp:mapping "true";

declare variable $content-settings as element(ldse:content-settings) := (cts:search(/ldse:content-settings, core:get-filter-query()), $DEFAULT)[1]; 
declare variable $workflow as element(ldse:content-workflow) := ( $content-settings/ldse:content-workflow, $DEFAULT/ldse:content-workflow )[1]; 
declare variable $columns as element(ldse:columns) := ( $content-settings/ldse:columns, $DEFAULT/ldse:columns )[1];
 
declare variable $DEFAULT as element(ldse:content-settings) := 
 <content-settings xmlns="http://lds.org/code/lds-edit">
       <columns>
        <column title="Type" id="fileType" class="hide-small">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string" collation="http://marklogic.com/collation/">
                <element ns="http://lds.org/code/lds-edit" name="document"/>
                <attribute ns="" name="type" />
            </sort-order>
        </column>
        <column title="Type" id="commentFileType" class="hide-small">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string" collation="http://marklogic.com/collation/">
                <element ns="http://lds.org/code/lds-edit/history" name="document"/>
                <attribute ns="" name="type" />
            </sort-order>
        </column>
        <column title="Root" class="hide-small" id="root">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string" collation="http://marklogic.com/collation/">
                <element ns="http://lds.org/code/lds-edit" name="document"/>
                <attribute ns="" name="uri" />
            </sort-order>
        </column>
        <column title="Root" class="hide-small" id="commentRoot">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string" collation="http://marklogic.com/collation/">
                <element ns="http://lds.org/code/lds-edit/history" name="document"/>
                <attribute ns="" name="uri" />
            </sort-order>
        </column>
        <column class="title" title="Title" id="title" link="uri" command="forceBreak">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string" collation="http://marklogic.com/collation/">
                <element ns="http://lds.org/code/lds-edit" name="document"/>
                <attribute ns="" name="title" />
            </sort-order>
        </column>
        <column class="title" title="Title" id="commentTitle" link="uri" command="forceBreak">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string" collation="http://marklogic.com/collation/">
                <element ns="http://lds.org/code/lds-edit/history" name="document"/>
                <attribute ns="" name="title" />
            </sort-order>
        </column>
        <column title="Locale" class="hide-med" id="locale">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string" collation="http://marklogic.com/collation/">
                <element ns="http://lds.org/code/lds-edit" name="document"/>
                <attribute ns="" name="locale" />
            </sort-order>
       </column>
       <column title="Status" class="hide-med" id="status" />
        <column title="Published By" class="hide-med" id="publisher">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string" collation="http://marklogic.com/collation/">
                <element ns="http://lds.org/code/lds-edit" name="publish-date"/>
                <attribute ns="" name="username" />
            </sort-order>
        </column>
        <column title="Unpublished By" class="hide-med" id="unpublisher">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string" collation="http://marklogic.com/collation/">
                 <element ns="http://lds.org/code/lds-edit" name="unpublish-date"/>
                 <attribute ns="" name="username" />
            </sort-order>
        </column>
        <column title="Created By" class="hide-med" id="creator">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string">
                <element ns="http://lds.org/code/lds-edit" name="created"/>
                <attribute ns="" name="username" />
            </sort-order>
        </column>
        <column title="Scheduled By" class="hide-med" id="scheduledPublisher">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string">
                <element ns="http://lds.org/code/lds-edit" name="schedule-publish"/>
                <attribute ns="" name="username" />
            </sort-order>
        </column>
        <column title="Scheduled By" class="hide-med" id="scheduledUnpublisher">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string">
                <element ns="http://lds.org/code/lds-edit" name="schedule-unpublish"/>
                <attribute ns="" name="username" />
            </sort-order>
        </column>
        <column title="Comment" class="hide-med" read-more="uri" id="comment" />
        <column title="Comment By" class="hide-med" id="commenter" />
        <column type="date" title="Created Date" class="hide-large" id="date-created" command="formatDate">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:dateTime" >
                <element ns="http://lds.org/code/lds-edit" name="created"/>
                <attribute ns="" name="date" />
            </sort-order>
        </column>
        <column title="Modified By" class="hide-med" id="modifier">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:string">
                <element ns="http://lds.org/code/lds-edit" name="last-modified"/>
                <attribute ns="" name="username" />
            </sort-order>
        </column>
       <column type="date" title="Modified Date" class="hide-large" id="date-modified" command="formatDate">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:dateTime" >
                <element ns="http://lds.org/code/lds-edit" name="last-modified"/>
                <attribute ns="" name="date" />
            </sort-order>
       </column>
       <column type="date" title="Published Date" class="hide-large" id="published" command="formatDate">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:dateTime" >
                 <element ns="http://lds.org/code/lds-edit" name="publish-date"/>
                 <attribute ns="" name="date" />
            </sort-order>
       </column>
       <column type="date" title="Unpublished Date" class="hide-large" id="unpublished-date" command="formatDate">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:dateTime" >
                <element ns="http://lds.org/code/lds-edit" name="unpublish-date"/>
                <attribute ns="" name="date" />
            </sort-order>
       </column>
       <column type="date" title="Scheduled Unpublish Date" class="hide-large" id="scheduledUnpublish" command="formatDate">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:dateTime" >
                <element ns="http://lds.org/code/lds-edit" name="schedule-unpublish"/>
                <attribute ns="" name="dateTime" />
            </sort-order>
       </column>
       <column type="date" title="Scheduled Publish Date" class="hide-large" id="scheduledPublish" command="formatDate">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:dateTime" >
                <element ns="http://lds.org/code/lds-edit" name="schedule-publish"/>
                <attribute ns="" name="dateTime" />
            </sort-order>
       </column>
       <column type="date" title="Comment Date" class="hide-large" id="commentedDate" command="formatDate">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:dateTime" >
                <element ns="http://lds.org/code/lds-edit/history" name="comment"/>
                <attribute ns="" name="date" />
            </sort-order>
       </column>
       <column type="date" title="Submitted Date" class="hide-large" id="submissionSubmittedDate" command="formatDate">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:dateTime" >
                <element ns="http://lds.org/code/lds-edit" name="submission"/>
                <attribute ns="" name="date" />
            </sort-order>
       </column>
       <column type="date" title="Created Date" class="hide-large" id="submissionCreatedDate" command="formatDate">
            <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:dateTime" >
                <element ns="http://lds.org/code/lds-edit" name="created"/>
                <attribute ns="" name="date" />
            </sort-order>
       </column>
    </columns>
    <content-workflow xmlns="http://lds.org/code/lds-edit">
        <step title="Created" name="submission-created">
        	<user-filter element-name="created" title="Created By"/>
        	<date-filter element-name="created" title="Created Date"/>
            <permission>ldse:add-submission</permission>
            <transform-results xmlns="http://marklogic.com/appservices/search" apply="build-submission-created" ns="http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet"
                at="/new-content-manager/modules/json-snippet.xqy" />
            <query status="submission-created"/>
            <default-sort direction="descending">date-created</default-sort>
        </step>
        <step title="Submitted" name="submission-submitted">
        	<user-filter element-name="submission" title="Submitted By"/>
        	<date-filter element-name="submission" title="Submitted Date"/>
            <permission>ldse:add-submission</permission>
            <transform-results xmlns="http://marklogic.com/appservices/search" apply="build-submission-submitted" ns="http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet"
                at="/new-content-manager/modules/json-snippet.xqy" />
            <query status="submission-submitted"/>
            <default-sort direction="descending">submissionSubmittedDate</default-sort>
        </step>
        <step title="Draft" name="draft">
            <user-filter element-name="created" title="Created By"/>
            <date-filter element-name="created" title="Created Date"/>
            <transform-results xmlns="http://marklogic.com/appservices/search" apply="build-preview-content-json" ns="http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet"
                at="/new-content-manager/modules/json-snippet.xqy" />
            <permission>ldse:add-doc</permission>
            <permission>ldse:add-submission</permission>
            <query status="preview"/>
            <back title="Publish" name="publish-files" ns="" at="" action="ldse:publish">
                <permission>ldse:publish-doc</permission>
                <template type="form" additional="language,teaser" id="form-publish" name="publish-templates" ns="" at=""/>
            </back>
            <block title="Delete" name="deleteTemplate" action="ldse:delete">
                <permission>ldse:delete-doc</permission>
                <!-- Remove the whole translation-event -->
                {(:<template type="form" additional="language,teaser" id="form-delete" name="delete-template" ns="" at=""/>:)}
                <template type="delete" id="deleteTemplate" title="Delete Files" />
            </block>
            <complete title="Edit">
                <permission>ldse:edit-doc</permission>
                <!--<template type="form" additional="translation" id="edit" name="send-template" ns="" at=""/>-->
            </complete>
            <default-sort direction="descending">date-created</default-sort>
        </step>
        <step title="Published" name="publish">
            <date-filter element-name="publish-date" title="Published Date"/>
            <user-filter element-name="publish-date" title="Published By"/>
            <transform-results xmlns="http://marklogic.com/appservices/search" apply="build-published-content-json" ns="http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet"
                at="/new-content-manager/modules/json-snippet.xqy" />
            <permission>ldse:publish-doc</permission>
            <permission>ldse:view-all-content-manager-statuses</permission>
            <query status="published"/>
            <default-sort direction="descending">published</default-sort>
        </step>
        <step title="Unpublished" name="unpublished">
            <date-filter element-name="unpublish-date" title="Unpublished Date"/>
            <user-filter element-name="unpublish-date" title="Unpublished By"/>
            <transform-results xmlns="http://marklogic.com/appservices/search" apply="build-unpublished-content-json" ns="http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet"
                at="/new-content-manager/modules/json-snippet.xqy" />
            <permission>ldse:unpublish-doc</permission>
            <permission>ldse:view-all-content-manager-statuses</permission>
            <query status="unpublish"/>
            <block title="Delete" name="deleteTemplate" action="ldse:delete">
                <permission>ldse:delete-doc</permission>
                <!-- Remove the whole translation-event -->
                {(:<template type="form" additional="language,teaser" id="form-delete" name="delete-template" ns="" at=""/>:)}
                <template type="delete" id="deleteTemplate" title="Delete Files" />
            </block>
            <back title="Publish" name="reasonTemplate" ns="" at="" action="ldse:publish">
                <permission>ldse:publish-doc</permission>
                <template type="form" additional="language,teaser" id="reasonTemplate" name="publish-template" ns="" at=""/>
            </back>
            <default-sort direction="descending">unpublish-date</default-sort>
        </step>
        <step title="Modified" name="modified">
            <user-filter element-name="last-modified" title="Modified By"/>
            <date-filter element-name="last-modified" title="Modified Date"/>
            <transform-results xmlns="http://marklogic.com/appservices/search" apply="build-modified-content-json" ns="http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet"
                at="/new-content-manager/modules/json-snippet.xqy" />
            <permission>ldse:add-doc</permission>
            <permission>ldse:view-all-content-manager-statuses</permission>
            <query status="preview" name="modified" />
            <back title="Publish" name="publish-files" ns="" at="" action="ldse:publish">
                <permission>ldse:publish-doc</permission>
                <template type="form" additional="language,teaser" id="form-publish" name="publish-templates" ns="" at=""/>
            </back>
            <block title="Delete" name="deleteTemplate" action="ldse:delete">
                <permission>ldse:delete-doc</permission>
                <template type="delete" id="deleteTemplate" title="Delete Files" />
            </block>
            <complete title="Edit">
                <permission>ldse:edit-doc</permission>
            </complete>
            <default-sort direction="descending">date-modified</default-sort>
        </step>
        <step title="Scheduled Publish" name="schedule-publish">
            <date-filter element-name="schedule-publish" title="Scheduled Publish Date"/>
            <user-filter element-name="schedule-publish" title="Scheduled By"/>
            <transform-results xmlns="http://marklogic.com/appservices/search" apply="build-scheduled-publish-json" ns="http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet"
                at="/new-content-manager/modules/json-snippet.xqy" />
            <permission>ldse:publish-doc</permission>
            <permission>ldse:view-all-content-manager-statuses</permission>
            <query status="schedulePublish"/>
            <default-sort direction="ascending">scheduledPublish</default-sort>
        </step>
        <step title="Scheduled Unpublish" name="schedule-unpublish">
            <date-filter element-name="schedule-unpublish" title="Scheduled Unpublish Date"/>
            <user-filter element-name="schedule-unpublish" title="Scheduled By"/>
            <transform-results xmlns="http://marklogic.com/appservices/search" apply="build-scheduled-unpublish-json" ns="http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet"
                at="/new-content-manager/modules/json-snippet.xqy" />
            <permission>ldse:unpublish-doc</permission>
            <permission>ldse:view-all-content-manager-statuses</permission>
            <query status="scheduleUnpublish"/>
            <default-sort direction="ascending">schedule-unpublish</default-sort>
        </step>
        <step title="Commented On" name="comments">
            <user-filter element-name="comment" title="Commented By"/>
            <date-filter element-name="comment" title="Comment Date"/>
            <transform-results xmlns="http://marklogic.com/appservices/search" apply="build-comment-json" ns="http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet"
                at="/new-content-manager/modules/json-snippet.xqy" />
            <permission>ldse:edit-doc</permission>
            <permission>ldse:view-all-content-manager-statuses</permission>
            <query status="comments"/>
            <default-sort direction="descending">commentedDate</default-sort>
        </step>
    </content-workflow>
</content-settings>;

declare function content-settings:get-content-settings() as element(ldse:content-settings) {
    $content-settings
};

declare function content-settings:get-workflow() as element(ldse:content-workflow) {
    $workflow
};

declare function content-settings:get-columns() as element(ldse:columns) {
    $columns
};

declare function content-settings:get-column-by-id($id as xs:string) as element(ldse:column) {
    $columns/ldse:column[@id eq $id]
};

declare function content-settings:getDateElementNameByStatus(
    $status as xs:string
) as xs:string? {
   let $step as element(ldse:step)? :=  content-workflow:get-step-by-name( $status)
   return $step/ldse:date-filter/@element-name
   
};

declare function content-settings:getUserElementNameByStatus(
    $status as xs:string
) as xs:string? {
   let $step as element(ldse:step)? :=  content-workflow:get-step-by-name($status)
   return $step/ldse:user-filter/@element-name
};
