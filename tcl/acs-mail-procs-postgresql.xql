<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs_mail_set_content.insert_new_content">      
      <querytext>
      FIX ME LOB

        insert into acs_contents
            (content_id, content, searchable_p, nls_language, mime_type)
        values
            (:object_id,empty_blob(),:searchable_p,:nls_language,:content_type)
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_set_content.update_content">      
      <querytext>
      FIX ME LOB

        update acs_contents
            set content = empty_blob()
            where content_id = :object_id
            returning content into :1
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_set_content.insert_new_content">      
      <querytext>
      FIX ME LOB

        insert into acs_contents
            (content_id, content, searchable_p, nls_language, mime_type)
        values
            (:object_id,empty_blob(),:searchable_p,:nls_language,:content_type)
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_set_content.update_content">      
      <querytext>
      FIX ME LOB

        update acs_contents
            set content = empty_blob()
            where content_id = :object_id
            returning content into :1
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_content_new.acs_mail_content_new">      
      <querytext>
      FIX ME PLSQL

        begin
            :1 := acs_mail_gc_object__new (
                gc_object_id => :object_id,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_body_new.acs_mail_body_new">      
      <querytext>
--      FIX ME PLSQL

--        begin
            select acs_mail_body__new (
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
--        end;
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_body_p.acs_mail_body_p">      
      <querytext>
--      FIX ME PLSQL

--      begin
            select acs_mail_body__body_p (:object_id);
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_body_clone.acs_mail_body_clone">      
      <querytext>
--      FIX ME PLSQL
--        begin
        select acs_mail_body__clone (
                old_body_id => :old_body_id,
                body_id => :body_id,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
--        end;
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_body_set_content_object.acs_mail_body_set_content_object">      
      <querytext>
--      FIX ME PLSQL

--        begin
             select acs_mail_body__set_content_object (
                body_id => :body_id,
                content_object_id => :content_object_id
            );
--        end;
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_multipart_new.acs_mail_multipart_new">      
      <querytext>
--      FIX ME PLSQL

--        begin
            select acs_mail_multipart__new (
                multipart_id => :multipart_id,
                multipart_kind => :multipart_kind,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
--        end;
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_multipart_p.acs_mail_multipart_p">      
      <querytext>
--      FIX ME PLSQL

--        begin
            select acs_mail_multipart__multipart_p (:object_id);
--        end;
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_multipart_add_content.acs_mail_multipart_add_content">      
      <querytext>
--      FIX ME PLSQL

--        begin
            select acs_mail_multipart__add_content (
                multipart_id => :multipart_id,
                content_object_id => :content_object_id
            );
--        end;
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_link_new.acs_mail_link_new">      
      <querytext>
--      FIX ME PLSQL

--        begin
            select acs_mail_link__new (
                mail_link_id => :mail_link_id,
                body_id => :body_id,
                context_id => :context_id,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
--        end;
    
      </querytext>
</fullquery>

 
<fullquery name="acs_mail_link_p.acs_mail_link_p">      
      <querytext>
--      FIX ME PLSQL

--        begin
            select acs_mail_link__link_p (:object_id);
--        end;
    
      </querytext>
</fullquery>

 
</queryset>
