xquery version "1.0-ml";

module namespace setup = "http://lds.org/services/lds-publisher/setup-functions";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "/modules/document-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace hs = "http://marklogic.com/xdmp/status/host";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace ldses = "http://lds.org/code/lds-edit-services";

declare variable $port-map as map:map := map:map();
declare variable $existing-ports as element(ports)? := setup:get-ports();
declare variable $ports as xs:integer* := $existing-ports/port/xs:int(.);
declare variable $app-server-ports as xs:integer* := xdmp:host-status(xdmp:host())//hs:port;

(:declare function setup:inspectPorts(
    $port as xs:integer
) as xs:integer {
    setup:inspectPorts(xdmp:host-status(xdmp:host())//hs:port, $port)
};:)

declare function setup:inspectPorts(
    $ports as xs:integer*,
    $port as xs:integer
) as xs:integer {
    if ( $port = $ports or $port = $app-server-ports ) then (
        setup:inspectPorts($ports, $port + 5)
    ) else ( $port )
};

declare function setup:setup-app(
    $site-name as xs:string,
    $db-name as xs:string?,
    $username as xs:string,
    $port as xs:integer,
    $readWriteUser as xs:string,
    $readWritePass as xs:string,
    $readOnlyUser as xs:string,
    $readOnlyPass as xs:string,
    $contacts as element(ldses:contact)*,
    $env as xs:string?,
    $display-name as xs:string?,
    $shared-prefix as xs:string?
) as item()* {
    let $port-map-update as empty-sequence() := setup:update-port-map()
    let $preview-port as xs:integer := setup:inspectPorts($ports, $port)
    let $update-ports as item()* := setup:update-assigned-ports($preview-port)
    let $appxml as element(application) := setup:build-app-xml($site-name, $site-name, $username, $preview-port + 3, $preview-port, $preview-port + 1, $readWriteUser, $readWritePass, $readOnlyUser, $readOnlyPass, $contacts, $display-name, $env, $shared-prefix)
    let $subject as xs:string? := "Site Registered"
    let $body as xs:string? := fn:concat($site-name, ' has been registered to use the LDS-Publisher Services. Attached is the application.xml for the site. The application.xml must be deployed and F5 rules in place to begin using the application.')
    let $attachment :=
        <attachment>
            <file-name>{$site-name}-application.xml</file-name>
            <content-type>application/xml</content-type>
            <content>{xdmp:quote($appxml)}</content>
        </attachment>
    let $recipients as xs:string* := ( $settings:ldse-settings/ldse:recipients/ldse:email, $contacts/@email/fn:string() )
    return (
        for $recipient as xs:string in $recipients
        return (
            util:send-email-with-attachments($recipient, "", $subject, $body, "no-reply@ldschurch.org", "Registration Services", $attachment)
        )
    )
};

declare function setup:update-assigned-ports(
    $port as xs:int
) as item()* {
    let $ports as element(ports) :=
        <ports>{
            $existing-ports/@*,
            <port>{$port}</port>,
            $existing-ports/node()
        }</ports>
    return (
        if ( fn:exists($existing-ports) ) then (
            document:document-replace($existing-ports, $ports)
        ) else (
            document:document-insert('/preview/lds-edit-services/content/english/assigned-ports.xml', $ports)
        )
    )
};

declare function setup:update-port-map() as empty-sequence() {
    for $port as xs:string in setup:get-ports()
    return (
        map:put($port-map, $port, $port)
    )
};

declare function setup:get-ports() as element(ports)? {
    cts:search(/ports,
        core:get-filter-query()
    )
};

declare function setup:build-app-xml(
    $site-name as xs:string,
    $db-name as xs:string,
    $username as xs:string,
    $rest-port as xs:integer,
    $preview-port as xs:integer,
    $publish-port as xs:integer,
    $readWriteUser as xs:string,
    $readWritePass as xs:string,
    $readOnlyUser as xs:string,
    $readOnlyPass as xs:string,
    $contacts as element(ldses:contact)*,
    $display-name as xs:string,
    $env as xs:string?,
    $shared-prefix as xs:string?
) as element(application) {
    <application appName="{$site-name}" appDesc="Web services to provide access to LDS Publisher for {$site-name}">
        <roles>
            <role name="auth" desc="Users coming to setup a site" roles="app, *_app_lds-edit-services_app">
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-get-session-field" />
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-add-response-header" />
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-email" />
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/admin-module-read" />
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/admin-module-write" />
                <defaultPermissions roles="auth" access="ru" />
            </role>

            <role name="site_admin" desc="Grants full access to all areas of the application, and inherits from new roles as created"
            roles="auth, app, *_developer" />
            <role name="amp" desc="Role used for amping functions">
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-document-get"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-node-insert-child"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-filesystem-directory-create"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-filesystem-directory"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-filesystem-file-length"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-invoke"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-invoke-in"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-save"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-document-add-permissions"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-node-replace"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-add-response-header"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-spawn"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-login"/>
    		 	<executePrivilege action="*http://marklogic.com/xdmp/privileges/get-user"/>
    		 	<executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-spawn-in" />
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-read-cluster-config-file"/>			<!-- Needed when deleting a URI Privilege-->
            </role>
    		<role name="app" desc="code, shared content bundles, site files containing usernames - has no URI privilege to write" roles="*_app_lds-edit-services_app">
    			<executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-login" />
    			<executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-add-response-header" />
    		</role>
    		<role name="higherRiskAmp" desc="Grants specific privileges needed for amping functions">
    			<executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-value" />
    		</role>
    		<role name="LogParsingAmp" desc="Role used for amping log parsing functions">
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-data-directory"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/xdmp-filesystem-file"/>
                <executePrivilege action="*http://marklogic.com/xdmp/privileges/admin-module-read"/>
            </role>
    	</roles>
    	<users>
    		<user name="app" desc="LDS Edit Services" password="{$readOnlyPass}" roles="app" />
    		<user name="auth" desc="LDS Edit Services" password="{$readWritePass}" roles="auth" />
    		<user name="!{$site-name || 'Admin'}" desc="LDS Edit Services" password="{$readWritePass}" roles="site_admin" />
    	</users>
    	<dbs>
    		<db dbName="*Modules">
    			<dir name="/code/lds-edit-services/" permissionMode="set">
    				<server name="REST-preview" type="http" port="{$rest-port}" db="!{$db-name}">
    					<authentication>digest</authentication>
    					<computeContentLength>true</computeContentLength>
    					<debugAllow>false</debugAllow>
    					<profileAllow>true</profileAllow>
    					<urlRewriter>restRewrite.xqy</urlRewriter>
    					<errorHandler></errorHandler>
    					<threads>32</threads>
    				</server>
    				<server name="preview" type="http" port="{$preview-port}" db="!{$db-name}">
    					<authentication>application-level</authentication>
    					<computeContentLength>true</computeContentLength>
    					<debugAllow>false</debugAllow>
    					<profileAllow>true</profileAllow>
    					<urlRewriter>rewrite.xqy</urlRewriter>
    					<defaultUser>auth</defaultUser>
    					<errorHandler></errorHandler>
    				</server>
    				<server name="published" type="http" port="{$publish-port}" db="!{$db-name}">
    					<authentication>application-level</authentication>
    					<computeContentLength>true</computeContentLength>
    					<debugAllow>false</debugAllow>
    					<profileAllow>true</profileAllow>
    					<urlRewriter>rewrite.xqy</urlRewriter>
    					<defaultUser>auth</defaultUser>
    					<errorHandler></errorHandler>
    				</server>
    			</dir>
    		</db>
    		<db dbName="!{$db-name}">
    			<server name="webdav" type="webdav" port="{$rest-port + 1}" db="!{$db-name}">
    				<authentication>digest</authentication>
    				<computeContentLength>false</computeContentLength>
    				<debugAllow>true</debugAllow>
    				<profileAllow>true</profileAllow>
    				<errorHandler/>
    			</server>
                <stemmedSearches>decompounding</stemmedSearches>
                <wordSearches>true</wordSearches>
                <collectionLexicon>true</collectionLexicon>
                <threeCharacterWordPositions>true</threeCharacterWordPositions>
                <threeCharacterSearches>true</threeCharacterSearches>
                <fastReverseSearches>false</fastReverseSearches>
                <expungeLocks>automatic</expungeLocks>
                <!-- VERSIONS -->
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="version" parentNamespace="http://lds.org/code/lds-edit/versions" attr="date"/>
                <!-- END OF VERSIONS -->

                <!-- CLEAR CACHE INDEXES -->
                <rangeElementIndex invalidValues="ignore" type="dateTime" localname="clear-cache-timestamp" namespace="http://lds.org/code/lds-edit" maintainValuePositions="false"/>
                <!-- END OF CLEAR CACHE INDEXES -->

                <!-- REPORT INDEXES-->
                <rangeElementIndex invalidValues="ignore" type="int" localname="words" namespace="http://marklogic.com/xdmp/property" maintainValuePositions="false"/>
                <!-- END OF REPORT INDEXES-->

                <!-- Translation -->
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="translation-event" parentNamespace="http://lds.org/code/lds-edit" attr="status"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-ready" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-sent" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-returned" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-approved" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-reviewed" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-not-ready" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="translation-returned" parentNamespace="http://lds.org/code/lds-edit" attr="component-id"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-removed" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-sent" parentNamespace="http://lds.org/code/lds-edit" attr="requested-return-date"/>

                <!-- Document Actions dates -->
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="last-modified" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="created" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="unpublish-date" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="publish-date" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <!-- Document Actions users -->
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="publish-date" parentNamespace="http://lds.org/code/lds-edit" attr="username"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="created" parentNamespace="http://lds.org/code/lds-edit" attr="username"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="unpublish-date" parentNamespace="http://lds.org/code/lds-edit" attr="username"/>

                <!-- Scheduled Actions -->
                <rangeElementAttrIndex invalidValues="ignore" type="date" parent="schedule-publish" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="date" parent="schedule-unpublish" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>

                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="schedule-publish" parentNamespace="http://lds.org/code/lds-edit" attr="dateTime"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="schedule-unpublish" parentNamespace="http://lds.org/code/lds-edit" attr="dateTime"/>

                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="schedule-publish" parentNamespace="http://lds.org/code/lds-edit" attr="username"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="schedule-unpublish" parentNamespace="http://lds.org/code/lds-edit" attr="username"/>

                <!-- Submission -->
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="submission" parentNamespace="http://lds.org/code/lds-edit" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="submission" parentNamespace="http://lds.org/code/lds-edit" attr="status"/>

                <!-- Document information -->
                <rangeElementAttrIndex invalidValues="ignore" type="double" parent="document" parentNamespace="http://lds.org/code/lds-edit" attr="tgp"/>
                <rangeElementAttrIndex invalidValues="ignore" type="unsignedInt" parent="document" parentNamespace="http://lds.org/code/lds-edit" attr="words"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="document" parentNamespace="http://lds.org/code/lds-edit" attr="locale"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="document" parentNamespace="http://lds.org/code/lds-edit" attr="uri"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="document" parentNamespace="http://lds.org/code/lds-edit" attr="source"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="document" parentNamespace="http://lds.org/code/lds-edit" attr="status"/>


                <!-- IP / Correlation> -->
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="correlation" parentNamespace="http://lds.org/code/lds-edit" attr="username"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="correlation" parentNamespace="http://lds.org/code/lds-edit" attr="status"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="correlation" parentNamespace="http://lds.org/code/lds-edit" attr="cor-status"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="correlation" parentNamespace="http://lds.org/code/lds-edit" attr="sent-date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="correlation" parentNamespace="http://lds.org/code/lds-edit" attr="status-date"/>

                <!-- Documents Last modified -->
                <rangeElementIndex invalidValues="ignore" type="dateTime" localname="last-modified" namespace="http://marklogic.com/xdmp/property" maintainValuePositions="false"/>

                <!-- Enrich -->
                <rangeElementIndex invalidValues="ignore" type="unsignedInt" localname="revision" namespace="http://lds.org/code/shared/lds-edit/enrich" maintainValuePositions="false"/>
                <rangeElementIndex invalidValues="ignore" type="unsignedLong" localname="hash" namespace="http://lds.org/code/shared/lds-edit/enrich" maintainValuePositions="false"/>

                <!-- Rewrite Manager -->
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="binary-title" parentNamespace="" attr="locale"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="rewriteRules" parentNamespace="" attr="locale"/>

                <!-- SEO Page scoring -->
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="score" parentNamespace="http://lds.org/code/lds-edit" attr="result"/>

                <!-- History Files -->
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="following" parentNamespace="http://lds.org/code/lds-edit/history" attr="username"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="comment" parentNamespace="http://lds.org/code/lds-edit/history" attr="username"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="comment" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="document" parentNamespace="http://lds.org/code/lds-edit/history" attr="locale"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="document" parentNamespace="http://lds.org/code/lds-edit/history" attr="title"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="document" parentNamespace="http://lds.org/code/lds-edit/history" attr="type"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="document" parentNamespace="http://lds.org/code/lds-edit/history" attr="uri"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="document" parentNamespace="http://lds.org/code/lds-edit/history" attr="status"/>
                <rangeElementAttrIndex invalidValues="ignore" type="string" parent="document" parentNamespace="http://lds.org/code/lds-edit/history" attr="id"/>
                <rangeElementAttrIndex invalidValues="ignore" type="double" parent="document" parentNamespace="http://lds.org/code/lds-edit/history" attr="tgp"/>
                <rangeElementAttrIndex invalidValues="ignore" type="unsignedInt" parent="document" parentNamespace="http://lds.org/code/lds-edit/history" attr="words"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="schedule-publish" parentNamespace="http://lds.org/code/lds-edit/history" attr="dateTime"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="schedule-unpublish" parentNamespace="http://lds.org/code/lds-edit/history" attr="dateTime"/>

                <!-- History item date attributes -->
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-ready" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-approved" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-sent" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-returned" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-reviewed" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-not-ready" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="translation-removed" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="document-created" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="document-edited" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="document-published" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="document-unpublished" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="document-removed" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="document-deleted" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="submission-submitted" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="submission-returned" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="scheduled-publish" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="scheduled-unpublish" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="scheduled-publish-removed" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="scheduled-unpublish-removed" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="page-document-created" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="page-document-published" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="page-document-unpublished" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="correlation-sent" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="correlation-incorrelation" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="correlation-approved" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="correlation-declined" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <rangeElementAttrIndex invalidValues="ignore" type="dateTime" parent="version-restore" parentNamespace="http://lds.org/code/lds-edit/history" attr="date"/>
                <!-- INDEXS -->

                <dir name="/to-translation/" clearPermissions="true">
                    <permissions roles="app" access="ri" applyToChildren="false"/>
                    <permissions roles="auth" access="riu" applyToChildren="false"/>
                    <uriPrivilege roles="app,site_admin"/>
                </dir>
                <dir name="/preview/lds-edit-services/from-translation/" clearPermissions="true">
                    <permissions roles="auth,app" access="riu" applyToChildren="false"/>
                    <uriPrivilege roles="auth,app,site_admin"/>
                </dir>
                <dir name="/preview/" permissionsMode="set">
                    <uriPrivilege roles="*_developer, *_contributor" />
                    <permissions roles="*_developer, *_contributor" access="r" applyToChildren="false"/>
                    <dir name="lds-edit-services/" permissionMode="set">
                        <uriPrivilege roles="auth, site_admin" />
                        <permissions roles="site_admin" access="riux" applyToChildren="false"/>
                        <permissions roles="auth" access="riu" applyToChildren="false" />
                        <dir name="content/" permissionsMode="set">
                            <!-- Load the sample content (if not already loaded) and setup up permissions for the application and contributor roles -->
                            <load root="/" includes="_configuration/.*" skipExisting="true"/>
                            <dir name="_configuration/" permissionMode="set" clearPermissions="false">
                                <permissions roles="site_admin" access="riux" applyToChildren="false"/>
                                <permissions roles="auth" access="riu" applyToChildren="false" />
                                <permissions roles="app" access="r" applyToChildren="false" />

                                <dir name="versions/">
                                    <permissions roles="app" access="r" applyToChildren="false" />
                                    <load root="/" includes="versions.xml" />
                                </dir>
                                <dir name="sites/">
                                    <permissions roles="site_admin" access="riux" applyToChildren="false"/>
                                    <permissions roles="auth" access="riu" applyToChildren="false" />
                                    <permissions roles="app" access="r" applyToChildren="false" />
                                    <save filename="{$site-name}.xml">
                                        <site name="{$site-name}" xmlns="http://lds.org/code/lds-edit-services">
                                            <user username="_app_{$site-name}_app" role="r"/>
                                            <user username="_app_{$site-name}_auth" role="rw"/>
                                            <creator ldsid="{$username}"/>
                                            {$contacts}
                                        </site>
                                    </save>
                                </dir>
                                <dir name="languages/">
                                    <permissions roles="auth" access="riu" applyToChildren="false"/>
                                    <permissions roles="app" access="r" applyToChildren="false" />
                                </dir>
                            </dir>
                        </dir>
                    </dir>
                    <dir name="{$site-name}/" permissionMode="set">
                        <uriPrivilege roles="app, auth" />
                        <permissions roles="app" access="r" applyToChildren="false"/>
                        <permissions roles="auth" access="riu" applyToChildren="false"/>
                        <dir name="from-translation/" clearPermissions="false">
                            <uriPrivilege roles="app, auth" />
                            <permissions roles="app" access="r" applyToChildren="true"/>
                            <permissions roles="auth" access="riu" applyToChildren="true"/>
                            <trigger env="LOCAL, DEV, TEST, PREVIEW" name="{fn:concat("_app_lds-edit-services_site-from-translation_",$site-name)}" desc="{$site-name} /from-translation trigger">
                                <event precommit="true" content="create" depth="1"/>
                                <module db="*Modules" root="/code/lds-edit-services/" path="/translation/from/trigger/from-translation.xqy"/>
                            </trigger>
                            <trigger env="LOCAL, DEV, TEST, PREVIEW" name="{fn:concat("_app_lds-edit-services_site-from-translation-update_",$site-name)}" desc="{$site-name} /from-translation trigger update">
                                <event precommit="true" content="modify" depth="1"/>
                                <module db="*Modules" root="/code/lds-edit-services/" path="/translation/from/trigger/from-translation.xqy"/>
                            </trigger>
                        </dir>
                        <dir name="content/_configuration/" permissionsMode="set">
                            <uriPrivilege roles="app, auth" />
                            <permissions roles="app" access="r" applyToChildren="true"/>
                            <permissions roles="auth" access="riu" applyToChildren="true"/>
                            <save filename="ldse-settings.xml">
                                <ldse-settings application="{$site-name}" environment="{$env}" display-name="{$display-name}" xmlns="http://lds.org/code/lds-edit">
                                    <shared-prefix>/{$site-name}</shared-prefix>
                                    <bcs-path>/opt/bc</bcs-path>
                                    <!--<cdn-path>//{if($inPreview) then "test" else "www" }.ldscdn.org</cdn-path> -->
                                    <search-domain>http://lds.org</search-domain>
                                    <cdn-path>//www.ldscdn.org</cdn-path>
                                    <modes>
                                        <mode name="preview">
                                            <port>8000</port>
                                            <port>{$preview-port}</port>
                                            <pharaoh>true</pharaoh>
                                            <front-end-host/>{(: front end host :)}
                                            <ldse-enabled>true</ldse-enabled>
                                            <database>{$db-name}</database>
                                            <root>/preview/{$site-name}/</root>
                                            <domain>preview-{$env}.lds.org</domain>
                                            <versioned>true</versioned>
                                            <warehoused>false</warehoused>
                                        </mode>
                                        <mode name="published">
                                            <port>{$publish-port}</port>
                                            <front-end-host/>{(: front end host :)}
                                            <ldse-enabled>false</ldse-enabled>
                                            <database>{$db-name}</database>
                                            <root>/published/{$site-name}/</root>
                                            <domain>preview-{$env}.lds.org</domain>
                                            <warehoused>false</warehoused>
                                        </mode>
                                    </modes>
                                    <contexts></contexts>
                                    <ckeditor>
                                        <image-upload-path></image-upload-path>
                                        <swf-upload-path></swf-upload-path>
                                    </ckeditor>
                                    <cache-clearing>
                                        <clear-logging>
                                            <clear-logging-active>true</clear-logging-active>
                                            <clear-logs-days-to-keep>30</clear-logs-days-to-keep>
                                        </clear-logging>
                                    </cache-clearing>
                                    <to-translation>
                                        <days-to-keep>120</days-to-keep>
                                        <location>/preview/{$site-name}/to-translation/</location>
                                        <send-email>
                                            <recipient>
                                                <name>{fn:data($contacts[1]/@name)}</name>
                                                <email>{fn:data($contacts[1]/@email)}</email>
                                            </recipient>
                                        </send-email>
                                    </to-translation>
                                    <from-translation>
                                        <days-to-keep>30</days-to-keep>
                                        <location>/preview/{$site-name}/from-translation/</location>
                                        <login></login>
                                    </from-translation>
                                    <root-qnames>
                                        <root namespace="">ldswebml</root>
                                        <root namespace="">teaser</root>
                                        <root namespace="">custom-page</root>
                                    </root-qnames>

                                    <admin-navigation>
                                        <remove>
                                            <!--  Ilene's remove Example -->
                                            <!-- <link id="link-Seomoz"/>  -->
                                            <!-- <link id="{link-id}"/> -->
                                            <!-- <menu id="{menu-id}"/>-->
                                            <!-- The link and menu ids can be found by browser inspection of the item to be removed -->
                                            <link id="link-{fn:replace($display-name, " ", "_")}"/>
                                            <link id="link-New_Page_From_Template" />
                                            <link id="link-Multimedia"/>
                                        </remove>
                                        <add>
                                            <!-- <link uri="/translation?lang=eng" sequence="1" title="Ilene's Test"/> -->
                                            <!-- *** ILENE's TEST to add Menu Items, with Rights. -->
                                            <!-- <link uri="/translation" sequence="1"  title="Ilene's Test" permission="ldse:view-workflow"/> -->
                                            <!-- <link uri="/rm" sequence="2"  title="Ilene2" permission="ldse:send-to-translation"/> -->
                                            <!--<link uri="{href path}" permission="{permission}" sequence="{sequence}" title="{title}"/> -->
                                            <!-- Only 'links' can be added to the Site Admin Pages menu. The sequence attribute
                                				is the only attribute not required. If used, the value must be castable as an integer,
                                				otherwise the link will default to the bottom of the list. -->
                                        </add>
                                    </admin-navigation>
                                    <contributor-roles>
                                        <role-mapping>
                                            <editor />
                                            <publisher />
                                            <admin />
                                            <super />
                                        </role-mapping>
                                        <role id="1" parent="99" validate="locale">Admin</role>
                                        <role id="2" parent="1" validate="locale,uri">Publish</role>
                                        <role id="3" parent="2" validate="locale,uri">Edit</role>
                                        <role id="99" parent="" validate="">Super</role>
                                    </contributor-roles>
                                    <binary-manager active="true">
                                        <extensions>
                                            <ext>xls</ext>
                                            <ext>xlsx</ext>
                                            <ext>xltm</ext>
                                            <ext>doc</ext>
                                            <ext>docx</ext>
                                            <ext>pps</ext>
                                            <ext>ppsx</ext>
                                            <ext>ppt</ext>
                                            <ext>ppx</ext>
                                            <ext>xltx</ext>
                                            <ext>pdf</ext>
                                            <ext>bmp</ext>
                                            <ext>gif</ext>
                                            <ext>jpg</ext>
                                            <ext>jpeg</ext>
                                            <ext>png</ext>
                                            <ext>tif</ext>
                                        </extensions>
                                    </binary-manager>
                                    <image-crop-settings>
                                        <aspect-ratio name="Square" w="1" h="1">
                                            <size options="1024x1024" width="1024" height="1024"/>
                                            <size options="512x512" width="512" height="512"/>
                                            <size options="256x256" width="256" height="256"/>
                                            <size options="200x200" width="200" height="200"/>
                                            <size options="150x150" width="150" height="150"/>
                                        </aspect-ratio>
                                        <aspect-ratio name="Wide" w="2" h="1">
                                            <size options="512x256" width="512" height="256"/>
                                            <size options="300x150" width="300" height="150"/>
                                        </aspect-ratio>
                                        <aspect-ratio name="Extra Wide" w="2.5" h="1">
                                            <size options="476x189" width="476" height="189"/>
                                        </aspect-ratio>
                                        <service-settings environment="stage">
                                            <service>https://ws-stage.ldschurch.org/ws/imagetrans/v1.0/Services/rest/job</service>
                                            <output>https://ws-stage.ldschurch.org/ws/imagetrans/v1.0/images/output</output>
                                            <username></username>
                                            <password></password>
                                        </service-settings>
                                    </image-crop-settings>
                                    <logins>
                                        <rw-login username="_app_{$site-name}_auth"/>
                                        <ro-login username="_app_{$site-name}_app"/>
                                    </logins>
                                    <statistics>
                                        <context>/preview/{$site-name}/</context>
                                    </statistics>
                                </ldse-settings>
                            </save>
                            <save filename="file-extensions.xml">
                                <fileExtensions application="{$site-name}">
                                    <ext>css</ext>
                                    <ext>js</ext>
                                    <ext>jpg</ext>
                                    <ext>gif</ext>
                                    <ext>png</ext>
                                    <ext>mp4</ext>
                                    <ext>mp3</ext>
                                    <ext>jpeg</ext>
                                    <ext>mov</ext>
                                    <ext>xqy</ext>
                                    <ext>swf</ext>
                                    <ext>woff</ext>
                                    <ext>ttf</ext>
                                    <ext>svg</ext>
                                    <ext>eot</ext>
                                    <ext>html</ext>
                                    <ext>xml</ext>
                                    <ext>pdf</ext>
                                </fileExtensions>
                            </save>
                            <dir name="ice/" permissionsMode="set">
                                <uriPrivilege roles="app, auth" />
                                <permissions roles="app" access="r" applyToChildren="false"/>
                                <permissions roles="auth" access="riu" applyToChildren="false"/>
                                <dir name="content-contributors/" permissionsMode="set">
                                    <uriPrivilege roles="app, auth" />
                                    <permissions roles="app" access="r" applyToChildren="false"/>
                                    <permissions roles="auth" access="riu" applyToChildren="false"/>
                                    <save filename="{$username}.xml">
                                        <contributor xmlns="http://lds.org/code/lds-edit">
                                            <name display="{ac:getPersonName()}">{$username}</name>
                                            <roles>
                                                <role name="super" />
                                            </roles>
                                            <admin-who-gave-access>
                                                <username>{$username}</username>
                                            </admin-who-gave-access>
                                        </contributor>
                                    </save>
                                </dir>
                                <dir name="ice-forms/" permissionsMode="set">
                                    <uriPrivilege roles="app, auth" />
                                    <permissions roles="app" access="r" applyToChildren="true"/>
                                    <permissions roles="auth" access="riu" applyToChildren="true"/>
                                </dir>
                            </dir>
                            <dir name="languages/" permissionMode="set">
                                <uriPrivilege roles="app, auth" />
                                <permissions roles="app" access="r" applyToChildren="true"/>
                                <permissions roles="auth" access="riu" applyToChildren="true"/>
                                <save filename="supportedLanguages.xml">
                                    <supportedLanguages application="{$site-name}" locale="none" status="preview" site="{$site-name}">
                                        <language key="eng"/>
                                        <language key="deu"/>
                                        <language key="ita"/>
                                        <language key="spa"/>
                                        <language key="kor"/>
                                        <language key="jpn"/>
                                        <language key="por"/>
                                        <language key="rus"/>
                                        <language key="zho"/>
                                        <language key="fra"/>
                                    </supportedLanguages>
                                </save>
                            </dir>
                        </dir>
                    </dir>
                </dir>
                <dir name="/published/" permissionsMode="set">
                    <uriPrivilege roles="*_developer, *_contributor" />
                    <permissions roles="*_developer, *_contributor" access="r" applyToChildren="false"/>
                    <dir name="lds-edit-services/" permissionMode="set">
                        <uriPrivilege roles="auth, site_admin" />
                        <permissions roles="site_admin" access="riux" applyToChildren="false"/>
                        <permissions roles="auth" access="riu" applyToChildren="false" />
                        <dir name="content/" permissionsMode="set">
                        </dir>
                    </dir>
                    <dir name="{$site-name}/" permissionMode="set">
                        <uriPrivilege roles="app, auth" />
                        <permissions roles="app" access="r" applyToChildren="true"/>
                        <permissions roles="auth" access="riu" applyToChildren="true"/>
                        <dir name="content/" permissionsMode="set">
                            <uriPrivilege roles="app, auth" />
                            <permissions roles="app" access="r" applyToChildren="true"/>
                            <permissions roles="auth" access="riu" applyToChildren="true"/>
                        </dir>
                    </dir>
                </dir>
            </db>
        </dbs>
    </application>
};
