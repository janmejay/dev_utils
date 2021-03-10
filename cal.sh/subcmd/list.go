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

type ListCmd struct {
	svc *calendar.Service
	num int64
	fmtJson bool
	startDateTime string
}

func (*ListCmd) Name() string			{ return "list" }
func (*ListCmd) Synopsis() string { return "Print a few list events." }
func (*ListCmd) Usage() string {
	return `list [-num] <number of events, default 10> [-fmt_json]:
	Print a few list events.
`
}

func (p *ListCmd) SetFlags(f *flag.FlagSet) {
	f.Int64Var(&p.num, "num", 10, "number of events to show")
	f.StringVar(&p.startDateTime, "start_date_time", "",
		"start date time, RFC3339")
	f.BoolVar(&p.fmtJson, "fmt_json", false, "spit out json-formatted events")
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

func (p *ListCmd) Execute(
	_ context.Context,
	f *flag.FlagSet,
	_ ...interface{}) subcommands.ExitStatus {
	var startDateTime string
	if p.startDateTime == "" {
		startDateTime = time.Now().Format(time.RFC3339)
	} else {
		startDateTime = p.startDateTime
	}

	events, err :=
		p.svc.Events.
		List("primary").
		ShowDeleted(false).
		SingleEvents(true).
		TimeMin(startDateTime).
		MaxResults(p.num).
		OrderBy("startTime").
		Do()
	if err != nil {
		log.Fatalf("Unable to retrieve next ten of the user's events: %v", err)
	}
	fmt.Println("List events:")
	if len(events.Items) == 0 {
		fmt.Println("No list events found.")
	} else {
		if (p.fmtJson) {
			printJson(events)
		} else {
			printShort(events)
		}
	}
	return subcommands.ExitSuccess
}

func NewListCmd(svc *calendar.Service) *ListCmd {
	return &ListCmd{svc, 10, false, ""}
}
