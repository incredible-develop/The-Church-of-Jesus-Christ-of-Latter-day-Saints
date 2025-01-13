function updateUserNames() {
        $(this).val($(this).val().toLowerCase());
        $('span.si').text($(this).val()+"-"); // get the current value of the input field.
        var newWidth = 200 - $('span.si').width();
        $('input.an').width(newWidth);
        $('input.dn').width(newWidth);
    }
    $(document).ready(updateUserNames);
    re = /[a-zA-Z0-9._-]+/;
    reEmail = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
    $('input.nospaces').keypress(function( e ) {
        var keyChar = String.fromCharCode(e.which);
        if(!re.test(keyChar)) {
            return false;
        }
    });
    $('input.site').bind('input', updateUserNames);
    function eMailValidator(classNames) {
        var hasError = false;
        $.each(classNames, function() {
            var label = "label." + this;
            var input = "input." + this;
            if(!reEmail.test($(input).val())) {
                $(label).addClass("error");
                hasError = true;
            }
            else {
                $(label).removeClass("error");
            }
        });
        return hasError; 
    }
    function requiredFieldValidator(classNames) {
        var hasError = false;
        $.each(classNames, function() {
            var label = "label." + this;
            var input = "input." + this;
            if($(input).val().length === 0) {
                $(label).addClass("error");
                hasError = true;
            }
            else {
                $(label).removeClass("error");
            }
        });
        return hasError; 
    }
    function addError($error) {
        errorMessage += $error + "<br/>";
    }
    function validate() {
            var site = $("input.site").val();
            window.errorMessage = "";            
            classNames = new Array("pn", "sn");
            classEmails= new Array("pe", "se");
            var hasError = eMailValidator(classEmails) || requiredFieldValidator(classNames);
            if(!re.test(site)) {
                $("label.site").addClass("error");
                hasError = true;
            }
            else if(site === "setup" || site === "rest"  ) {
                $("label.site").addClass("error");
                hasError = true;
                addError("Site name already used");
            }
            else {
                $("label.site").removeClass("error");
            }
            
            if(!re.test($("input.an").val())) {
                $("label.an").addClass("error");
                hasError = true;
            }
            else {
                $("label.an").removeClass("error");
            }
            if($("input.ap1").val() !== $("input.ap2").val()) {
                $("label.ap1").addClass("error");
                $("label.ap2").addClass("error");
                addError("Read/Write Passwords do not Match");
                hasError = true;
            }
            else if($("input.ap1").val().length === 0) {
                $("label.ap1").addClass("error");
                $("label.ap2").addClass("error");
            }
            else {
                $("label.ap1").removeClass("error");
                $("label.ap1").removeClass("error");
            }
            if($("input.dn").val().length === 0) {
                $("label.dn").addClass("error");
                hasError = true;
            }
            else {
                $("label.dn").removeClass("error");
            }
            if($("input.dp1").val() !== $("input.dp2").val()) {
                $("label.dp1").addClass("error");
                $("label.dp2").addClass("error");
                addError("Read Only Passwords do not Match");
                hasError = true;
            }
            else if($("input.dp1").val().length === 0) {
                $("label.dp1").addClass("error");
                $("label.dp2").addClass("error");
                hasError = true;
            }
            else {
                $("label.dp1").removeClass("error");
                $("label.dp2").removeClass("error");
            }
            if(hasError) {
                $("#errors").removeClass("invisible").html(errorMessage);
                return false;
            } else {
                $("#errors").addClass("invisible")
            }
    };