var MIU = {
    form: {},

    init: function() {
        MIU.form = $('#ice-dialog form.ixf-form');

        $(document).bind('drop dragover', function (e) {
            e.preventDefault();
        });

        // Setup the drag and drop upload
        MIU.form.fileupload({
            url: $('#ice-dialog form.ixf-form').attr('action'),
            sequentialUploads: true,
            dropZone: $('#filedrag')
        });
        MIU.form.bind('fileuploadadd', MIU.add);
        MIU.form.bind('fileuploaddone', MIU.done);

        // Do an AJAX submit to the save page
        MIU.form.append('<input type="hidden" name="ajax" value="true"/>');

        // Bind to the upload images
        $('li.miu-done').live('click', function() {
            MIU.form.find('input[name="id"]').val($(this).data('id'));
            MIU.form.find('input[name^="title"]').val($(this).data('title'));
            MIU.form.find('input[name="action"]').val('edit');
            MIU.form.find('input[name="' + ICE.formVars['image-path-node'] + '"]').val($(this).data('path'));
            $('li.miu-done').removeClass('miu-active');
            $(this).addClass('miu-active');
        });

        MIU.form.ajaxForm({dataType: 'json'});
    },

    // Runs when files are dropped
    add: function (e, data) {
        MIU.form.find('input[name="action"]').val('add');
        MIU.form.find('input[name="id"]').val('');
        MIU.form.find('input[name="' + ICE.formVars['image-path-node'] + '"]').val('');
        $.each(data.files, MIU.parseFile);
        $('li.miu-done').removeClass('miu-active');
    },

    // Runs after files are uploaded
    done: function (e, data) {
        $.each(data.files, function(index, file) {
            setTimeout(function() { MIU.setDone(file, data.jqXHR.responseText); }, 500);
        });
    },

    parseFile: function (index, file) {
        if (file.type.indexOf("image") == 0) {
            var reader = new FileReader();
            reader.onload = function(e) {
                $('#fileinfo > ul').append(
                    '<li id="' + encodeURI(file.name).replace(/[\]\[<>{}\\();:%\+\.@.]/g, '-') + '" class="miu-ready"><img src="' + e.target.result + '"/><div>' + file.name + '</div></li>'
                );
            };
            reader.readAsDataURL(file);
        }
    },

    setDone: function (file, responseText) {
        var _r = $.parseJSON(responseText);
        var _i = $('#' + encodeURI(file.name).replace(/[\]\[<>{}\\();:%\+\.@.]/g, '-'));
        _i.removeClass('miu-ready').addClass('miu-done');
        _i.data('id', _r.id);
        _i.data('title', _r.title);
        _i.data('path', _r[ICE.formVars['image-path-node']]);
    }
};

if (window.File && window.FileList && window.FileReader) {
    setTimeout(MIU.init(), 500);
}
