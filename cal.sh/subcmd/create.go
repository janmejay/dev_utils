package subcmd

import (
	"context"
	"flag"
	"log"
	"strings"
	"time"

	"github.com/google/subcommands"
	"google.golang.org/api/calendar/v3"
)

type CreateCmd struct {
	svc *calendar.Service

	name string

	self string

	startDate string // yyyy-mm-dd

	startDateTime string // RFC3339 yyyy-mm-ddTHH:MM:SS.sss+/-ZZZZ

	len string

	invite string // comma separated str
}

func (*CreateCmd) Name() string { return "create" }
func (*CreateCmd) Synopsis() string {
	return "Create a new event described by flags." }
func (*CreateCmd) Usage() string {
	return `create ...:
	Create new event.
`
}

func (p *CreateCmd) SetFlags(f *flag.FlagSet) {
	f.StringVar(&p.name, "name", "", "event name")
	f.StringVar(&p.self, "self", "", "google-id of organizer")

	f.StringVar(&p.startDate, "start_date", "", "start date, yyyy-mm-dd")
	f.StringVar(&p.startDateTime, "start_date_time", "",
		"start date time, RFC3339")

	f.StringVar(&p.len, "len", "1h", "length of event in humane format")

	f.StringVar(&p.invite, "invite", "", "additionally invite...")
}

func (p *CreateCmd) makeEventStartTime() *calendar.EventDateTime {
	t := &calendar.EventDateTime{}
	if (p.startDate != "") {
		t.Date = p.startDate
	} else {
		t.DateTime = p.startDateTime
	}
	return t
}

func (p *CreateCmd) makeEventEndTime(
	start *calendar.EventDateTime,
) *calendar.EventDateTime {
	var startTime time.Time
	var err error
	if start.Date != "" {
		startTime, err = time.Parse("2006-01-02", start.Date)
		if err != nil {
			log.Fatalf("Couldn't parse date '%s': %v", start.Date, err)
		}
	} else {
		startTime, err = time.Parse(time.RFC3339, start.DateTime)
		if err != nil {
			log.Fatalf("Couldn't parse date-time '%s': %v", start.DateTime, err)
		}
	}

	len, err := time.ParseDuration(p.len)
	if err != nil {
		log.Fatalf("Couldn't parse duration: %v", err)
	}

	endTime := startTime.Add(len)

	end := &calendar.EventDateTime{}
	if start.Date != "" {
		end.Date = endTime.Format("2006-01-02")
	} else {
		blob, err := endTime.MarshalText()
		end.DateTime = string(blob)
		if err != nil {
			log.Fatalf("Couldn't format end-date-time: %v", err)
		}
	}
	return end
}

func makeAttendee(email string, self bool) *calendar.EventAttendee {
	attendee := &calendar.EventAttendee{}
	attendee.Email = email
	if (self) {
		attendee.Organizer = true
		attendee.ResponseStatus = "accepted"
		attendee.Self = true
	}
	return attendee
}

func makeOrganizer(email string) *calendar.EventOrganizer {
	organizer := &calendar.EventOrganizer{}
	organizer.Email = email
	organizer.Self = true
	return organizer
}

func makeCreator(email string) *calendar.EventCreator {
	creator := &calendar.EventCreator{}
	creator.Email = email
	creator.Self = true
	return creator
}

func makeAttendees(
	commaSeparatedEmails string,
	self *calendar.EventOrganizer) []*calendar.EventAttendee {
	attendees := make([]*calendar.EventAttendee, 1)
	attendees[0] = makeAttendee(self.Email, true)
	if (commaSeparatedEmails != "") {
		for _, email := range strings.Split(commaSeparatedEmails, ",") {
			attendees = append(attendees, makeAttendee(email, false))
		}
	}
	return attendees
}

func makeDefaultReminders() *calendar.EventReminders {
	r := &calendar.EventReminders{}
	r.UseDefault = true
	return r
}

func (p *CreateCmd) makeEvent() *calendar.Event {
	evt := &calendar.Event{}
	evt.Start = p.makeEventStartTime()
	evt.End = p.makeEventEndTime(evt.Start)
	evt.Organizer = makeOrganizer(p.self)
	evt.Creator = makeCreator(p.self)
	evt.Attendees = makeAttendees(p.invite, evt.Organizer)
	evt.EventType = "default"
	evt.Reminders = makeDefaultReminders()
	evt.Summary = p.name
	return evt
}

func (p *CreateCmd) Execute(
	_ context.Context,
	f *flag.FlagSet,
	_ ...interface{}) subcommands.ExitStatus {
	evt := p.makeEvent()
	_, err := p.svc.Events.Insert("primary", evt).Do()

	if err != nil {
		log.Fatalf("Couldn't insert event: %v", err)
	}
	return subcommands.ExitSuccess
}

func NewCreateCmd(svc *calendar.Service) *CreateCmd {
	cmd := &CreateCmd{}
	cmd.svc = svc
	return cmd
}
