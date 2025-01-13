xquery version "1.0-ml";
(:Notice the functions here use the invoke method, as this is best practice (Sonar). The code in these modules is from
  Marklogic Corona, and instead of using eval as they do, invoke is used instead against the security database.
  Calling the functions directly, without invoke or eval, will not work because the user is not actually added
  to the database till the completion of the entire "transaction" from the setup page. Using invoke here allows
  a user to be "added" as soon as the invoke returns which allows for many "transactions" inside of one, which
  is essential to successful resolve dependencies in the default privileges for the read-write and read only roles.
  :)
module namespace ldsesUser = "http://lds.org/code/lds-edit-services/user";

import module namespace ldseUtil = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at  "/modules/utility-functions.xqy";
import module namespace util = "http://lds.org/code/lds-edit-services/utilFunctions" at  "/modules/common/utilFunctions.xqy";
import module namespace valid = "http://lds.org/code/shared/lds-edit/isValidFunctions" at "/ice/modules/isValidFunctions.xqy";
import module namespace document = "http://lds.org/code/shared/common/document/document-functions" at "/shared/common/document/documentFunctions.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy";
import module namespace setup = "http://lds.org/services/lds-publisher/setup-functions" at "/modules/setup-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace ldses = "http://lds.org/code/lds-edit-services";
declare option xdmp:mapping "true";

declare variable $user-settings as element()? := settingsForCurrentUser();
declare variable $site as xs:string? := $user-settings/../@name;
declare variable $context as xs:string := $util:context;
declare variable $invoke-security-db as element() := <options xmlns="xdmp:eval"><database>{ xdmp:security-database() }</database></options>;

(:Logs in the correct user, not must be logged in as lds-admin:)
declare function login($serviceSite as xs:string) as xs:boolean? {
    login($serviceSite, fn:true())
};

(:Logs in the correct user, not must be logged in as lds-admin:)
declare function login($serviceSite as xs:string, $verify-user as xs:boolean) as xs:boolean? {
    let $siteUser as xs:string := ldsesUser:lookupUserNameForSite($serviceSite)
    let $policy-cn as xs:string? := fn:lower-case(ac:getUserName())
    let $login := xdmp:login($siteUser,(), fn:false())
    let $contributor as element(ldse:contributor)? :=
        cts:search(/ldse:contributor,
            cts:and-query((
                (: We do not want the core:get-filter-query() here :)
                core:get-filter-query(),
                cts:element-value-query( xs:QName('ldse:name'), $policy-cn, ('unstemmed','case-insensitive'))
            ))
        )
    let $is-super as xs:boolean := $contributor/ldse:roles/ldse:role/@name = "super"
    let $is-contributor as xs:boolean := if ( $contributor ) then ( fn:true() ) else ( fn:false() )
    let $siteUser := fn:concat("_app_", $serviceSite, "_auth")

    let $login as xs:boolean? :=
        if( $siteUser = "" ) then (
                xdmp:logout(),
                fn:error(xs:QName("Unauthorized"),"Perhaps try a specific site (e.g. http://preview-local.lds.org/services/lds-edit/site-name/)")
        ) else (
            if ( $is-super or fn:not($verify-user) ) then (
                xdmp:login($siteUser,(), fn:false())
            ) else (
                if( $is-contributor ) then (
                     xdmp:login($siteUser,(), fn:false())
                ) else (
                    xdmp:logout(),
                    fn:error(xs:QName("Unauthorized"),"You must be a valid contributor")
                )
           )
        )

    return fn:true()
};

declare function lookupUserNameForSite($service-site as xs:string) as xs:string {
    fn:string(getSite($service-site)/ldses:user[@role="rw"]/@username)
};
declare function getSite($serviceSite as xs:string) as element()*{
        cts:search(/ldses:site,
            cts:and-query((
                cts:directory-query($context, 'infinity'),
                cts:element-attribute-value-query(xs:QName('ldses:site'), xs:QName('name'), $serviceSite, ('exact'))
            ))
        )[1]
};
declare function getContacts($serviceSite as xs:string) as element()*{
    getSite($serviceSite)/ldses:contact
};
(:Looks up the REST Url on a config file:)
declare function getRESTURL() as xs:string{
    getSite("lds-edit-services")/ldses:rest/@url
};
declare function lookupReadOnlyUserNameForSite($service-site as xs:string) as xs:string {
    fn:string(getSite($service-site)/ldses:user[@role="r"]/@username)
};
(:Will error if the username passed in already exists:)
declare function errorIfUsernameExists($user as xs:string) as empty-sequence(){
(:    let $exists as xs:boolean := xdmp:invoke('userExists.xqy', ( xs:QName("user"), $user ), $invoke-security-db)
    return (
        if ( $exists ) then (
            fn:error(xs:QName("ERROR"), "Site has already been created")
        ) else ()
    ):)
    ()
};
(:Will error if the logged in user does not have appropriate rights:)
declare function hasAppropriateAccess($method as xs:string) as empty-sequence(){
    let $isReadWrite as xs:boolean :=  fn:exists(
        for $perm as element(sec:permission) in xdmp:default-permissions()
        where fn:string($perm/sec:capability) = "update"
        return fn:true())
    let $hasAccess as xs:boolean := $isReadWrite or ($method = "GET")
    return
        if($hasAccess) then ()
       else fn:error(xs:QName("ERROR"), "You must have write access")
};
(:Retrieves the current user's site information:)
declare function settingsForCurrentUser() as element()? {
    cts:search(/ldses:site/*,
        cts:and-query((
            cts:directory-query($context, 'infinity'),
            cts:element-attribute-value-query( xs:QName('ldses:user'), xs:QName('username'), xdmp:get-current-user(), ('exact'))
        ))
    )[1]
};
(:Gets the site's settings:)
declare function getSiteSettings($site as xs:string) as element()? {
    cts:search(/*,
        cts:and-query((
            cts:directory-query($context, 'infinity'),
            cts:element-attribute-value-query( xs:QName('ldses:site'), xs:QName('name'), $site, ('exact'))
        ))
    )[1]
};
(:Will only add a role if it doesn't exists:)
declare private function addRole($role as xs:string, $description as xs:string) as item()*{
    (:this uses xdmp:evals so that  each step is completed sequentially in order:)(:
    xdmp:invoke('addRole.xqy'
        , (xs:QName("role"), $role, xs:QName("description"), $description), $invoke-security-db):)
        ()
};
(:Creates permissions if they do not exists:)
declare private function setPermissions($role as xs:string, $intendedPermissions as element(perms)) as item()*{(:
    xdmp:invoke('setPermissions.xqy',
        (xs:QName("role"), $role, xs:QName("intendedPermissions"), $intendedPermissions), $invoke-security-db):)
        ()
};
(:Returns the URI of the folder where the site is kept based on the folder name:)
declare private function getSiteFolder($newSite as xs:string) as xs:string {
    fn:concat($context, $newSite, "/")
};
declare private function getPublishedSiteFolder($newSite as xs:string) as xs:string {
    fn:concat("/published/", $newSite, "/")
};
(:Creates privileges if they do not exists:)
declare private function createPrivileges($role as xs:string, $privileges as element(privs)) as empty-sequence() {
    let $createPrivs as item()* := xdmp:invoke('createPrivileges1.xqy', (xs:QName("privileges"), $privileges), $invoke-security-db)
    return addPrivileges($role, $privileges)
};
(:Adds privileges to Roles:)
declare private function addPrivileges($role as xs:string, $privileges as element(privs)) as item()* {
    xdmp:invoke('createPrivileges2.xqy', (xs:QName("role"), $role, xs:QName("privileges"), $privileges), $invoke-security-db)
};
(:Sets up the roles for a read-only user and a read-write user, this is done
  in such a fashion that they can only create files in a certain folder,
  effectively this ensures that only these two roles can access the files in their
  site folder TODO remove privileges to amps:)
declare function setupSite(
    $readWriteRole as xs:string,
    $readWritePassword as xs:string,
    $readOnlyRole as xs:string,
    $readOnlyPassword as xs:string,
    $newSite as xs:string,
    $primaryName as xs:string,
    $primaryEmail as xs:string,
    $secondaryName as xs:string,
    $secondaryEmail as xs:string,
    $username as xs:string,
    $display-name as xs:string?,
    $env as xs:string?,
    $database as xs:string?,
    $shared-prefix as xs:string?
) as item()* {

    let $contacts as element(ldses:contact)* := ( <ldses:contact name="{$primaryName}" email="{$primaryEmail}"/>, <ldses:contact name="{$secondaryName}" email="{$secondaryEmail}"/> )
    return (
        setup:setup-app($newSite, $database, $username, 9900, $readWriteRole, $readWritePassword, $readOnlyRole, $readOnlyPassword, $contacts, $env, $display-name, $shared-prefix)
    )
(:    return (
        setupConfigFile((), (), $newSite, (), (), $contacts, $username, $display-name, $env, $database, $readWriteRole, $readWritePassword, $readOnlyRole, $readOnlyPassword)
    ):)

    (:let $verify as empty-sequence() :=
        if ( $readWriteRole = $readOnlyRole ) then (
            fn:error(xs:QName("ERROR"), "Read write Role and read only Role can't be the same")
        ) else()
    let $check-for-existing-folder as empty-sequence() := check-for-existing-folder($newSite)
    let $contacts as element(ldses:contact)* := ( <ldses:contact name="{$primaryName}" email="{$primaryEmail}"/>, <ldses:contact name="{$secondaryName}" email="{$secondaryEmail}"/> )
    let $siteFolder as xs:string := getSiteFolder($newSite)
    let $readDescription as xs:string := fn:concat("read-only role for ", $site)
    let $readWriteDescription as xs:string := fn:concat("read/write role for ", $site)
    let $readWritePermissions as element() :=
        <perms>
            <perm><role>{$readWriteRole}</role><type>read</type></perm>
            <perm><role>{$readWriteRole}</role><type>insert</type></perm>
            <perm><role>{$readWriteRole}</role><type>update</type></perm>
            <perm><role>{$readOnlyRole}</role><type>read</type></perm>
        </perms>
    let $readOnlyPermissions as element() :=
        <perms>
            <perm><role>{$readOnlyRole}</role><type>read</type></perm>
        </perms>
    let $readWritePrivileges as element() :=
        <privs>
            <priv>http://marklogic.com/xdmp/privileges/xdmp-add-response-header</priv>
            <priv>http://marklogic.com/xdmp/privileges/xdmp-value</priv>
            <priv type="uri" name="{$newSite}">{$siteFolder}</priv>
            <priv type="uri" name="{$newSite}p">{fn:replace($siteFolder,"/preview","/published")}</priv>
        </privs>
    let $readOnlyPrivileges as element() :=
        <privs>
            <priv>http://marklogic.com/xdmp/privileges/xdmp-add-response-header</priv>
        </privs>
    let $siteFolderAlreadyExisted as xs:boolean :=
        try {
            fn:empty(
                xdmp:directory-create($siteFolder,
                for $i as element() in $readWritePermissions/*
                return xdmp:permission(fn:string($i/role), fn:string($i/type)))
            )
        }
        catch ($e) {
            fn:false()
        }
    let $readRoleId as xs:unsignedLong := setupRole($readOnlyRole, $readDescription, $readOnlyPermissions, $readOnlyPrivileges)
    let $setupSite as empty-sequence() := ( addUser($readOnlyRole, $readOnlyPassword, $readOnlyRole), addUserRole(fn:concat("_app_", $newSite, "_app"), $readOnlyRole) )
    let $readWriteRoleId as xs:unsignedLong  := setupRole($readWriteRole, $readWriteDescription, $readWritePermissions, $readWritePrivileges)
    let $finishSetup as empty-sequence() :=
        (addUser($readWriteRole, $readWritePassword, $readWriteRole),
        addUserRole("_app_lds-edit-services_app", $readWriteRole),
        setupConfigFile($readOnlyRole, $readWriteRole, $newSite,
        $readRoleId, $readWriteRoleId, $contacts, $username, $display-name, $env, $database),
        add-triggers($newSite)
    )
    return ():)
};
(:Adds a user to the security database, if it doesn't already exist':)
declare function addUser($userName as xs:string, $userPassword as xs:string, $role as xs:string*) as empty-sequence(){
    let $add as item()* :=
        xdmp:invoke('createUser.xqy', (xs:QName("userName"),
            $userName,xs:QName("userPassword"), $userPassword,xs:QName("role"), $role),
            $invoke-security-db)
    return ()
};
(:Adds a user to the security database, if it doesn't already exist':)
declare function check-for-existing-folder($site-name) as empty-sequence(){
    let $modules as xs:unsignedLong := xdmp:modules-database()
    let $exists as xs:boolean :=
        ($site-name = "setup") or (:Setup is used in the rest library:)
        ($site-name = "rest") or
        (if ($modules eq 0) then ( (:Instead of looking through the file-system made a list of current
                                    shared folders instead, most deployments though it should actually scan:)
            let $folders as xs:string*:= ("binary", "clear-cache", "content", "db", "error",
                "ice","modules","omniture","pages","pharaoh","reports","resources","rest","rice",
                "settings","shared","stats","test","translation")
            return $site-name eq $folders
        ) else ( (:by invoking here:)
            xdmp:invoke('checkForExistingSharedFolder.xqy',
                (xs:QName("site-name"), $site-name),
                    <options xmlns="xdmp:eval"><database>{ $modules }</database></options>)
       ))
   return if($exists) then (
            fn:error(xs:QName("ERROR"), "Invalid site name")
        ) else (
        )
};
(:Reset's a user's password in the security database if it exists:)
declare function resetUserPassword($userName as xs:string, $userPassword as xs:string) as empty-sequence(){
        xdmp:invoke('resetUserPassword.xqy', (xs:QName("userName"),
            $userName,xs:QName("userPassword"),$userPassword),
            $invoke-security-db)
};
declare private function add-triggers($site as xs:string) as empty-sequence() {
let $trigger-name-insert as xs:string := fn:concat("_app_lds-edit-services_site-from-translation_", $site)
let $trigger-name-update as xs:string := fn:concat("_app_lds-edit-services_site-from-translation-update_", $site)
let $scope as xs:string := fn:concat("/preview/",$site,"/from-translation/")
(:let $first as item()*:=
    trgr:create-trigger($trigger-name-insert, "insert trigger",
      trgr:trigger-data-event(
          trgr:directory-scope($scope, "1"),
          trgr:document-content("create"),
          trgr:pre-commit()),
      trgr:trigger-module(xdmp:database("Modules"), "/code/lds-edit-services/", "/translation/from/trigger/from-translation.xqy"),
      fn:true(), xdmp:default-permissions() )
  let $second as item()*:=
    trgr:create-trigger($trigger-name-update, "update trigger",
      trgr:trigger-data-event(
          trgr:directory-scope($scope, "1"),
          trgr:document-content("modify"),
          trgr:pre-commit()),
      trgr:trigger-module(xdmp:database("Modules"), "/code/lds-edit-services/", "/translation/from/trigger/from-translation.xqy"),
      fn:true(), xdmp:default-permissions() ):)
  return ()
};
declare private function remove-triggers($site as xs:string) as empty-sequence() {
    let $trigger-name-insert as xs:string := fn:concat("_app_lds-edit-services_site-from-translation_",$site)
    let $trigger-name-update as xs:string := fn:concat("_app_lds-edit-services_site-from-translation-update_",$site)
    return (trgr:remove-trigger($trigger-name-insert),
        trgr:remove-trigger($trigger-name-update)
    )
};
(:Creates a role and adds default permissions and privileges:)
declare private function setupRole($role as xs:string, $description as xs:string,
 $permissions as element(), $privileges as element()) as xs:unsignedLong {
   let $createRole as xs:unsignedLong := addRole($role, $description)
   let $createPermissions as empty-sequence() := setPermissions($role, $permissions)
   let $createPrivileges as empty-sequence() := createPrivileges($role, $privileges)
   return $createRole
};
(:Adds a role to the user:)
declare private function addUserRole($role as xs:string, $user as xs:string) as empty-sequence() {
    xdmp:invoke('addUserRole.xqy', (xs:QName("role"), $role,xs:QName("user"), $user), $invoke-security-db)
};
(:Deletes a role, and the user NOTE assumes that the role name and user name is the same:)
declare private function deleteRoleAndUser($role as xs:string) as empty-sequence() {
    xdmp:invoke('deleteUser.xqy', (xs:QName("user"), $role), $invoke-security-db),
    xdmp:invoke('deleteRole.xqy', (xs:QName("role"), $role), $invoke-security-db)
};
(:Deletes a URI Privilege:)
declare private function deleteURIPriviliege($site as xs:string) as empty-sequence() {
    xdmp:invoke('deleteSiteURIPriv.xqy', (xs:QName("site"), $site), $invoke-security-db)
};
(:Removes all config files that were created when a new site was created:)
declare function deleteConfigFiles($site as xs:string) as empty-sequence() {
    let $siteDocumentURI as xs:string := fn:concat($context, "lds-edit-services/content/_configuration/sites/", $site, ".xml" )
    let $readOnlyUser as xs:string := lookupReadOnlyUserNameForSite($site)
    let $readWriteUser as xs:string := lookupUserNameForSite($site)
    return
    (:Delete all files in preview and published directory if it exists:)
    (    xdmp:directory-delete(getSiteFolder($site)),
         xdmp:directory-delete(getPublishedSiteFolder($site)),
         document:documentDelete($siteDocumentURI),
         (:Delete the users and the roles:)
         deleteRoleAndUser($readOnlyUser),
         deleteRoleAndUser($readWriteUser),
         deleteURIPriviliege($site),
         remove-triggers($site) )
};
(:Adds an xml file to the site so the name of their site can be looked up:)
declare private function setupConfigFile(
    $readOnlyRole as xs:string?,
    $readWriteRole as xs:string?,
    $newSite as xs:string,
    $readRoleId as xs:integer?,
    $readWriteRoleId as xs:integer?,
    $contacts as element(ldses:contact)*,
    $username as xs:string,
    $display-name as xs:string?,
    $env as xs:string?,
    $database as xs:string?,
    $readWriteUser as xs:string?,
    $readWritePass as xs:string?,
    $readOnlyUser as xs:string?,
    $readOnlyPass as xs:string?
) as empty-sequence(){
()
(:    setup:setup-app($newSite, $database, $username, 1234, 1235, 1236, $readWriteUser, $readWritePass, $readOnlyUser, $readWritePass) :)
(:    let $role as element(sec:permission)* := (
        <sec:permission>
            <sec:capability>read</sec:capability>
            <sec:role-id>{$readRoleId}</sec:role-id>
        </sec:permission>,
        <sec:permission>
            <sec:capability>update</sec:capability>
            <sec:role-id>{$readWriteRoleId}</sec:role-id>
        </sec:permission>,
        <sec:permission>
            <sec:capability>read</sec:capability>
            <sec:role-id>{$readWriteRoleId}</sec:role-id>
        </sec:permission>
    )
    let $database as xs:string? := ($database, 'Delivery')[1]
    let $setup-database := setup:setup-app($newSite, $database, 1234, 1235, 1236)
(\:    let $setup-database as empty-sequence() := setup:setup-database($database):\)
    let $inPreview as xs:boolean := $context = "/preview/"
    let $sharedPrefix as xs:string := fn:concat("/services/lds-edit/", $newSite)
(\:    let $indexes := setup:setup-indexes($database):\)
    let $defaultLDSEditConfigFile as element() :=
        <ldse-settings application="{$newSite}" environment="{$env}" display-name="{$display-name}" xmlns="http://lds.org/code/lds-edit">
            <shared-prefix>{$sharedPrefix}</shared-prefix>
            <bcs-path>/opt/bc</bcs-path>
            <cdn-path>//{if($inPreview) then "test" else "www" }.ldscdn.org</cdn-path>
            <search-domain>http://lds.org</search-domain>
            <login username="{$readWriteRole}"/>
            <modes>
                <mode name="preview">
                   <port>8000</port>
                   <port>9309</port>
                   <pharaoh>true</pharaoh>
                   <front-end-host/>{(\: front end host :\)}
                   <ldse-enabled>true</ldse-enabled>
                   <database>{$database}</database>
                   <root>/preview/{$newSite}/</root>
                   <domain>preview-{$env}.lds.org</domain>
                   <versioned>true</versioned>
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
                <location>/preview/{$newSite}/to-translation/</location>
                <send-email>
                <recipient>
                    <name>{fn:data($contacts[1]/@name)}</name>
                    <email>{fn:data($contacts[1]/@email)}</email>
                </recipient>
                </send-email>
            </to-translation>
            <from-translation>
                <days-to-keep>30</days-to-keep>
                <location>/preview/{$newSite}/from-translation/</location>
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
            <image-processing active="true">
                <max-size>700</max-size>
                <create-thumb-size>100</create-thumb-size>
                <thumb-size>100</thumb-size>
                <caller-code>EducatorForSandI</caller-code>
            </image-processing>
        </binary-manager>
        <statistics>
          <context>/preview/{$newSite}/</context>
        </statistics>
    </ldse-settings>
    let $newSiteSettingsURI as xs:string := fn:concat($context, $newSite, "/content/_configuration/ldse-settings.xml")
    let $addSetupConfig as empty-sequence() := xdmp:document-insert($newSiteSettingsURI, $defaultLDSEditConfigFile, $role)
    let $configURI as xs:string := fn:concat($context, "lds-edit-services/content/_configuration/sites/", $newSite, ".xml" )
    let $siteConfig as element() :=
        <site name="{$newSite}" xmlns="http://lds.org/code/lds-edit-services">
            <user username="{$readOnlyRole}" role="r"/>
            <user username="{$readWriteRole}" role="rw"/>
            <creator ldsid="{$username}"/>
            {$contacts}
        </site> (\:These permissions allow for the users to see which site they belong to:\)
    let $rewriteConfig as element() :=
        <fileExtensions application="{$newSite}">
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
    let $iceContributorURI as xs:string := fn:concat("/preview/", $newSite, "/content/_configuration/ice/content-contributors/", $username, ".xml")
    let $rewritePassThroughConfigURI as xs:string := fn:concat($context, $newSite, "/content/_configuration/rewrite/fileExtensions.xml" )
    let $iceContributor as element() :=
        <contributor xmlns="http://lds.org/code/lds-edit">
            <name display="{ac:getPersonName()}">{$username}</name>
            <roles>
                <role name="super" />
            </roles>
            <admin-who-gave-access>
                <username>{$username}</username>
            </admin-who-gave-access>
        </contributor>
        (\:TODO Should these be configured:\)
    let $supportedLanguages as element() :=
        <supportedLanguages application="{$newSite}" locale="none" status="preview">
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
    let $supportedLanguagesURI as xs:string := fn:concat("/preview/", $newSite, "/content/_configuration/languages/supportedLanguages.xml")
    let $ldsEditSerivcesAdminRole as element(sec:permission)* := fn:insert-before($role, 1, xdmp:permission(xdmp:get-current-user(), "read"))
    let $languageMappingUri as xs:string := fn:concat($context, "lds-edit-services/content/_configuration/languages/languageMapping.xml")
    let $addLanguageMappingPermission as empty-sequence() := xdmp:document-add-permissions($languageMappingUri, $role)
    return (
        xdmp:document-insert($configURI, $siteConfig, $ldsEditSerivcesAdminRole),
        xdmp:document-insert($rewritePassThroughConfigURI, $rewriteConfig, $role),
        xdmp:document-insert($iceContributorURI, $iceContributor, $role),
        xdmp:document-insert($supportedLanguagesURI, $supportedLanguages, $role)
    ):)
};
