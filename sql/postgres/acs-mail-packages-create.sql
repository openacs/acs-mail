--
-- packages/acs-mail/sql/acs-mail-create-packages.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @creation-date 2001-01-08
-- @cvs-id $Id$
--

-- Package Implementations ---------------------------------------------

create function acs_mail_gc_object__new (integer,varchar,timestamp,integer,varchar,integer)
returns integer as '
declare
    gc_object_id  alias for $1;    -- default null
    object_type   alias for $2;    -- default 'acs_mail_gc_object'
    creation_date alias for $3;    -- default now
    creation_user alias for $4;    -- default null
    creation_ip   alias for $5;    -- default null
    context_id    alias for $6;    -- default null
    v_object_id   integer;
 begin
    v_object_id := acs_object__new (
        object_id => gc_object_id,
        object_type => object_type,
        creation_date => creation_date,
        creation_user => creation_user,
        creation_ip => creation_ip,
        context_id => context_id
    );
    insert into acs_mail_gc_objects values ( v_object_id );
    return v_object_id;
 end;
' language 'plpgsql';

procedure acs_mail_gc_object__delete (integer)
returns integer as '
declare
    gc_object_id alias for $1;
begin
     delete from acs_mail_gc_objects
         where gc_object_id = acs_mail_gc_object.delete.gc_object_id;
     acs_object__delete(gc_object_id);
    return 1;
end;
' language 'plpgsql';

-- end acs_mail_gc_object

---
-- create or replace package body acs_mail_body

-- note for docs that I am making header_message_id mandatory
-- jag

create function acs_mail_body__new (integer,integer,integer,timestamp,
varchar,varchar,text,text,text,integer,varchar,date,integer,varchar,integer)
as ' 
declare
    body_id           alias for $1;    -- default null
    body_reply_to     alias for $2;    -- default null
    body_from         alias for $3;    -- default null
    body_date         alias for $4;    -- default null
    header_message_id alias for $5;    -- default null
    header_reply_to   alias for $6;    -- default null
    header_subject    alias for $7;    -- default null
    header_from       alias for $8;    -- default null
    header_to         alias for $9;    -- default null
    content_object_id alias for $10;   -- default null
    object_type       alias for $11;   -- default 'acs_mail_body'
    creation_date     alias for $12;   -- default now()
    creation_user     alias for $13;   -- default null
    creation_ip       alias for $14;   -- default null
    context_id        alias for $15;   -- default null
    v_object_id       integer;
-- not needed anymore
--    v_header_message_id varchar;
 begin
     v_object_id := acs_mail_gc_object__new (
         gc_object_id => body_id,
         object_type => object_type,
         creation_date => creation_date,
         creation_user => creation_user,
         creation_ip => creation_ip,
         context_id => context_id
     );
-- I am making this mandatory for now
    if header_message_id is null then 
        raise exception ''You didn't supply a header_message_id'';
    end if;

--         coalesce (header_message_id,
--            now() || '.' || v_object_id || '@' ||
--                 utl_inaddr.get_host_name || '.sddd');
     insert into acs_mail_bodies
         (body_id, body_reply_to, body_from, body_date, header_message_id,
          header_reply_to, header_subject, header_from, header_to,
          content_object_id)
     values
         (v_object_id, body_reply_to, body_from, body_date,
          header_message_id, header_reply_to, header_subject, header_from,
          header_to, content_object_id);
     return v_object_id;
end;
' language 'pgplsql';

create function acs_mail_body__delete (integer) 
returns integer as ' 
declare
    body_id alias for $1;
begin
    acs_mail_gc_object__delete(body_id);
    return 1;
end;
' language 'pgpsql';

create function acs_mail_body__body_p (integer) 
returns char as '
    object_id alias for $1;
    v_check_body_id integer;
begin
     select case when (count(body_id)=0 then 0 else1) into v_check_body_id
         from acs_mail_bodies
         where body_id = object_id;
     if v_check_body_id <> 0 then
         return 't';
     else
         return 'f';
     end if;
 end;
' language 'pgplsql';

create function acs_mail_body__clone (integer,integer,varchar,timestamp,
integer,varchar,integer) 
returns integer as '
declare 
    old_body_id       alias for $1;
    body_id           alias for $2;    -- default null
    object_type       alias for $3;    -- default 'acs_mail_body'
    creation_date     alias for $4;    -- default now()
    creation_user     alias for $5;    -- default null
    creation_ip       alias for $6;    -- default null
    context_id        alias for $7;    -- default null
    v_object_id       integer;
    body_reply_to     integer;
    body_from         integer;
    body_date         timestamp;
    header_message_id varchar;
    header_reply_to   varchar;
    header_subject    text;
    header_from       text;
    header_to         text;
    content_object_id integer;
 begin
     select body_reply_to, body_from, body_date,
            header_reply_to, header_subject, header_from, header_to,
            content_object_id
         into body_reply_to, body_from, body_date,
            header_reply_to, header_subject, header_from, header_to,
            content_object_id
         from acs_mail_bodies
         where body_id = old_body_id;
     v_object_id := acs_mail_body__new (
         body_id => body_id,
         body_reply_to => body_reply_to,
         body_from => body_from,
         body_date => body_date,
         header_reply_to => header_reply_to,
         header_subject => header_subject,
         header_from => header_from,
         header_to => header_to,
         content_object_id => content_object_id,
         object_type => object_type,
         creation_date => creation_date,
         creation_user => creation_user,
         creation_ip => creation_ip,
         context_id => context_id
     );
     return v_object_id;
end;
' language 'pgplsql';

create function acs_mail_body__set_content_object (integer,integer) 
returns integer as '
declare
    body_id           alias for $1;
    content_object_id alias for $2;
begin
    update acs_mail_bodies
        set content_object_id = set_content_object.content_object_id
        where body_id = set_content_object.body_id;
    return 1;
end;
' language 'pgplsql';

----
--create or replace package body acs_mail_multipart
create function acs_mail_multipart__new (integer,varchar,varchar,
timestamp,integer,varchar,integer) 
returns integer as '
declare
    multipart_id   alias for $1;    -- default null,
    multipart_kind alias for $2;
    object_type    alias for $3;    -- default 'acs_mail_multipart'
    creation_date  alias for $4;    -- default now()
    creation_user  alias for $5;    -- default null
    creation_ip    alias for $6;    -- default null
    context_id     alias for $7;    -- default null
    v_object_id    integer;
begin
    v_object_id := acs_mail_gc_object__new (
        gc_object_id => multipart_id,
        object_type => object_type,
        creation_date => creation_date,
        creation_user => creation_user,
        creation_ip => creation_ip,
        context_id => context_id
    );
    insert into acs_mail_multiparts (multipart_id, multipart_kind)
        values (v_object_id, multipart_kind);
    return v_object_id;
end;
' language 'pgplsql';

create function acs_mail_multipart__delete (integer)
returns integer as '
declare
    multipart_id alias for $1;
begin
    acs_mail_gc_object__delete(multipart_id);
    return 1;
end;
' language 'pgplsql';

create function acs_mail_multipart__multipart_p (integer)
returns char as '
declare
    object_id alias for $1;
    v_check_multipart_id integer;
begin
    select (case when count(multipart_id) = 0 then 0 else 1 end) into v_check_multipart_id
        from acs_mail_multiparts
        where multipart_id = object_id;
    if v_check_multipart_id <> 0 then
        return 't';
    else
        return 'f';
    end if;
end;
' language 'pgplsql';

 -- Add content at a specific index.  If the sequence number is null,
 -- below one, or higher than the highest item already available,
 -- adds at the end.  Otherwise, inserts and renumbers others.

create function acs_mail_multipart__add_content (integer,integer)
returns integer as ' 
declare
    multipart_id      alias for $1;
    content_object_id alias for $2;
    v_multipart_id    integer;
    v_max_num         integer;
begin
    -- get a row lock on the multipart item
    select multipart_id into v_multipart_id from acs_mail_multiparts
        where multipart_id = add_content.multipart_id for update;
    select coalesce(max(sequence_number),0) into v_max_num
        from acs_mail_multipart_parts
        where multipart_id = add_content.multipart_id;
    insert into acs_mail_multipart_parts
        (multipart_id, sequence_number, content_object_id)
    values
         (multipart_id, v_max_num + 1, content_object_id);
end;
' language 'pgplsql';

--end acs_mail_multipart;

--create or replace package body acs_mail_link__
create function acs_mail_link__new (integer,integer,integer,timestamp,
integer,varchar,varchar)
returns integer as '
declare
    mail_link_id    alias for $1;    -- default null
    body_id         alias for $2;
    context_id      alias for $3;    -- default null
    creation_date   alias for $4;    -- default now()
    creation_user   alias for $5;    -- default null
    creation_ip     alias for $6;    -- default null
    object_type     alias for $7;    -- default 'acs_mail_link'
    v_object_id     integer;
 begin
    v_object_id := acs_object__new (
        object_id => mail_link_id,
        context_id => context_id,
        creation_date => creation_date,
        creation_user => creation_user,
        creation_ip => creation_ip,
        object_type => object_type
    );
    insert into acs_mail_links ( mail_link_id, body_id )
        values ( v_object_id, body_id );
    return v_object_id;
end;
' language 'pgplsql';

create function acs_mail_link__delete (integer)
returns integer as '
declare
    mail_link_id alias for $1;
begin
    delete from acs_mail_links
        where mail_link_id = acs_mail_link.delete.mail_link_id;
    acs_object__delete(mail_link_id);
    return 1;
end;
' language 'pgplsql';

create function acs_mail_link__link_p (integer)
returns char as '
declare
    object_id alias for $1;
    v_check_link_id integer;
begin
    select (case when count(mail_link_id) = 0 then 0 else 1) into v_check_link_id
        from acs_mail_links
        where mail_link_id = object_id;
    if v_check_link_id <> 0 then
        return 't';
    else
        return 'f';
    end if;
end; -- link_p
' language 'pgplsql';

--end acs_mail_link;

