ad_library {
    Utility procs for working with messages in acs-mail

    @author John Prevost <jmp@arsdigita.com>
    @creation-date 2001-01-11
    @cvs-id $Id$
}

## Utility Functions ###################################################

ad_proc -private acs_mail_set_content {
    {-object_id:required}
    {-content:required}
    {-content_type:required}
    {-nls_language}
    {-searchable_p}
} {
    Set the acs_contents info for an object.  Utility function.
} {
    if ![info exists nls_language] {
        set nls_language [db_null]
    }
    if ![info exists searchable_p] {
        set searchable_p "f"
    }
    # There are two possibilities: There's an entry in acs_contents or
    # there's not.  In any case, we're replacing.  We can delete, then set.
    db_dml delete_old_content {
        delete from acs_contents where content_id = :object_id
    }
    db_dml insert_new_content {
        insert into acs_contents
            (content_id, content, searchable_p, nls_language, mime_type)
        values
            (:object_id,empty_blob(),:searchable_p,:nls_language,:content_type)
    }
    db_dml update_content {
        update acs_contents
            set content = empty_blob()
            where content_id = :object_id
            returning content into :1
    } -blobs [list $content]
}

ad_proc -private acs_mail_set_content_file {
    {-object_id:required}
    {-content_file:required}
    {-content_type:required}
    {-nls_language}
    {-searchable_p}
} {
    Set the acs_contents info for an object.  Utility function.
} {
    if ![info exists nls_language] {
        set nls_language [db_null]
    }
    if ![info exists searchable_p] {
        set searchable_p "t"
    }
    # There are two possibilities: There's an entry in acs_contents or
    # there's not.  In any case, we're replacing.  We can delete, then set.
    db_dml delete_old_content {
        delete from acs_contents where content_id = :object_id
    }
    db_dml insert_new_content {
        insert into acs_contents
            (content_id, content, searchable_p, nls_language, mime_type)
        values
            (:object_id,empty_blob(),:searchable_p,:nls_language,:content_type)
    }
    db_dml update_content {
        update acs_contents
            set content = empty_blob()
            where content_id = :object_id
            returning content into :1
    } -blob_files [list $content_file]
}

ad_proc -private acs_mail_encode_content {
    content_object_id
} {
    ns_log "Notice" "acs-mail: encode: starting $content_object_id"
    # What sort of content do we have?
    if ![acs_mail_multipart_p $content_object_id] {
	ns_log "Notice" "acs-mail: encode: one part $content_object_id"
        # Easy as pie.
        # Let's get the data.
        if [db_0or1row acs_mail_body_to_mime_get_content_simple {
            select content, mime_type as v_content_type
                from acs_contents
                where content_id = :content_object_id
        }] {
	    ns_log "Notice" "acs-mail: encode: one part hit $content_object_id"
            # We win!  Hopefully.  Check if there are 8bit characters/data.
            # HT NL CR SP-~  The full range of ASCII with spaces but no
            # control characters.
            if ![regexp "\[^\u0009\u000A\u000D\u0020-\u007E\]" $content] {
		ns_log "Notice" "acs-mail: encode: good code $content_object_id"
                # We're still okay.  Use it!
                return [list $v_content_type $content]
            }
	    ns_log "Notice" "acs-mail: encode: bad code $content_object_id"
        }
    } else {
        # Harder.  Oops.
	ns_log "Notice" "acs-mail: encode: multipart $content_object_id"
        set boundary "=-=-="
        set contents {}
        # Get the component pieces
        db_foreach acs_mail_body_to_mime_get_contents {
            select mime_filename, mime_disposition, content_object_id as coid
                from acs_mail_multipart_parts
                where multipart_id = :content_object_id
            order by sequence_number
        } {
            if {[string equal "" $mime_disposition]} {
                if {![string equal "" $mime_filename]} {
                    set mime_disposition "attachment; filename=$mime_filename"
                } else {
                    set mime_disposition "inline"
                }
            } else {
                if {![string equal "" $mime_filename]} {
                    set mime_disposition \
                        "$mime_disposition; filename=$mime_filename"
                }
            }
            set content [acs_mail_encode_content $coid]
            while {[regexp -- "--$boundary--" $content]} {
                set boundary "=$boundary"
            }
            lappend contents [list $mime_disposition $content]
        } if_no_rows {
            # Defaults
            return {
                "text/plain; charset=us-ascii"
                "An ACS object was unable to be encoded here.\n"
            }
        }
        set content_type \
            "multipart/[acs_mail_multipart_type $content_object_id]; boundary=\"$boundary\""
        set content ""
        foreach {cont} $contents {
	    set c_disp [lindex $cont 0]
            set c_type [lindex [lindex $cont 1] 0]
            set c_cont [lindex [lindex $cont 1] 1]
            append content "--$boundary\n"
            append content "Content-Type: $c_type\n"
            append content "Content-Disposition: $c_disp\n"
            append content "\n"
            append content $c_cont
	    append content "\n\n"
        }
        append content "--$boundary--\n"
        return [list $content_type $content]
    }

    # Defaults
    return {
        "text/plain; charset=us-ascii"
        "An ACS object was unable to be encoded here.\n"
    }
}

ad_proc -private acs_mail_body_to_output_format {
    {-body_id ""}
    {-link_id ""}
} {
    This will return the given mail body (or the mail body associated with the
    given link) as a properly MIME formatted message.

    Actually, the result will be in the form:

    [list $to $from $subject $body $extraheaders]

    so the info can easily be handed to ns_sendmail (for now.)
} {
    if [string equal $body_id ""] {
        db_1row acs_mail_body_to_mime_get_body {
            select body_id from acs_mail_links where mail_link_id = :link_id
        }
    }   
    db_1row acs_mail_body_to_mime_data {
        select header_message_id, header_reply_to, header_subject,
               header_from, header_to, content_object_id
            from acs_mail_bodies
            where body_id = :body_id
    }
    set headers [ns_set new]
    ns_set put $headers "Message-Id" $header_message_id
    if ![string equal $header_to ""] {
        ns_set put $headers "To" $header_to
    }
    if ![string equal $header_from ""] {
        ns_set put $headers "From" $header_from
    }
    if ![string equal $header_reply_to ""] {
        ns_set put $headers "In-Reply-To" $header_reply_to
    }
    ns_set put $headers "MIME-Version" "1.0"
    set contents [acs_mail_encode_content $content_object_id]
    set content_type [lindex $contents 0]
    set content [lindex $contents 1]
    ns_set put $headers "Content-Type" "$content_type"
    ns_set put $headers "Content-Encoding" "7bit"

    db_foreach acs_mail_body_to_mime_headers {
        select header_name, header_content from acs_mail_body_headers
            where body_id = :body_id
    } {
        ns_set put $headers $header_name $header_content
    }

    return [list $header_to $header_from $header_subject $content $headers]
}

ad_proc -private acs_mail_process_queue {
} {
    Process the outgoing message queue.
} {
    db_foreach acs_message_send {
        select message_id, envelope_from, envelope_to
            from acs_mail_queue_outgoing
    } {
        set to_send [acs_mail_body_to_output_format -link_id $message_id]
	set to_send_2 [list $envelope_to $envelope_from [lindex $to_send 2] [lindex $to_send 3] [lindex $to_send 4]]

        if [catch {
            eval ns_sendmail $to_send_2
        } errMsg] {
            ns_log "Notice" "acs-mail-queue: failure: $errMsg"
        } else {
            db_dml acs_message_delete_sent {
                delete from acs_mail_queue_outgoing
                    where message_id = :message_id
                        and envelope_from = :envelope_from
                        and envelope_to = :envelope_to
            }
        }
    }
    ns_log "Notice" "acs-mail-queue: cleaning up"
    # All done.  Delete dangling links.
    db_dml acs_message_cleanup_queue {
        delete from acs_mail_queue_messages
            where message_id not in
                    (select message_id from acs_mail_queue_outgoing)
                and message_id not in
                    (select message_id from acs_mail_queue_incoming)
    }
    ns_log "Notice" "acs-mail-queue: done cleaning up"
}

## Basic API ###########################################################

  ## acs_mail_content

ad_proc -public acs_mail_content_new {
    {-object_id ""}
    {-creation_user ""}
    {-creation_ip ""}
    {-content}
    {-content_file}
    {-content_type ""}
} {
    Create a new content object (to contain text/plain, or text/html,
    for example.)  If content is given, its text is used to make a
    content entry.  Otherwise, if content_file is given, that file is
    read to make a content entry.

    If there's a more specific way to make the object you want, best to
    use it.  This is for types of files that have no object types of their
    own.
} {
    set object_id [db_exec_plsql acs_mail_content_new {
        begin
            :1 := acs_mail_gc_object.new (
                gc_object_id => :object_id,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
        end;
    }]
    if [info exists content] {
        acs_mail_set_content \
            -object_id $object_id -content $content -content_type $content_type
    } elseif [info exists content_file] {
        acs_mail_set_content_file -object_id $object_id \
            -content_file $content_file -content_type $content_type
    }
    return $object_id
}

  ## acs_mail_body

ad_proc -public acs_mail_body_new {
    {-body_id ""}
    {-body_reply_to ""}
    {-body_from ""}
    {-body_date ""}
    {-header_message_id ""}
    {-header_reply_to ""}
    {-header_subject ""}
    {-header_from ""}
    {-header_to ""}
    {-content_object_id ""}
    {-creation_user ""}
    {-creation_ip ""}
    {-content}
    {-content_file}
    {-content_type ""}
} {
    Create a new mail body object from whole cloth.
    If content or content_file is supplied, a content object will
    automatically be created and set as the content object for the new body.
} {
    if {[info exists content]} {
        set content_object_id \
            [acs_mail_content_new \
                 -creation_user $creation_user -creation_ip $creation_ip \
                 -content $content -content_type $content_type]
    } elseif {[info exists content_file]} {
        set content_object_id \
            [acs_mail_content_new \
                 -creation_user $creation_user -creation_ip $creation_ip \
                 -content_file $content_file -content_type $content_type]
    }
    return [db_exec_plsql acs_mail_body_new {
        begin
            :1 := acs_mail_body.new (
                body_id => :body_id,
                body_reply_to => :body_reply_to,
                body_from => :body_from,
                body_date => :body_date,
                header_message_id => :header_message_id,
                header_reply_to => :header_reply_to,
                header_subject => :header_subject,
                header_from => :header_from,
                header_to => :header_to,
                content_object_id => :content_object_id,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
        end;
    }]
}

ad_proc -public acs_mail_body_p {
    {object_id}
} {
    Returns 1 if the argument is an ID for a valid acs_mail_body object.
} {
    return [string equal "t" [db_exec_plsql acs_mail_body_p {
        begin
            :1 := acs_mail_body.body_p (:object_id);
        end;
    }]]
}

ad_page_contract_filter acs_mail_body_id { name value } {
    Checks whether the value (assumed to be an integer) is the id
    of an already-existing acs_mail_body
} {
    # empty is okay (handled by notnull)
    if [empty_string_p $value] {
        return 1
    }
    if ![acs_mail_body_p $value] {
        ad_complain "$name does not refer to a valid ACS Mail body"
        return 0
    }
    return 1
}

ad_proc -public acs_mail_body_clone {
    {-old_body_id:required}
    {-body_id ""}
    {-creation_user ""}
    {-creation_ip ""}
} {
    Clone a mail body.  This is a very appropriate thing to do if you're
    going to make changes.  If you want changes to be shared between
    systems that share the message, change in place.  If you don't want
    them to be shared, clone first.
} {
    return [db_exec_plsql acs_mail_body_clone {
        begin
            :1 := acs_mail_body.clone (
                old_body_id => :old_body_id,
                body_id => :body_id,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
        end;
    }]
}

ad_proc -public acs_mail_body_set_content_object {
    {-body_id:required}
    {-content_object_id:required}
} {
    Sets the content object of the given mail body.
} {
    db_exec_plsql acs_mail_body_set_content_object {
        begin
            :1 := acs_mail_body.set_content_object (
                body_id => :body_id,
                content_object_id => :content_object_id
            );
        end;
    }
}

  ## acs_mail_multipart

ad_proc -public acs_mail_multipart_new {
    {-multipart_id ""}
    {-multipart_kind:required}
    {-creation_user ""}
    {-creation_ip ""}
} {
    Create a new MIME multipart object.  The kind of multipart is required.
    The kinds of multiparts I currently know about are:

    mixed: attachments of various content_types which can either be inline
           or presented as files to save.

    alternative: multiple versions of one document, from which the best
           should be chosen.  This is how text + html mail is sent.

    signed: the first sub-part is a document.  The second is a digital
           signature in some format.
} {
    return [db_exec_plsql acs_mail_multipart_new {
        begin
            :1 := acs_mail_multipart.new (
                multipart_id => :multipart_id,
                multipart_kind => :multipart_kind,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
        end;
    }]
}

ad_proc -public acs_mail_multipart_type {
    {object_id}
} {
    Returns the subtype of the multipart.
} {
    db_1row acs_mail_multipart_type {
	select multipart_kind from acs_mail_multiparts
	    where multipart_id = :object_id
    }
    return $multipart_kind;
}

ad_proc -public acs_mail_multipart_p {
    {object_id}
} {
    Returns 1 if the argument is an ID for a valid acs_mail_multipart object.
    Useful for determining whether a body's content is a multipart or a single
    content object.
} {
    return [string equal "t" [db_exec_plsql acs_mail_multipart_p {
        begin
            :1 := acs_mail_multipart.multipart_p (:object_id);
        end;
    }]]
}

ad_page_contract_filter acs_mail_multipart_id { name value } {
    Checks whether the value (assumed to be an integer) is the id
    of an already-existing acs_mail_multipart
} {
    # empty is okay (handled by notnull)
    if [empty_string_p $value] {
        return 1
    }
    if ![acs_mail_multipart_p $value] {
      ad_complain "$name does not refer to a valid ACS Mail multipart"
      return 0
    }
    return 1
}

ad_proc -public acs_mail_multipart_add_content {
    {-multipart_id:required}
    {-content_object_id:required}
} {
    Add a new item to a given multipart object at the end.
} {
    db_exec_plsql acs_mail_multipart_add_content {
        begin
            acs_mail_multipart.add_content (
                multipart_id => :multipart_id,
                content_object_id => :content_object_id
            );
        end;
    }
}

  ## acs_mail_link

ad_proc -public acs_mail_link_new {
    {-mail_link_id ""}
    {-body_id}
    {-creation_user ""}
    {-creation_ip ""}
    {-context_id ""}
    {-content}
    {-content_object_id}
    {-content_file}
    {-content_type ""}
} {
    Create a new mail link object.  Strictly speaking, applications should
    subclass acs_mail_link and use their own types.  This is provided as
    a tool for prototyping.
} {
    if {[info exists body_id]} {
        # use it
    } elseif {[info exists content]} {
        set body_id [acs_mail_body_new -creation_user $creation_user \
                         -creation_ip $creation_ip -content $content \
                         -content_type $content_type]
    } elseif {[info exists content_file]} {
        set body_id [acs_mail_body_new -creation_user $creation_user \
                         -creation_ip $creation_ip -content_file $content \
                         -content_type $content_type]
    } elseif {[info exists content_object_id]} {
        set body_id [acs_mail_body_new -creation_user $creation_user \
                         -creation_ip $creation_ip \
			 -content_object_id $content_object_id]
    } else {
        # Uh oh...  Use a blank one, I guess.  Not so good.
        set body_id [acs_mail_body_new -creation_user $creation_user \
                         -creation_ip $creation_ip]
    }
    return [db_exec_plsql acs_mail_link_new {
        begin
            :1 := acs_mail_link.new (
                mail_link_id => :mail_link_id,
                body_id => :body_id,
                context_id => :context_id,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
        end;
    }]
}

ad_proc -public acs_mail_link_get_body_id {
    {link_id}
} {
    Returns the object_id of the acs_mail_body for this mail link.
} {
    return [db_string acs_mail_link_get_body_id {
	select body_id from acs_mail_links where mail_link_id = :link_id
    }]
}

ad_proc -public acs_mail_link_p {
    {object_id}
} {
    Returns 1 if the argument is an ID for a valid acs_mail_link object.
} {
    return [string equal "t" [db_exec_plsql acs_mail_link_p {
        begin
            :1 := acs_mail_link.link_p (:object_id);
        end;
    }]]
}

ad_page_contract_filter acs_mail_link_id { name value } {
    Checks whether the value (assumed to be an integer) is the id
    of an already-existing acs_mail_link
} {
    # empty is okay (handled by notnull)
    if [empty_string_p $value] {
        return 1
    }
    if ![acs_mail_link_p $value] {
      ad_complain "$name does not refer to a valid ACS Mail link"
      return 0
    }
    return 1
}

