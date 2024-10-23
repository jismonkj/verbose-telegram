package helper

import "testing"

func TestHelper(t *testing.T) {
	tests := []struct {
		name string
	}{
		struct{ name string }{
			name: "Helper",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			Helper()
		})
	}
}
