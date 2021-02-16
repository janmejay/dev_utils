package subcmd

import (
	"context"
	"flag"
	"fmt"
	"log"
	"time"

	"github.com/google/subcommands"
	"google.golang.org/api/calendar/v3"
)

type UpcomingCmd struct {
	svc *calendar.Service
	num int64
	fmt_json bool
}

func (*UpcomingCmd) Name() string			{ return "upcoming" }
func (*UpcomingCmd) Synopsis() string { return "Print a few upcoming events." }
func (*UpcomingCmd) Usage() string {
	return `upcoming [-num] <number of events, default 10> [-fmt_json]:
	Print a few upcoming events.
`
}

func (p *UpcomingCmd) SetFlags(f *flag.FlagSet) {
	f.Int64Var(&p.num, "num", 10, "number of events to show")
	f.BoolVar(&p.fmt_json, "fmt_json", false, "spit out json-formatted events")
}

func printShort(evts *calendar.Events) {
	for _, item := range evts.Items {
		date := item.Start.DateTime
		if date == "" {
			date = item.Start.Date
		}
		fmt.Printf("%v (%v)\n", item.Summary, date)
	}
}

func printJson(evts *calendar.Events) {
	for _, item := range evts.Items {
		blob, err := item.MarshalJSON()
		if err != nil {
			log.Fatalf("Couldn't marshal event to json: %v", err)
		}
		fmt.Printf("%s\n", string(blob))
	}
}

func (p *UpcomingCmd) Execute(
	_ context.Context,
	f *flag.FlagSet,
	_ ...interface{}) subcommands.ExitStatus {
	t := time.Now().Format(time.RFC3339)
	events, err :=
		p.svc.Events.
		List("primary").
		ShowDeleted(false).
		SingleEvents(true).
		TimeMin(t).
		MaxResults(p.num).
		OrderBy("startTime").
		Do()
	if err != nil {
		log.Fatalf("Unable to retrieve next ten of the user's events: %v", err)
	}
	fmt.Println("Upcoming events:")
	if len(events.Items) == 0 {
		fmt.Println("No upcoming events found.")
	} else {
		if (p.fmt_json) {
			printJson(events)
		} else {
			printShort(events)
		}
	}
	return subcommands.ExitSuccess
}

func NewUpcomingCmd(svc *calendar.Service) *UpcomingCmd {
	return &UpcomingCmd{svc, 10, false}
}
