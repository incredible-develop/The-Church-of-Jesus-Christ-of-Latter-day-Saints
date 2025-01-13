(:
    This is a bundle for registering a site
    which will also read in the parameters as needed to a variable
:)
xquery version "1.0-ml";
module namespace create-site = "http://lds.org/code/services/lds-publisher/create-site";
import module namespace email = "http://lds.org/code/shared/lds-edit/email" at "/setup/modules/emailFunction.xqy";
import module namespace ldsesUser="http://lds.org/code/lds-edit-services/user" at "/modules/userManagement.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace common = "http://marklogic.com/lds-edit-services/common" at "/v1/modules/common.xqy";
declare namespace ldses = "http://lds.org/code/lds-edit-services";
declare option xdmp:mapping "true";

declare variable $serviceSite as xs:string? := xdmp:get-request-field("site");
declare variable $adminName as xs:string? := fn:concat($serviceSite, "-", xdmp:get-request-field("adminName"));
declare variable $adminPass as xs:string? := xdmp:get-request-field("adminPass");
declare variable $devName as xs:string? := fn:concat($serviceSite, "-", xdmp:get-request-field("devName"));
declare variable $devPass as xs:string? := xdmp:get-request-field("devPass");
declare variable $shared-prefix as xs:string? := xdmp:get-request-field("shared-prefix");
declare variable $primaryName as xs:string? := xdmp:get-request-field("primaryName");
declare variable $primaryEmail as xs:string? := xdmp:get-request-field("primaryEmail");
declare variable $secondaryName as xs:string? := xdmp:get-request-field("secondaryName");
declare variable $secondaryEmail as xs:string? := xdmp:get-request-field("secondaryEmail");
declare variable $env as xs:string? := xdmp:get-request-field("env");
declare variable $display-name as xs:string? := xdmp:get-request-field("display-name",$serviceSite);
declare variable $completePostBack as xs:boolean := detect-complete-postback();
declare variable $database as xs:string? := xdmp:get-request-field('database')[. ne ''];

(:~ 
    Checks to see if the post is complete and contains all of the information 
   ~ :)
declare function detect-complete-postback() as xs:boolean {
    fn:exists($serviceSite) and fn:exists($adminName) and fn:exists($adminPass) and fn:exists($devName) and fn:exists($devPass)
    and fn:exists($primaryName) and fn:exists($primaryEmail) and fn:exists($secondaryName) and fn:exists($secondaryEmail)
};
declare function validateForMLRoleName($role as xs:string) as empty-sequence() {
    if(fn:matches($role, "^[a-zA-Z0-9._-]+$")) then ((:role name is valid:)) 
    else (
         fn:error(xs:QName("ERROR"), "Site names and user names must be valid role names")
    )
};
(:~
    Creates a site, if the name is invalid, will return a 500 error, 
    Note that this function requires the LDS Account username of one person
    to add in as default. Their full name and email is used in ICE.
    @person-name
    @person-email
    @username
~:)
declare function register(
    $username as xs:string,
    $person-name as xs:string,
    $person-email as xs:string 
) as item()* {
    if($completePostBack) then (
        let $siteSettings as element()* := ldsesUser:getSiteSettings($serviceSite)
        return
            if(fn:exists($siteSettings)) then (
                fn:error(xs:QName("ERROR"), "Site has already been created")
            ) else (
                let $checkSiteNameAndUserName := validateForMLRoleName(($serviceSite, $adminName, $devName))
                let $checkUserNames as empty-sequence() := ldsesUser:errorIfUsernameExists(($adminName, $devName))
                return
                    let $site as xs:string := functx:capitalize-first($serviceSite)
                    let $siteReg as element()* := ldsesUser:getSite("lds-edit-services") 
                    let $subject as xs:string := fn:concat($site, " site created - LDS Edit Services")
                    let $content as xs:string := fn:concat("This message is to let you know that the ", $site, 
                       " site was created on LDS Edit Services by ", $person-name , " (",
                       $person-email,"). <br/><br/>Sincerely,<br/>LDS Edit Services Team")
                    (:let $from as element() := <contact name="LDS Edit" email="noreply@ldschurch.org"/>
                    let $to as element()* := $siteReg/ldses:contact:)
                    (: TODO deprecated let $mail as empty-sequence() :=email:sendMail($subject, $content, "text/html", $from, $to):)
                    return ldsesUser:setupSite($adminName, $adminPass, $devName, 
                        $devPass, $serviceSite, $primaryName, $primaryEmail, $secondaryName, $secondaryEmail, $username, $display-name, $env, $database, $shared-prefix)
            )
      ) else (
         fn:error(xs:QName("ERROR"), "Not all fields posted correctly")
      )
};