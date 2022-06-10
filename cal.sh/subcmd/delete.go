package subcmd

import (
	"context"
	"flag"
	"fmt"
	"log"

	"github.com/google/subcommands"
	"google.golang.org/api/calendar/v3"
)

type DeleteCmd struct {
	svc *calendar.Service
	eventId string
}

func (*DeleteCmd) Name() string			{ return "delete" }
func (*DeleteCmd) Synopsis() string { return "Delete given event." }
func (*DeleteCmd) Usage() string {
	return `delete -event_id <event id string>:
	Delete given event.
`
}

func (p *DeleteCmd) SetFlags(f *flag.FlagSet) {
	f.StringVar(&p.eventId, "event_id", "", "event-id string")
}

func (p *DeleteCmd) Execute(
	_ context.Context,
	f *flag.FlagSet,
	_ ...interface{}) subcommands.ExitStatus {
	if p.eventId == "" {
		log.Fatalf("No event-id given.")
	}

	err :=
		p.svc.Events.
		Delete("primary", p.eventId).
		Do()
	if err != nil {
		log.Fatalf("Unable to delete user's event by id: %s %v", p.eventId, err)
	}
	fmt.Printf("Deleted %s successfully\n", p.eventId)
	return subcommands.ExitSuccess
}

func NewDeleteCmd(svc *calendar.Service) *DeleteCmd {
	return &DeleteCmd{svc, ""}
}
