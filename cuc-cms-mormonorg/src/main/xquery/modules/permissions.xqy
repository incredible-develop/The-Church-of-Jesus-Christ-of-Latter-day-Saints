xquery version "1.0-ml";

module namespace permissions = "http://lds.org/code/shared/lds-edit/permissions";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "ldse-settings.xqy";


declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare variable $PERMISSIONS as element(ldse:permissions) :=
    <permissions xmlns="http://lds.org/code/lds-edit">
        {$settings:additional-permissions}
        <!-- Actions -->
            <permission name="ldse:publish-all-bundles"></permission>
            <permission name="ldse:publish-bundles"></permission>
            <permission name="ldse:edit-doc"></permission>
            <permission name="ldse:add-doc"></permission>
            <permission name="ldse:publish-doc>"></permission>
            <permission name="ldse:unpublish-doc"></permission>
            <permission name="ldse:remove-doc"></permission>
            <permission name="ldse:delete-doc"></permission>
            <permission name="ldse:edit-teaser-sequence"></permission>
            <permission name="ldse:teaser-search"></permission>
            <permission name="ldse:edit-navigation"></permission>
            <permission name="ldse:publish-navigation"></permission>
            <permission name="ldse:publish-jericho"></permission>
            <permission name="ldse:teaser-manager"></permission>
            <permission name="ldse:validate-forms"></permission>
            <permission name="ldse:clear-server-field"></permission>
            <permission name="ldse:edit-supported-language"></permission>
            <permission name="ldse:sync-meta"></permission>
            <permission name="ldse:publish-meta"></permission>
            <permission name="ldse:change-uri"></permission>
            <permission name="ldse:edit-rewrite-rules"></permission>
            <permission name="ldse:edit-redirect-rules"></permission>
        <!-- End Actions -->
        <!-- Views -->
            <permission name="ldse:view-page-editor"></permission>
            <permission name="ldse:view-xml"></permission>
            <permission name="ldse:cloning"></permission>
            <permission name="ldse:view-rice-admin"></permission>
            <permission name="ldse:view-lds-edit-home"></permission>
            <permission name="ldse:view-rice-admin"></permission>
            <permission name="ldse:view-binary-manager"></permission>
            <permission name="ldse:view-reports-admin"></permission>
            <permission name="ldse:view-omniture-admin"></permission>
            <permission name="ldse:view-pages-admin"></permission>
            <permission name="ldse:view-clear-cache-admin"></permission>
            <permission name="ldse:view-stats-admin"></permission>
            <permission name="ldse:view-rewrite-manager"></permission>
            <permission name="ldse:view-redirect-manager"></permission>
            <!-- Clear Cache -->
                <permission name="ldse:view-clear-cache"></permission>
                <permission name="ldse:submit-clear-cache"></permission>
            <!-- End Clear Cache -->
            <permission name="ldse:view-content-admin"></permission>
            <permission name="ldse:view-pages-admin"></permission>
            <permission name="ldse:view-omniture-admin"></permission>

            <permission name="ldse:view-page-settings"></permission>
        <!-- End Views -->
        <!-- Translation Permissions -->
            <permission name="ldse:view-translation"></permission>
            <!-- Ready -->
                <permission name="ldse:view-translation-ready"></permission>
                <permission name="ldse:remove-translation-ready"></permission>
                <permission name="ldse:send-to-translation"></permission>
            <!-- In -->
                <permission name="ldse:view-translation-in"></permission>
                <permission name="ldse:translation-remove-approval"></permission>
            <!-- Returned -->
                <permission name="ldse:view-translation-returned"></permission>
                <permission name="ldse:translation-not-ready"></permission>
                <permission name="ldse:translation-remove-returned"></permission>
            <!-- Not Ready -->
                <permission name="ldse:view-translation-not-ready"></permission>
                <permission name="ldse:translation-fix-not-ready"></permission>
            <!-- Manage -->
                <permission name="ldse:view-translation-mangage"></permission>
            <!-- Published -->
                <permission name="ldse:view-translation-publish"></permission>
            <!-- Archives -->
                <permission name="ldse:view-translation-archive"></permission>
                <permission name="ldse:edit-translation-archive"></permission>
            <!-- expanded permissions -->
                <permission name="ldse:translation-approve"></permission>
                <permission name="ldse:view-translation-approved"></permission>
                <permission name="ldse:translation-remove-approval"></permission>
                <permission name="ldse:view-translation-reviewed"></permission>
                <permission name="ldse:translation-needs-reviewed"></permission>
                <permission name="ldse:view-translation-removed"></permission>
                <permission name="ldse:translation-unremove"></permission>

                <permission name="ldse:translation-checkbox"></permission>
        <!-- End Translation Permissions -->
        <!-- String-Manager Functions-->
                        <permission name="ldse:string-manager-import-export"></permission>
                        <permission name="ldse:string-manager-add-bundle"></permission>
                        <permission name="ldse:string-manager-export-english"></permission>
                        <permission name="ldse:string-manager-add-string"></permission>
        <!--End String Manager Functions -->
        <!-- Add Gear -->
            <permission name="ldse:add-poll"></permission>
            <permission name="ldse:source-button"></permission>
            <permission name="ldse:change-template"></permission>
            <permission name="ldse:clone-page"></permission>
            <permission name="ldse:edit-hidden-resources"></permission>
            <permission name="ldse:add-new-page"></permission>
            <permission name="ldse:toggle-carousel"></permission>
            <permission name="ldse:view-omniture-page"></permission>
            <permission name="ldse:view-seomoz-page"></permission>
        <!-- End Add Gear -->


        <!-- Rice -->
            <permission name="ldse:edit-rice"></permission>
            <permission name="ldse:edit-rice-contentEditor"></permission>
        <!-- End Rice -->

        <!-- Cor-IP / Cor-Eval -->
            <permission name="ldse:correlation-send"></permission>
            <permission name="ldse:correlation-prepublisher"></permission>
			<permission name="ldse:view-correlation"></permission>
			<permission name="ldse:correlation-always-add-element"></permission>
			<permission name="ldse:correlation-always-remove-element"></permission>
			<permission name="ldse:correlation-no-new-content-button"></permission>
        <!-- End Cor-IP / Cor-Eval -->

        <!-- Submission Permissions -->
            <permission name="ldse:edit-submission"></permission>
            <permission name="ldse:edit-any-submission"></permission>
            <permission name="ldse:add-submission"></permission>
            <permission name="ldse:delete-submission"></permission>
            <permission name="ldse:delete-any-submission"></permission>
            <permission name="ldse:view-submission"></permission>
            <permission name="ldse:view-any-submission"></permission>
            <permission name="ldse:submit-submission"></permission>
            <permission name="ldse:view-all-content-manager-statuses"></permission>
            <permission name="ldse:return-submission"></permission>
        <!-- End Submission Permissions -->

        <!-- Versions -->
        	<permission name="ldse:versions-restore-complete"></permission>
        	<permission name="ldse:versions-restore-line-item"></permission>
        	<permission name="ldse:versions-save-as-current"></permission>
        <!-- End Versions -->
    </permissions>;


























