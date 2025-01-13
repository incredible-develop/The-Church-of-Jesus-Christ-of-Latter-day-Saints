xquery version "1.0-ml";

(:~
 : Default Batch Processing Script
 :
 : This is the default script for processing a batch of documents.  It will requires use of the batch processing library
 : and accepts the processData and uris parameter from those functions.  The documents are processed using a function
 : value defined at the initiation.
 :
 : This shows an example of how to define a function that will do the processing during batch processing (requires one
 : parameter for the URI and returns true/false based on if it processed the URI or not).
 :
 : @author Chris Cieslinski
 :
 :)
 
import module namespace over-batch = "http://lds.org/code/common/process/batch-processing-custom" at "batch-override.xqy";

(: 
    Don't want to use function mapping, and need to force this to an update transaction since the processing
    function will do an update to the database (and it is not part of the lexical analysis to determine transaction
    type).
:)
declare option xdmp:mapping "false";
declare option xdmp:update "true";    

(: Declare the variables coming in from the spawn command in the batch processing library :)
declare variable $processData as element(process-data) external;
declare variable $uris as element(over-batch:uris) external;
declare variable $processor as xdmp:function external;
declare variable $options as element(over-batch:options) external;

(: 
    Process the batch, passing in the data submitted to this task and setting the quality function used for processing.  To
    see different options for passing the function value see the API documentation on docs.marklogic.com.
:)
(: over-batch:process($processData, $uris, $processor, $options) :)
()