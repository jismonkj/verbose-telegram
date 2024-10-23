package notifications

import "testing"

func TestNotify(t *testing.T) {
	tests := []struct {
		name string
	}{
		struct{ name string }{
			"Notify",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			Notify()
		})
	}
}
