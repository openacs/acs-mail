--
-- packages/acs-mail/sql/postgresql/acs-mail-drop.sql
--
-- @author Vinod Kurup <vkurup@massmed.org>
-- @creation-date 2001-07-05
-- @cvs-id $Id$
--

-- FIXME: This script has NOT been tested! - vinodk

drop function acs_mail_queue_message__new (integer,integer,
	 integer,timestamp,integer,varchar,varchar);
drop function acs_mail_queue_message__delete (integer);

drop table acs_mail_queue_messages;
drop table acs_mail_queue_incoming;
drop table acs_mail_queue_outgoing;

select acs_object_type__drop_type (
	'acs_mail_queue_message',
	't'
);


drop function acs_mail_gc_object__new (integer,varchar,timestamp,integer,
	 varchar,integer);
drop function acs_mail_gc_object__delete(integer);
drop function acs_mail_body__new (integer,integer,integer,timestamp,varchar,
	 varchar,text,text,text,integer,varchar,date,integer,varchar,integer);
drop function acs_mail_body__delete(integer);
drop function acs_mail_body__body_p(integer);
drop function acs_mail_body__clone (integer,integer,varchar,timestamp,
	 integer,varchar,integer);
drop function acs_mail_body__set_content_object (integer,integer);
drop function acs_mail_multipart__new (integer,varchar,varchar,
	 timestamp,integer,varchar,integer);
drop function acs_mail_multipart__delete (integer);
drop function acs_mail_multipart__multipart_p (integer);
drop function acs_mail_multipart__add_content (integer,integer);
drop function acs_mail_link__new (integer,integer,integer,timestamp,
	 integer,varchar,varchar);
drop function acs_mail_link__delete (integer);
drop function acs_mail_link__link_p (integer);


drop index acs_mail_body_hdrs_body_id_idx;

drop table acs_mail_gc_objects;
drop table acs_mail_bodies;
drop table acs_mail_body_headers;
drop table acs_mail_multiparts;
drop table acs_mail_multipart_parts;
drop table acs_mail_links;

select acs_object_type__drop_type (
	'acs_mail_link',
	't'
);

select acs_object_type__drop_type (
	'acs_mail_multipart',
	't'
);

select acs_object_type__drop_type (
	'acs_mail_body',
	't'
);

select acs_object_type__drop_type (
	'acs_mail_gc_object',
	't'
);
