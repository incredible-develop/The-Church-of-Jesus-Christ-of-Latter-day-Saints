xquery version "1.0-ml";

module namespace email = "http://lds.org/code/shared/lds-edit/email";
declare namespace ldses = "http://lds.org/code/lds-edit-services";
declare option xdmp:mapping "true";
(:Sends mail to multiple people using elements to take advatage of function mapping:)
declare function sendMail($subject as xs:string, $content as item()*, $contentType as xs:string,
                            $from as element(), $to as element()) as empty-sequence() {
     sendMail($subject, $content, $contentType, $from/@name, $from/@email,
                            $to/@name, $to/@email)
};
declare function sendMail($subject as xs:string, $content as item()*, $contentType as xs:string,
                            $fromName as xs:string, $fromAddress as xs:string, 
                            $toName   as xs:string,   $toAddress as xs:string) as empty-sequence() {
    xdmp:email(
        <em:Message xmlns:em="URN:ietf:params:email-xml:" xmlns:rf="URN:ietf:params:rfc822:">
          <rf:subject>{$subject}</rf:subject>
          <rf:from>
            <em:Address>3
              <em:name>{$fromName}</em:name>
              <em:adrs>{$fromAddress}</em:adrs>
            </em:Address>
          </rf:from>
          <rf:to>
            <em:Address>
              <em:name>{$toName}</em:name>
              <em:adrs>{$toAddress}</em:adrs>
            </em:Address>
          </rf:to>
          <rf:content-type>{$contentType}</rf:content-type>
          <em:content>             
              {$content}
          </em:content>
        </em:Message>
   )
};