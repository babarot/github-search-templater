package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"text/template"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

// Repo represents GitHub repository
type Repo struct {
	Name        string
	Description string
	URL         string
}

func main() {
	err := run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] %s\n", err.Error())
		os.Exit(1)
	}
}

func run() error {
	var (
		flagT = flag.String("t", "", "template file path")
	)
	flag.Parse()
	args := flag.Args()

	token := os.Getenv("GITHUB_TOKEN")
	if token == "" {
		return errors.New("GITHUB_TOKEN is missing")
	}
	if len(args) == 0 {
		return errors.New("too few arguments")
	}

	ts := oauth2.StaticTokenSource(&oauth2.Token{
		AccessToken: token,
	})
	tc := oauth2.NewClient(oauth2.NoContext, ts)
	client := github.NewClient(tc)

	ctx := context.Background()
	q := args[0]
	opt := &github.SearchOptions{Sort: "created", Order: "asc"}

	var results []*github.RepositoriesSearchResult
	for {
		result, resp, err := client.Search.Repositories(ctx, q, opt)
		if err != nil {
			return err
		}
		results = append(results, result)
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}

	var repos []Repo
	for _, result := range results {
		for _, repo := range result.Repositories {
			repos = append(repos, Repo{
				Name:        repo.GetFullName(),
				Description: repo.GetDescription(),
				URL:         repo.GetHTMLURL(),
			})
		}
	}

	if path := *flagT; path != "" {
		t := template.Must(template.ParseFiles(path))
		if err := t.Execute(os.Stdout, repos); err != nil {
			return err
		}
	}

	return nil
}
