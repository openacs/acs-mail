ad_library {
    Scheduled proc setup for acs-mail

    @author John Prevost <jmp@arsdigita.com>
    @creation-date 2001-01-19
    @cvs-id $Id$
}

# Schedule periodic mail send events.  Its own thread, since it does
# network activity.  If it ever takes longer than the interval,
# there'll be hell to pay.

# Default interval is 15 minutes.

ad_schedule_proc -thread t 900 acs_mail_process_queue
