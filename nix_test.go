package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"path"
	"strings"
	"testing"

	"github.com/google/go-cmp/cmp"
)

var update = flag.Bool("update", false, "update golden files")

func getPaths(t *testing.T, useCommonInput bool) (string, string) {
	t.Helper()
	var composePath string
	if useCommonInput {
		composePath = path.Join("testdata", "compose.yml")
	} else {
		composePath = path.Join("testdata", fmt.Sprintf("%s.compose.yml", t.Name()))
	}
	envFilePath := path.Join("testdata", "input.env")
	return composePath, envFilePath
}

func runSubtestsWithGenerator(t *testing.T, g *Generator) {
	t.Helper()
	ctx := context.Background()
	for _, runtime := range []ContainerRuntime{ContainerRuntimeDocker, ContainerRuntimePodman} {
		t.Run(runtime.String(), func(t *testing.T) {
			testName := strings.ReplaceAll(t.Name(), "/", ".")
			outFilePath := path.Join("testdata", fmt.Sprintf("%s.nix", testName))
			g.Runtime = runtime
			c, err := g.Run(ctx)
			if err != nil {
				t.Fatal(err)
			}
			got := c.String()
			if *update {
				if err := os.WriteFile(outFilePath, []byte(got), 0644); err != nil {
					t.Fatal(err)
				}
				return
			}
			wantOutput, err := os.ReadFile(outFilePath)
			if err != nil {
				t.Fatal(err)
			}
			if diff := cmp.Diff(string(wantOutput), got); diff != "" {
				t.Errorf("output diff: %s\n", diff)
			}
		})
	}
}
