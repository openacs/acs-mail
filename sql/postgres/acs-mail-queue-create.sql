--
-- packages/acs-mail/sql/acs-mail-queue-create.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @creation-date 2001-01-08
-- @cvs-id $Id$
--

begin
    acs_object_type__create_type (
        'acs_mail_queue_message',
        'Queued Message',
        'Queued Messages',
	'acs_mail_link',
        'ACS_MESSAGES_QUEUE_MESSAGE',
        'MESSAGE_ID',
	null,
	'f',
	null,
        'ACS_OBJECT.DEFAULT_NAME'
    );
end;
/
show errors

create table acs_mail_queue_messages (
    message_id integer
        constraint acs_mail_queue_ml_id_pk primary key
        constraint acs_mail_queue_ml_id_fk references acs_mail_links
);

create table acs_mail_queue_incoming (
    message_id integer
        constraint acs_mail_queue_in_mlid_pk primary key
        constraint acs_mail_queue_in_mlid_fk
            references acs_mail_queue_messages,
    envelope_from text,
    envelope_to text
);

create table acs_mail_queue_outgoing (
    message_id integer
        constraint acs_mail_queue_out_mlid_pk primary key
        constraint acs_mail_queue_out_mlid_fk
            references acs_mail_queue_messages,
    envelope_from text,
    envelope_to text
);

-- API -----------------------------------------------------------------
--create or replace package body acs_mail_queue_message__
create function acs_mail_queue_message__new (integer,integer,
integer,timestamp,integer,varchar,varchar)
returns integer as '
declare
    mail_link_id    alias for $1;    -- default null
    body_id         alias for $2;
    context_id      alias for $3;    -- default null
    creation_date   alias for $4;    -- default sysdate
    creation_user   alias for $5;    -- default null
    creation_ip     alias for $6;    -- default null
    object_type     alias for $7;    -- default 'acs_mail_link'
    v_object_id     integer;
 begin
    v_object_id := acs_mail_link__new (
        mail_link_id => mail_link_id,
	body_id => body_id,		      
        context_id => context_id,
        creation_date => creation_date,
        creation_user => creation_user,
        creation_ip => creation_ip,
        object_type => object_type
    );
    insert into acs_mail_queue_messages ( message_id )
        values ( v_object_id );
    return v_object_id;
end;
' language 'pgplsql';

create function acs_mail_queue_message__delete (integer)
returns integer as '
declare
    message_id alias for $1;
begin
    delete from acs_mail_queue_messages
        where message_id = acs_mail_queue_message.delete.message_id;
    acs_mail_link.delete(message_id);
    return 1;
end;
' language 'pgplsql';
-- end acs_mail_queue_message;


-- Needs:
--   Incoming:
--     A way to say "okay, I've accepted this one, go ahead and delete"
--   Outgoing:
--     A way to say "send this message to this person from this person"
--     A way to say "send this message to these people from this person"
